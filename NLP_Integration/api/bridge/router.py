from __future__ import annotations

import asyncio
import difflib
import logging
import time
from pathlib import Path

import numpy as np
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile

from api.bridge.audio_pipeline import AudioPipeline, RetentionStore
from api.bridge.clinical_text import (
    contains_emergency_keyword,
    contains_warlpiri_emergency,
    extract_top_3_symptoms,
    translate_clinical_transcript,
)
from api.bridge.config import CFG
from api.bridge.models import (
    TriageAnalyzeVoiceResponse,
    TriagePredictRequest,
    TriagePredictResponse,
    TranscribeResponse,
)
from api.bridge.nlp_service import NLPService
from api.bridge.security import verify_bearer_token
from api.bridge.stt_service import STTService
from api.bridge.transcript_audit import write_transcript_audit
from api.bridge.triage_service import TriageService
from api.bridge.warlpiri_dict import normalize_for_triage, translate_warlpiri_to_english
from api.bridge.warlpiri_stt import get_active_mms_adapter, transcribe_mms_waveform

logger = logging.getLogger("saca.bridge")
logger.setLevel(logging.INFO)
router = APIRouter(tags=["secure-bridge"])

audio_pipeline = AudioPipeline()
stt_service = STTService()
nlp_service = NLPService()
triage_service = TriageService()
retention_store = RetentionStore(root=CFG.uploads_dir, retention_seconds=CFG.retention_seconds)


def _transcript_delta(raw_text: str, verified_text: str) -> float:
    return float(difflib.SequenceMatcher(None, raw_text, verified_text).ratio())


def _is_warlpiri_lang(language: str) -> bool:
    return (language or "").strip().lower() in {"wbp", "warlpiri", "w"}


async def _transcribe_upload(
    audio_file: UploadFile,
    language: str = "en",
) -> tuple[str, bytes, str, str]:
    """Validate and transcribe one uploaded audio file.

    Returns ``(transcript, raw_wav_bytes, stt_provider, audio_temp_path_str)``.
    """
    started = time.perf_counter()
    raw = await audio_file.read()
    filename = audio_file.filename or "unknown_audio.wav"
    content_type = audio_file.content_type or "unknown"
    size_bytes = len(raw)
    logger.info(
        "audio_upload_received filename=%s content_type=%s size_bytes=%s",
        filename,
        content_type,
        size_bytes,
    )
    if not raw:
        raise HTTPException(status_code=400, detail="audio_file is empty")

    safe_name = Path(filename).name.replace(" ", "_")
    temp_path = CFG.temp_audio_dir / f"{int(time.time() * 1000)}_{safe_name}"
    temp_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path.write_bytes(raw)
    logger.info("audio_upload_saved temp_path=%s", str(temp_path))

    try:
        waveform, audio_metrics = audio_pipeline.process_wav_bytes(raw)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid WAV audio: {exc}") from exc
    logger.info(
        "audio_signal_stats peak=%.4f rms=%.4f duration_s=%.2f clipping=%.3f samples=%d",
        audio_metrics.peak,
        audio_metrics.rms,
        audio_metrics.duration_seconds,
        audio_metrics.clipping_ratio,
        waveform.size,
    )
    if audio_metrics.is_too_short:
        raise HTTPException(
            status_code=422,
            detail=f"Audio too short ({audio_metrics.duration_seconds:.2f}s); speak for at least 0.3 seconds.",
        )
    if audio_metrics.is_silent:
        raise HTTPException(
            status_code=422,
            detail="Audio too quiet or no microphone input detected. Check emulator microphone settings.",
        )
    if audio_metrics.is_clipped:
        logger.warning(
            "audio_clipping_detected ratio=%.3f — transcript quality may be reduced",
            audio_metrics.clipping_ratio,
        )
    lang_key = (language or "en").strip().lower()
    if _is_warlpiri_lang(language):
        if CFG.use_mms_warlpiri_stt:
            try:
                transcript = await asyncio.wait_for(
                    asyncio.to_thread(transcribe_mms_waveform, waveform),
                    timeout=CFG.mms_stt_timeout_seconds,
                )
                stt_provider = "mms-warlpiri"
            except (TimeoutError, asyncio.TimeoutError) as exc:
                raise HTTPException(
                    status_code=504,
                    detail="MMS transcription timed out. First model load can take several minutes "
                    "or raise SACA_MMS_STT_TIMEOUT_SECONDS.",
                ) from exc
            except Exception as exc:
                # MMS adapter unavailable for this model checkpoint (e.g. facebook/mms-300m
                # may not carry wbp/pjt adapters). Fall back to English Whisper so the app
                # stays functional — the Warlpiri dictionary bridge still runs on the result.
                logger.warning(
                    "MMS transcription failed — adapter may not exist in model %s. "
                    "Falling back to English STT for wbp request. "
                    "Use SACA_MMS_MODEL_ID=facebook/mms-1b-all for full adapter support. "
                    "Error: %s",
                    CFG.mms_model_id,
                    exc,
                )
                stt = await stt_service.transcribe_audio(waveform, language="en-AU")
                transcript = stt.text
                stt_provider = f"{stt.provider}-wbp-mms-fallback"
        elif CFG.warlpiri_stt_dev_fallback_english:
            logger.warning(
                "Warlpiri (wbp) voice using English STT only (SACA_WARLPIRI_STT_DEV_FALLBACK=1); "
                "not suitable for production Warlpiri accuracy."
            )
            stt = await stt_service.transcribe_audio(waveform, language="en-AU")
            transcript = stt.text
            stt_provider = f"{stt.provider}-wbp-dev-fallback"
        else:
            raise HTTPException(
                status_code=503,
                detail="Warlpiri voice needs MMS: set SACA_USE_MMS_WARLPIRI_STT=1 and install "
                "torch + transformers (run_api.ps1 -WarlpiriMms), or for local UI testing only set "
                "SACA_WARLPIRI_STT_DEV_FALLBACK=1 to use English Whisper.",
            )
    else:
        stt = await stt_service.transcribe_audio(waveform, language="en-AU")
        transcript = stt.text
        stt_provider = stt.provider
    elapsed_ms = int((time.perf_counter() - started) * 1000)
    logger.info(
        "stt_completed provider=%s configured_provider=%s elapsed_ms=%s transcript_len=%s lang=%s",
        stt_provider,
        stt_service.provider,
        elapsed_ms,
        len(transcript),
        lang_key,
    )
    if not transcript.strip():
        raise HTTPException(
            status_code=422,
            detail="Failed to generate transcript. Speech was not detected; try louder input or check emulator mic.",
        )
    return transcript, raw, stt_provider, str(temp_path)


