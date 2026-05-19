"""Lazy-loaded Meta MMS ASR for Warlpiri (wbp) voice intake.

**Accuracy note:** Public ``facebook/mms-1b-all`` often has no working ``wbp`` adapter; the pipeline
tries ``wbp`` first (when :env:`SACA_MMS_TRY_WBP_FIRST` is on), then your configured language
(default ``pjt``). Pitjantjatjara is *related* but not Warlpiri — for clinically reliable Warlpiri
orthography you need a **Warlpiri-finetuned ASR** (point :env:`SACA_MMS_MODEL_ID` to that repo)
and/or **human verification** of transcripts before triage.

Clinical route still tags ``language=wbp`` for the dictionary → English bridge used before SBERT
(:mod:`api.bridge.warlpiri_dict`, applied in ``router`` *after* this module returns text).

For a diagram of ASR vs lexicon, see the module docstring of :mod:`api.bridge.warlpiri_dict`.
"""

from __future__ import annotations

import logging
import re
import threading
from typing import Any

import numpy as np

from api.bridge.config import CFG

logger = logging.getLogger("saca.bridge.warlpiri_stt")

_lock = threading.Lock()
_processor: Any = None
_model: Any = None
_loaded_adapter: str | None = None
_active_mms_adapter: str | None = None


def get_active_mms_adapter() -> str | None:
    """ISO 639-3 adapter code last used successfully (for /health)."""
    return _active_mms_adapter


def _iso639_3_adapter_code(raw: str) -> str:
    """MMS adapter ids look like ``fra`` or ``azj-script_latin`` — normalize env input."""
    s = (raw or "").strip().lower()
    s = re.sub(r"[^a-z3\-_]+", "", s)
    return s or "pjt"


def _dedupe_preserve_order(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for x in items:
        if not x or x in seen:
            continue
        seen.add(x)
        out.append(x)
    return out


def _adapter_try_sequence() -> list[str]:
    """Ordered MMS language adapters to attempt (first loadable wins)."""
    if CFG.mms_adapter_chain:
        return _dedupe_preserve_order(
            [_iso639_3_adapter_code(p) for p in CFG.mms_adapter_chain.split(",") if p.strip()]
        )
    primary = _iso639_3_adapter_code(CFG.mms_warlpiri_lang)
    seq: list[str] = []
    if CFG.mms_try_wbp_adapter_first and "wbp" not in seq:
        seq.append("wbp")
    if primary not in seq:
        seq.append(primary)
    # Common Australian fallback if still distinct
    if "pjt" not in seq:
        seq.append("pjt")
    return _dedupe_preserve_order(seq)


def _ensure_mms_model_and_device() -> None:
    global _processor, _model, _loaded_adapter

    if not CFG.use_mms_warlpiri_stt:
        raise RuntimeError(
            "MMS Warlpiri STT is disabled. Set SACA_USE_MMS_WARLPIRI_STT=1 and install "
            "torch + transformers."
        )

    import torch
    from transformers import AutoProcessor, Wav2Vec2ForCTC

    if _model is None:
        logger.info("Loading MMS ASR model_id=%s", CFG.mms_model_id)
        _processor = AutoProcessor.from_pretrained(CFG.mms_model_id)
        _model = Wav2Vec2ForCTC.from_pretrained(CFG.mms_model_id)
        _model.eval()
        _loaded_adapter = None

    device = torch.device(
        "cuda" if CFG.mms_device == "cuda" and torch.cuda.is_available() else "cpu"
    )
    _model.to(device)


def _try_load_adapter(target_lang: str) -> None:
    global _loaded_adapter
    assert _processor is not None and _model is not None
    _processor.tokenizer.set_target_lang(target_lang)
    _model.load_adapter(target_lang)
    _loaded_adapter = target_lang


def _ensure_mms_adapter() -> str:
    """Load first working adapter from the try-sequence; raise if none work."""
    global _active_mms_adapter

    with _lock:
        _ensure_mms_model_and_device()
        candidates = _adapter_try_sequence()
        if not candidates:
            raise RuntimeError(
                "No MMS adapter candidates (check SACA_MMS_ADAPTER_CHAIN / SACA_MMS_WARLPIRI_LANG)."
            )
        last_err: BaseException | None = None

        if _loaded_adapter in candidates:
            _active_mms_adapter = _loaded_adapter
            return _loaded_adapter

        for lang in candidates:
            try:
                _try_load_adapter(lang)
                logger.info(
                    "MMS adapter selected=%s (attempt order was %s)",
                    lang,
                    ",".join(candidates),
                )
                _active_mms_adapter = lang
                return lang
            except Exception as exc:
                last_err = exc
                logger.warning("MMS load_adapter failed for lang=%s: %s", lang, exc)

        raise RuntimeError(
            f"No MMS adapter could be loaded from {candidates} for model {CFG.mms_model_id}. "
            f"Set SACA_MMS_ADAPTER_CHAIN (e.g. pjt) or SACA_MMS_WARLPIRI_LANG. Last error: {last_err!r}"
        ) from last_err


def transcribe_mms_waveform(waveform: np.ndarray) -> str:
    """Transcribe 16 kHz float32 mono PCM (same scale as ``AudioPipeline`` output)."""
    import torch

    _ensure_mms_adapter()

    if waveform.dtype != np.float32:
        waveform = waveform.astype(np.float32, copy=False)

    device = torch.device(
        "cuda" if CFG.mms_device == "cuda" and torch.cuda.is_available() else "cpu"
    )

    inputs = _processor(waveform, sampling_rate=16000, return_tensors="pt")
    input_values = inputs["input_values"].to(device)
    attention_mask = inputs.get("attention_mask")
    if attention_mask is not None:
        attention_mask = attention_mask.to(device)

    with torch.inference_mode():
        logits = _model(input_values, attention_mask=attention_mask).logits

    # batch_decode handles CTC blank/repeat collapsing and vocabulary post-processing
    # more correctly than manual argmax + single-sequence decode.
    predicted_ids = torch.argmax(logits, dim=-1)
    transcriptions = _processor.batch_decode(predicted_ids)
    text = transcriptions[0] if transcriptions else ""
    return (text or "").strip()
