"""Append-only audit files for verifying voice STT vs patient/clinical transcripts (local QA)."""

from __future__ import annotations

import json
import logging
import re
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from api.bridge.config import CFG

logger = logging.getLogger("saca.bridge.transcript_audit")
_lock = threading.Lock()


def _safe_snippet(s: str, max_len: int = 8000) -> str:
    t = (s or "").replace("\r\n", "\n")
    if len(t) > max_len:
        return t[: max_len - 20] + "\n... [truncated]"
    return t


def _audit_base_dir() -> Path:
    root = CFG.transcript_audit_dir
    day = datetime.now(timezone.utc).strftime("%Y%m%d")
    d = root / day
    d.mkdir(parents=True, exist_ok=True)
    return d


def _slug(s: str, max_len: int = 40) -> str:
    x = re.sub(r"[^\w\-]+", "_", (s or "").strip().lower())
    x = re.sub(r"_+", "_", x).strip("_")
    return (x[:max_len] or "session").rstrip("_")


def write_transcript_audit(
    *,
    source: str,
    language: str,
    voice_transcript_as_recognized: str | None = None,
    patient_verified_transcript: str | None = None,
    patient_normalized_for_sbert: str | None = None,
    stt_provider: str | None = None,
    mms_adapter: str | None = None,
    audio_temp_relpath: str | None = None,
    extra: dict[str, Any] | None = None,
) -> Path | None:
    """
    Write one human-readable ``.txt`` plus one JSON line in ``transcript_audit.jsonl`` under
    ``SACA_TRANSCRIPT_AUDIT_DIR/YYYYMMDD/``.
    """
    if not CFG.transcript_audit_enabled:
        return None

    base = _audit_base_dir()
    ts = datetime.now(timezone.utc).strftime("%H%M%S")
    ms = int(time.time() * 1000) % 1000
    sid = f"{ts}_{ms:03d}_{_slug(source)}"

    record: dict[str, Any] = {
        "utc_iso": datetime.now(timezone.utc).isoformat(),
        "source": source,
        "language": language,
        "voice_transcript_as_recognized": voice_transcript_as_recognized,
        "patient_verified_transcript": patient_verified_transcript,
        "patient_normalized_for_sbert": patient_normalized_for_sbert,
        "stt_provider": stt_provider,
        "mms_adapter": mms_adapter,
        "audio_temp_relpath": audio_temp_relpath,
    }
    if extra:
        record["extra"] = extra

    txt_path = base / f"transcript_{sid}.txt"
    lines = [
        "# SACA transcript audit (local verification)\n",
        f"utc_iso: {record['utc_iso']}\n",
        f"source: {source}\n",
        f"language: {language}\n",
    ]
    if stt_provider:
        lines.append(f"stt_provider: {stt_provider}\n")
    if mms_adapter:
        lines.append(f"mms_active_adapter: {mms_adapter}\n")
    if audio_temp_relpath:
        lines.append(f"audio_temp_file: {audio_temp_relpath}\n")
    lines.append("\n## voice_transcript_as_recognized (raw STT output)\n")
    lines.append(_safe_snippet(voice_transcript_as_recognized or "") + "\n")
    lines.append("\n## patient_verified_transcript (client / form; may match STT before edits)\n")
    lines.append(_safe_snippet(patient_verified_transcript or "") + "\n")
    lines.append("\n## patient_normalized_for_sbert (after translate_clinical_transcript / dictionary bridge)\n")
    lines.append(_safe_snippet(patient_normalized_for_sbert or "") + "\n")

    try:
        with _lock:
            txt_path.write_text("".join(lines), encoding="utf-8")
            jsonl = base / "transcript_audit.jsonl"
            with jsonl.open("a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except OSError as exc:
        logger.warning("transcript audit write failed: %s", exc)
        return None

    logger.info("transcript_audit written path=%s", txt_path)
    return txt_path