def _analyze_transcript(
    transcript: str,
    raw: bytes | None = None,
    *,
    language: str = "en",
    warlpiri_raw_transcript: str | None = None,
    pre_escalate_severe: bool = False,
) -> TriageAnalyzeVoiceResponse:
    """Run NLP and triage inference on a transcript string."""
    sbert_vector = nlp_service.encode(transcript)
    decision = triage_service.decide(
        transcript=transcript,
        semantic_vector=sbert_vector.embedding,
    )
    if raw is not None:
        retention_store.save_audio(session_id=f"analyze_voice_{int(time.time() * 1000)}", wav_bytes=raw)
    # Override triage level when a Warlpiri emergency term was detected before
    # the dictionary bridge (pre_escalate_severe=True means we caught a danger
    # signal the English pipeline may have missed).
    triage_level = decision.triage_level
    recommendation = decision.recommendation
    if pre_escalate_severe and triage_level != "Severe":
        logger.warning(
            "triage_level upgraded Severe by warlpiri_pre_escalation original_level=%s", triage_level
        )
        triage_level = "Severe"
        recommendation = (
            "EMERGENCY — Warlpiri speech indicated a life-threatening symptom. "
            "Immediate clinical assessment required. " + (recommendation or "")
        ).strip()
    return TriageAnalyzeVoiceResponse(
        transcript=transcript,
        triage_level=triage_level,  # type: ignore[arg-type]
        top_condition=decision.top_condition,
        recommendation=recommendation,
        language=language,
        warlpiri_raw_transcript=warlpiri_raw_transcript,
    )


