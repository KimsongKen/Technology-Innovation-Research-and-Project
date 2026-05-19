from __future__ import annotations

import asyncio
import logging
import math
import time
from dataclasses import dataclass

import numpy as np

from api.bridge.config import CFG
from api.bridge.audio_pipeline import AudioPipeline


@dataclass
class STTResult:
    text: str
    confidence: float
    provider: str = "unknown"


class STTService:
    """Audio-to-text service with optional hosted ASR, faster-whisper, and deterministic fallbacks."""

    def __init__(self) -> None:
        self._logger = logging.getLogger("saca.bridge.stt")
        self._hosted_ready = (
            CFG.use_hosted_stt
            and CFG.hosted_stt_provider in {"openai", "openai-compatible"}
            and bool(CFG.hosted_stt_api_key)
        )
        self._provider = "fallback"
        self._faster_whisper_model = None
        self._whisper_tiny_model = None

        if self._hosted_ready:
            self._provider = "hosted-openai"

        if CFG.use_faster_whisper:
            try:
                from faster_whisper import WhisperModel  # type: ignore

                self._faster_whisper_model = WhisperModel(
                    CFG.faster_whisper_model,
                    device=CFG.faster_whisper_device,
                    compute_type=CFG.faster_whisper_compute_type,
                )
                if self._provider == "fallback":
                    self._provider = "faster-whisper"
            except Exception as exc:
                self._logger.warning("Failed to initialize faster-whisper: %s", exc)

        if CFG.use_whisper_tiny_fallback:
            try:
                import whisper  # type: ignore

                self._whisper_tiny_model = whisper.load_model(CFG.whisper_tiny_model)
                if self._provider == "fallback":
                    self._provider = "whisper-tiny"
            except Exception as exc:
                self._logger.warning("Failed to initialize whisper-tiny fallback: %s", exc)

    @property
    def provider(self) -> str:
        return self._provider

    async def transcribe_partial(self, waveform: np.ndarray, language: str) -> STTResult:
        return await self.transcribe_audio(waveform, language=language)

    async def transcribe_final(self, waveform: np.ndarray, language: str) -> STTResult:
        return await self.transcribe_audio(waveform, language=language)

    async def transcribe_audio(self, waveform: np.ndarray, language: str = "en-AU") -> STTResult:
        if waveform.size == 0:
            return STTResult(text="", confidence=0.0, provider="empty-audio")

        if self._hosted_ready:
            hosted = await self._transcribe_hosted_openai(waveform, language)
            if hosted is not None and hosted.text.strip():
                return hosted

        if self._faster_whisper_model is not None:
            faster_result = await self._run_provider(
                provider_name="faster-whisper",
                waveform=waveform,
                language=language,
                fn=self._faster_whisper_transcribe,
            )
            if faster_result is not None:
                return faster_result

        if self._whisper_tiny_model is not None:
            tiny_result = await self._run_provider(
                provider_name="whisper-tiny",
                waveform=waveform,
                language=language,
                fn=self._whisper_tiny_transcribe,
            )
            if tiny_result is not None:
                return tiny_result

        return self._fallback_transcribe(waveform)

    async def _run_provider(self, provider_name: str, waveform: np.ndarray, language: str, fn) -> STTResult | None:
        started = time.perf_counter()
        try:
            result: STTResult = await asyncio.wait_for(
                asyncio.to_thread(fn, waveform, language),
                timeout=CFG.stt_timeout_seconds,
            )
            elapsed_s = time.perf_counter() - started
            if not result.text.strip():
                self._log_model_failure(provider_name, "empty transcript", elapsed_s)
                return None
            if elapsed_s > CFG.stt_failure_warn_seconds:
                self._log_model_failure(provider_name, "slow transcription", elapsed_s)
            result.provider = provider_name
            return result
        except (TimeoutError, asyncio.TimeoutError):
            elapsed_s = time.perf_counter() - started
            self._log_model_failure(provider_name, "timeout", elapsed_s)
            return None
        except Exception as exc:
            elapsed_s = time.perf_counter() - started
            reason = "OOM" if "out of memory" in str(exc).lower() else "exception"
            self._log_model_failure(provider_name, reason, elapsed_s, exc=exc)
            return None

    async def _transcribe_hosted_openai(self, waveform: np.ndarray, language: str) -> STTResult | None:
        from api.bridge.hosted_stt import openai_transcription_language, transcribe_openai_compatible

        provider_name = "hosted-openai"
        started = time.perf_counter()
        try:
            wav_bytes = AudioPipeline.float32_mono_to_wav_bytes(waveform)
            olang = openai_transcription_language(language)
            text = await asyncio.wait_for(
                transcribe_openai_compatible(
                    wav_bytes=wav_bytes,
                    api_key=CFG.hosted_stt_api_key,
                    base_url=CFG.hosted_stt_base_url,
                    model=CFG.hosted_stt_model,
                    language=olang,
                    timeout_seconds=CFG.hosted_stt_timeout_seconds,
                ),
                timeout=max(CFG.hosted_stt_timeout_seconds + 5.0, CFG.stt_timeout_seconds),
            )
            elapsed_s = time.perf_counter() - started
            if not text.strip():
                self._log_model_failure(provider_name, "empty transcript", elapsed_s)
                return None
            if elapsed_s > CFG.stt_failure_warn_seconds:
                self._log_model_failure(provider_name, "slow transcription", elapsed_s)
            return STTResult(text=text, confidence=0.85, provider=provider_name)
        except (TimeoutError, asyncio.TimeoutError):
            elapsed_s = time.perf_counter() - started
            self._log_model_failure(provider_name, "timeout", elapsed_s)
            return None
        except Exception as exc:
            elapsed_s = time.perf_counter() - started
            self._log_model_failure(provider_name, "exception", elapsed_s, exc=exc)
            return None

    def _faster_whisper_transcribe(self, waveform: np.ndarray, language: str) -> STTResult:
        assert self._faster_whisper_model is not None
        lang = "en" if language.startswith("en") else None
        beam = CFG.faster_whisper_beam_size
        use_vad = CFG.faster_whisper_vad_filter
        prompt_kw: dict = {}
        if CFG.faster_whisper_initial_prompt:
            prompt_kw["initial_prompt"] = CFG.faster_whisper_initial_prompt

        def _run(vad: bool, b: int, condition: bool) -> tuple[list, object]:
            segs, info = self._faster_whisper_model.transcribe(
                waveform,
                language=lang,
                vad_filter=vad,
                beam_size=b,
                condition_on_previous_text=condition,
                **prompt_kw,
            )
            return list(segs), info

        segments, info = _run(use_vad, beam, True)
        text = " ".join(seg.text for seg in segments).strip()

        if not text:
            # VAD can aggressively drop short or quiet speech — retry without it
            segments, info = _run(False, max(1, beam // 2), False)
            text = " ".join(seg.text for seg in segments).strip()

        if not text:
            # Last attempt: raise temperature slightly to escape greedy local minima
            segments, info = _run(False, 1, False)
            text = " ".join(seg.text for seg in segments).strip()

        # Confidence from segment avg log-probability, not language_probability
        confidence = _segments_confidence(segments)
        if confidence == 0.0:
            # No segments — fall back to language detection probability as a floor
            confidence = max(0.0, min(float(getattr(info, "language_probability", 0.5)), 1.0))

        return STTResult(
            text=text,
            confidence=confidence,
            provider="faster-whisper",
        )

    def _whisper_tiny_transcribe(self, waveform: np.ndarray, language: str) -> STTResult:
        assert self._whisper_tiny_model is not None
        lang = "en" if language.startswith("en") else None

        result = self._whisper_tiny_model.transcribe(
            waveform.astype(np.float32),
            language=lang,
            fp16=False,
            no_speech_threshold=0.8,
            condition_on_previous_text=True,
            temperature=0.0,
        )
        text = str(result.get("text", "")).strip()

        if not text:
            # Permissive retry — drop the no-speech gate entirely
            result = self._whisper_tiny_model.transcribe(
                waveform.astype(np.float32),
                language=lang,
                fp16=False,
                no_speech_threshold=1.0,
                condition_on_previous_text=False,
                temperature=0.2,
            )
            text = str(result.get("text", "")).strip()

        # openai-whisper exposes per-segment avg_logprob
        segs = result.get("segments", [])
        confidence = _segments_confidence_dict(segs) if segs else (0.6 if text else 0.05)

        return STTResult(
            text=text,
            confidence=confidence,
            provider="whisper-tiny",
        )

    def _log_model_failure(self, provider_name: str, reason: str, elapsed_s: float, exc: Exception | None = None) -> None:
        if exc is not None:
            self._logger.warning(
                "STT MODEL FAILURE provider=%s reason=%s elapsed_ms=%d error=%s",
                provider_name, reason, int(elapsed_s * 1000), exc,
            )
        else:
            self._logger.warning(
                "STT MODEL FAILURE provider=%s reason=%s elapsed_ms=%d",
                provider_name, reason, int(elapsed_s * 1000),
            )

    @staticmethod
    def _fallback_transcribe(waveform: np.ndarray) -> STTResult:
        _ = waveform
        return STTResult(text="", confidence=0.0, provider="fallback-empty")


# ---------------------------------------------------------------------------
# Confidence helpers
# ---------------------------------------------------------------------------

def _segments_confidence(segments: list) -> float:
    """Mean segment avg_logprob → probability in [0, 1] for faster-whisper segment objects."""
    if not segments:
        return 0.0
    logprobs = [getattr(seg, "avg_logprob", None) for seg in segments]
    valid = [lp for lp in logprobs if lp is not None and math.isfinite(lp)]
    if not valid:
        return 0.0
    mean_lp = sum(valid) / len(valid)
    # avg_logprob is typically in [-2, 0]; map to [0, 1] with a soft sigmoid
    return float(max(0.0, min(1.0, math.exp(mean_lp))))


def _segments_confidence_dict(segments: list[dict]) -> float:
    """Mean segment avg_logprob for openai-whisper dict output."""
    if not segments:
        return 0.0
    valid = [s["avg_logprob"] for s in segments if isinstance(s.get("avg_logprob"), float) and math.isfinite(s["avg_logprob"])]
    if not valid:
        return 0.0
    return float(max(0.0, min(1.0, math.exp(sum(valid) / len(valid)))))
