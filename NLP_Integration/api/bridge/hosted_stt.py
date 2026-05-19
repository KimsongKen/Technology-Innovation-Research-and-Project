"""Optional cloud ASR (OpenAI-compatible ``/v1/audio/transcriptions``).

Use for English (and similar) intakes when you want a managed model without local GPU.
Warlpiri (``wbp``) voice still uses :mod:`api.bridge.warlpiri_stt` (MMS) in the router;
this module is used from :class:`api.bridge.stt_service.STTService` for ``en-AU`` paths.
"""

from __future__ import annotations

import logging
from typing import Any

logger = logging.getLogger("saca.bridge.hosted_stt")


def openai_transcription_language(language: str) -> str | None:
    """Map route language hints to ISO-639-1 for OpenAI ``language`` (optional)."""
    l = (language or "").strip().lower().replace("_", "-")
    if l in {"", "en", "en-au", "english"}:
        return "en"
    if len(l) == 2 and l.isalpha():
        return l
    if len(l) >= 2 and l[0:2].isalpha() and (len(l) == 2 or l[2] in {"-", "_"}):
        return l[0:2]
    return None


async def transcribe_openai_compatible(
    *,
    wav_bytes: bytes,
    api_key: str,
    base_url: str,
    model: str,
    language: str | None,
    timeout_seconds: float,
) -> str:
    """
    POST multipart audio to ``{base}/audio/transcriptions``.

    ``base_url`` should be like ``https://api.openai.com/v1`` (no trailing slash required).
    Works with OpenAI and many proxies / Azure OpenAI-style gateways that expose the same route.
    """
    import httpx

    url = f"{base_url.rstrip('/')}/audio/transcriptions"
    headers = {"Authorization": f"Bearer {api_key}"}
    data: dict[str, Any] = {"model": model}
    if language:
        data["language"] = language
    files = {"file": ("audio.wav", wav_bytes, "audio/wav")}

    async with httpx.AsyncClient(timeout=timeout_seconds) as client:
        response = await client.post(url, headers=headers, data=data, files=files)

    if response.status_code >= 400:
        body = (response.text or "")[:500]
        logger.warning(
            "hosted STT HTTP %s: %s",
            response.status_code,
            body,
        )
        response.raise_for_status()

    payload = response.json()
    text = str(payload.get("text", "")).strip()
    return text