def bridge_health_snapshot() -> dict:
    """Expose non-sensitive backend runtime state for clients and ops."""
    return {
        "status": "ok",
        "stt_provider": stt_service.provider,
        "hosted_stt_enabled": CFG.use_hosted_stt and bool(CFG.hosted_stt_api_key),
        "hosted_stt_provider": CFG.hosted_stt_provider if CFG.use_hosted_stt else "",
        "faster_whisper_enabled": CFG.use_faster_whisper,
        "whisper_tiny_fallback_enabled": CFG.use_whisper_tiny_fallback,
        "stt_timeout_seconds": CFG.stt_timeout_seconds,
        "mms_warlpiri_stt_enabled": CFG.use_mms_warlpiri_stt,
        "warlpiri_stt_dev_fallback_english": CFG.warlpiri_stt_dev_fallback_english,
        "mms_model_id": CFG.mms_model_id,
        "mms_adapter_lang_configured": CFG.mms_warlpiri_lang,
        "mms_try_wbp_first": CFG.mms_try_wbp_adapter_first,
        "mms_active_adapter": get_active_mms_adapter(),
        "transcript_audit_enabled": CFG.transcript_audit_enabled,
        "transcript_audit_dir": str(CFG.transcript_audit_dir),
    }


@router.post("/triage/predict", response_model=TriagePredictResponse)
async def triage_predict(payload: TriagePredictRequest) -> TriagePredictResponse:
    """Unified JSON triage contract used by Flutter and backend QA."""
    t0 = time.perf_counter()
    try:
        verified_norm = translate_clinical_transcript(payload.verified_transcript, payload.language)
        semantic_vector = nlp_service.encode(verified_norm)
        decision = triage_service.decide(
            transcript=verified_norm,
            semantic_vector=semantic_vector.embedding,
            text_input=verified_norm,
            pain_locations=[],
        )

        top_3_symptoms = extract_top_3_symptoms(verified_norm, triage_service.symptom_columns)
        triage_level = decision.triage_level
        escalation_triggered = False

        # Conservative gate: only bump *Mild* when the model/score is very uncertain.
        # Moderate stays Moderate so the UI can show a spectrum (was: Mild+Moderate both upgraded if conf < threshold).
        if triage_level == "Mild" and decision.confidence < CFG.low_confidence_triage_threshold:
            triage_level = "Severe"
            escalation_triggered = True

        if contains_emergency_keyword(verified_norm):
            triage_level = "Severe"
            escalation_triggered = True

        latency_ms = int((time.perf_counter() - t0) * 1000)
        delta_ratio = _transcript_delta(payload.raw_transcript, payload.verified_transcript)
        logger.info(
            "triage_predict latency_ms=%d transcript_delta=%.3f escalation=%s",
            latency_ms,
            delta_ratio,
            escalation_triggered,
        )

        w_raw = (
            payload.raw_transcript.strip()
            if _is_warlpiri_lang(payload.language) and (payload.raw_transcript or "").strip()
            else None
        )

        if CFG.transcript_audit_enabled:
            write_transcript_audit(
                source="triage/predict",
                language=(payload.language or "en").strip().lower() or "en",
                voice_transcript_as_recognized=w_raw
                if _is_warlpiri_lang(payload.language)
                else (payload.raw_transcript.strip() or None),
                patient_verified_transcript=payload.verified_transcript.strip() or None,
                patient_normalized_for_sbert=verified_norm,
                mms_adapter=get_active_mms_adapter(),
            )

        return TriagePredictResponse(
            triage_level=triage_level,  # type: ignore[arg-type]
            top_condition=decision.top_condition,
            confidence=float(decision.confidence),
            top_3_symptoms=top_3_symptoms,
            recommendation=decision.recommendation,
            escalation_triggered=escalation_triggered,
            language=payload.language,
            warlpiri_raw_transcript=w_raw,
        )
    except Exception as exc:
        logger.exception("triage_predict failed")
        raise HTTPException(status_code=500, detail=f"Inference error: {exc}") from exc


