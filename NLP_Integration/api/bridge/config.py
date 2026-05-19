from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path


_DEFAULT_CLINICAL_WHISPER_PROMPT = (
    "Clinical and emergency care vocabulary. Symptoms include chest pain, shortness of breath, "
    "difficulty breathing, cannot breathe, fever, cough, headache, dizziness, nausea, vomiting, "
    "diarrhea, abdominal pain, sore throat, fatigue, weakness, chills, wheezing, palpitations, "
    "fainting, bleeding, confusion, seizure, weakness on one side, slurred speech, stroke, "
    "heart attack, pneumonia."
)


def _whisper_prompt_from_env() -> str | None:
    if os.getenv("SACA_WHISPER_NO_INITIAL_PROMPT", "") in {"1", "true", "yes"}:
        return None
    raw = os.getenv("SACA_WHISPER_INITIAL_PROMPT")
    if raw is not None:
        return raw.strip() or None
    return _DEFAULT_CLINICAL_WHISPER_PROMPT


@dataclass(frozen=True)
class BridgeConfig:
    host: str = os.getenv("SACA_BRIDGE_HOST", "0.0.0.0")
    port: int = int(os.getenv("SACA_BRIDGE_PORT", "8000"))
    auth_token: str = os.getenv("SACA_BRIDGE_AUTH_TOKEN", "dev-token")
    cors_allow_origins: tuple[str, ...] = tuple(
        o.strip()
        for o in os.getenv("SACA_CORS_ALLOW_ORIGINS", "http://localhost,http://127.0.0.1").split(",")
        if o.strip()
    )
    cors_allow_origin_regex: str = os.getenv(
        "SACA_CORS_ALLOW_ORIGIN_REGEX",
        r"^https?://(localhost|127\.0\.0\.1|10\.0\.2\.2|192\.168\.\d+\.\d+)(:\d+)?$",
    )
    stt_timeout_seconds: float = float(os.getenv("SACA_STT_TIMEOUT_SECONDS", "10.0"))
    stt_failure_warn_seconds: float = float(os.getenv("SACA_STT_FAILURE_WARN_SECONDS", "10.0"))
    # Hosted ASR (OpenAI-compatible /v1/audio/transcriptions). Tried first in STTService when enabled + key set.
    use_hosted_stt: bool = os.getenv("SACA_USE_HOSTED_STT", "0") in {"1", "true", "yes"}
    hosted_stt_provider: str = (
        os.getenv("SACA_HOSTED_STT_PROVIDER", "openai").strip().lower() or "openai"
    )
    hosted_stt_base_url: str = os.getenv(
        "SACA_HOSTED_STT_BASE_URL", "https://api.openai.com/v1"
    ).strip()
    hosted_stt_model: str = os.getenv("SACA_HOSTED_STT_MODEL", "whisper-1").strip() or "whisper-1"
    hosted_stt_timeout_seconds: float = float(os.getenv("SACA_HOSTED_STT_TIMEOUT_SECONDS", "120"))
    hosted_stt_api_key: str = field(
        default_factory=lambda: (
            os.getenv("SACA_HOSTED_STT_API_KEY") or os.getenv("OPENAI_API_KEY") or ""
        ).strip()
    )
    # Local faster-whisper (CTranslate2). For GPU + best WER: SACA_WHISPER_DEVICE=cuda,
    # SACA_WHISPER_COMPUTE_TYPE=float16, SACA_WHISPER_MODEL=large-v3 (or medium).
    use_faster_whisper: bool = os.getenv("SACA_USE_FASTER_WHISPER", "0") in {"1", "true", "yes"}
    faster_whisper_model: str = os.getenv("SACA_WHISPER_MODEL", "small")
    faster_whisper_device: str = os.getenv("SACA_WHISPER_DEVICE", "cpu")
    faster_whisper_compute_type: str = os.getenv("SACA_WHISPER_COMPUTE_TYPE", "int8")
    faster_whisper_beam_size: int = max(1, int(os.getenv("SACA_WHISPER_BEAM_SIZE", "5")))
    faster_whisper_vad_filter: bool = os.getenv("SACA_WHISPER_VAD_FILTER", "1") not in {"0", "false", "no"}
    faster_whisper_initial_prompt: str | None = field(default_factory=_whisper_prompt_from_env)
    use_whisper_tiny_fallback: bool = os.getenv("SACA_USE_WHISPER_TINY_FALLBACK", "0") in {"1", "true", "yes"}
    whisper_tiny_model: str = os.getenv("SACA_WHISPER_TINY_MODEL", "tiny")
    uploads_dir: Path = Path(os.getenv("SACA_UPLOADS_DIR", "output/uploads"))
    temp_audio_dir: Path = Path(os.getenv("SACA_TEMP_AUDIO_DIR", "temp/audio_debug"))
    retention_seconds: int = int(os.getenv("SACA_UPLOAD_RETENTION_SECONDS", "900"))
    log_transcripts: bool = os.getenv("SACA_LOG_TRANSCRIPTS", "0") in {"1", "true", "yes"}
    transcript_audit_enabled: bool = os.getenv("SACA_TRANSCRIPT_AUDIT", "0") in {"1", "true", "yes"}
    transcript_audit_dir: Path = Path(
        os.getenv("SACA_TRANSCRIPT_AUDIT_DIR", str(Path("temp") / "transcript_audit"))
    )
    catboost_model_dir: Path = Path(
        os.getenv(
            "SACA_CATBOOST_MODEL_DIR",
            str(Path("archive") / "saca_model_evaluation" / "catboost_runtime_artifacts"),
        )
    )
    low_confidence_triage_threshold: float = float(
        os.getenv("SACA_LOW_CONFIDENCE_TRIAGE_THRESHOLD", "0.40")
    )
    # MMS (optional): used when the client sends language=wbp for voice intake.
    # Default adapter pjt — Warlpiri (wbp) is not listed on mms-1b-all; override for custom checkpoints.
    use_mms_warlpiri_stt: bool = os.getenv("SACA_USE_MMS_WARLPIRI_STT", "0") in {"1", "true", "yes"}
    # Dev-only: when MMS is off, transcribe Warlpiri mode with English Whisper (inaccurate for wbp).
    warlpiri_stt_dev_fallback_english: bool = os.getenv(
        "SACA_WARLPIRI_STT_DEV_FALLBACK", "0"
    ) in {"1", "true", "yes"}
    mms_model_id: str = os.getenv("SACA_MMS_MODEL_ID", "facebook/mms-1b-all")
    # For Warlpiri accuracy: try ISO 639-3 "wbp" on the MMS checkpoint before falling back (e.g. pjt).
    mms_try_wbp_adapter_first: bool = os.getenv("SACA_MMS_TRY_WBP_FIRST", "1") not in {
        "0",
        "false",
        "no",
    }
    mms_warlpiri_lang: str = os.getenv("SACA_MMS_WARLPIRI_LANG", "pjt")
    mms_device: str = os.getenv("SACA_MMS_DEVICE", "cpu")
    mms_stt_timeout_seconds: float = float(os.getenv("SACA_MMS_STT_TIMEOUT_SECONDS", "180"))
    # Optional override: comma-separated adapter codes, first working wins (e.g. "wbp,pjt").
    mms_adapter_chain: str = os.getenv("SACA_MMS_ADAPTER_CHAIN", "").strip()


CFG = BridgeConfig()