@router.post("/triage/analyze-voice", response_model=TriageAnalyzeVoiceResponse)
async def triage_analyze_voice(
    audio_file: UploadFile = File(...),
    language: str = Form(default="en"),
    _: str = Depends(verify_bearer_token),
) -> TriageAnalyzeVoiceResponse:
    """Primary production endpoint: audio upload to triage JSON."""
    raw_transcript, raw, stt_provider, audio_path = await _transcribe_upload(audio_file, language=language)
    warlpiri_raw = raw_transcript if _is_warlpiri_lang(language) else None
    # Pre-translation safety check: catch Warlpiri emergency terms before the dictionary bridge.
    warlpiri_pre_escalate = warlpiri_raw is not None and contains_warlpiri_emergency(warlpiri_raw)
    if warlpiri_pre_escalate:
        logger.warning("warlpiri_pre_translation_emergency_detected raw=%s", raw_transcript[:120])
    clinical = translate_clinical_transcript(raw_transcript, language)
    lang_norm = (language or "en").strip().lower() or "en"
    if CFG.log_transcripts:
        logger.info("analyze_voice clinical_transcript=%s", clinical[:300])
    if CFG.transcript_audit_enabled:
        write_transcript_audit(
            source="triage/analyze_voice",
            language=lang_norm,
            voice_transcript_as_recognized=raw_transcript,
            patient_verified_transcript=raw_transcript,
            patient_normalized_for_sbert=clinical,
            stt_provider=stt_provider,
            mms_adapter=get_active_mms_adapter(),
            audio_temp_relpath=audio_path,
        )
    return _analyze_transcript(
        clinical,
        raw=raw,
        language=lang_norm,
        warlpiri_raw_transcript=warlpiri_raw,
        pre_escalate_severe=warlpiri_pre_escalate,
    )


@router.post("/triage/predict-multipart", response_model=TriagePredictResponse)
async def triage_predict_multipart_compat(
    audio_file: UploadFile | None = File(default=None),
    raw_transcript: str = Form(default=""),
    verified_transcript: str = Form(default=""),
    language: str = Form(default="en"),
    text_input: str = Form(default=""),
    voice_transcript: str = Form(default=""),
    _: str = Depends(verify_bearer_token),
) -> TriagePredictResponse:
    """Multipart compatibility route for the unified predict contract."""
    transcript = (verified_transcript or "").strip()
    raw: bytes | None = None
    if audio_file is not None:
        transcript, raw, _stt_unused, _audio_unused = await _transcribe_upload(audio_file, language=language)
        if raw_transcript.strip() == "":
            raw_transcript = transcript
        if verified_transcript.strip() == "":
            verified_transcript = transcript
    if not verified_transcript.strip():
        verified_transcript = " ".join([text_input.strip(), voice_transcript.strip()]).strip()
    if not raw_transcript.strip():
        raw_transcript = verified_transcript
    if not verified_transcript.strip():
        raise HTTPException(status_code=400, detail="No usable transcript/text provided")

    if raw is not None:
        retention_store.save_audio(
            session_id=f"predict_multipart_{int(time.time() * 1000)}",
            wav_bytes=raw,
        )
    return await triage_predict(
        TriagePredictRequest(
            raw_transcript=raw_transcript,
            verified_transcript=verified_transcript,
            language=language,
        )
    )


@router.post("/triage/transcribe", response_model=TranscribeResponse)
async def transcribe_audio_compat(
    audio_file: UploadFile = File(...),
    language: str = Form(default="en"),
    _: str = Depends(verify_bearer_token),
) -> TranscribeResponse:
    """Deprecated compatibility route for legacy transcript-only clients."""
    transcript, _, stt_provider, audio_path = await _transcribe_upload(audio_file, language=language)
    if CFG.transcript_audit_enabled:
        write_transcript_audit(
            source="triage/transcribe",
            language=(language or "en").strip().lower() or "en",
            voice_transcript_as_recognized=transcript,
            patient_verified_transcript=transcript,
            patient_normalized_for_sbert=translate_clinical_transcript(transcript, language),
            stt_provider=stt_provider,
            mms_adapter=get_active_mms_adapter(),
            audio_temp_relpath=audio_path,
        )
    return TranscribeResponse(transcript=transcript, transcript_final=transcript)


@router.get("/triage/validate-warlpiri")
async def validate_warlpiri_phrase(
    q: str = Query(default="", alias="q"),
    language: str = Query(default="wbp"),
    _: str = Depends(verify_bearer_token),
) -> dict[str, str]:
    """Map a Warlpiri clinical phrase (placeholders) to English glosses for QA."""
    return {
        "query": q,
        "english_gloss": translate_warlpiri_to_english(q),
        "normalized_for_triage": normalize_for_triage(q, language),
    }

