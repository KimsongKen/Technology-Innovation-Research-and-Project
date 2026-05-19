from __future__ import annotations

import wave
from dataclasses import dataclass
from io import BytesIO
from pathlib import Path

import numpy as np


# ---------------------------------------------------------------------------
# WAV decoding — supports 8, 16, 24, 32-bit int and 32-bit float
# ---------------------------------------------------------------------------

def _decode_wav_to_float32(wav_bytes: bytes) -> tuple[np.ndarray, int]:
    """Decode any standard PCM WAV to float32 mono in [-1, 1]."""
    with wave.open(BytesIO(wav_bytes), "rb") as wf:
        ch = wf.getnchannels()
        sw = wf.getsampwidth()   # bytes per sample per channel
        sr = wf.getframerate()
        n_frames = wf.getnframes()
        raw = wf.readframes(n_frames)

    if sw == 1:
        # 8-bit WAV is unsigned
        arr = np.frombuffer(raw, dtype=np.uint8).astype(np.float32) / 127.5 - 1.0
    elif sw == 2:
        arr = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    elif sw == 3:
        # 24-bit little-endian signed — no native numpy dtype
        b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
        i32 = (
            b[:, 0].astype(np.int32)
            | (b[:, 1].astype(np.int32) << 8)
            | (b[:, 2].astype(np.int32) << 16)
        )
        # Sign-extend from bit 23
        i32 = np.where(i32 >= 0x800000, i32 - 0x1000000, i32)
        arr = i32.astype(np.float32) / 8388608.0
    elif sw == 4:
        # Try float32 first (e.g. some mobile recorders); fall back to int32
        f32 = np.frombuffer(raw, dtype=np.float32)
        if np.all(np.abs(f32) <= 1.05):
            arr = np.clip(f32, -1.0, 1.0)
        else:
            arr = np.frombuffer(raw, dtype=np.int32).astype(np.float32) / 2147483648.0
    else:
        raise ValueError(f"Unsupported WAV sample width: {sw} bytes")

    # Downmix multi-channel to mono
    if ch > 1:
        arr = arr.reshape(-1, ch).mean(axis=1)

    return arr.astype(np.float32), sr


# ---------------------------------------------------------------------------
# Resampling — pure numpy, no scipy dependency
# ---------------------------------------------------------------------------

def _resample(waveform: np.ndarray, orig_sr: int, target_sr: int) -> np.ndarray:
    if orig_sr == target_sr:
        return waveform
    orig_len = len(waveform)
    target_len = int(orig_len * target_sr / orig_sr)
    if target_len == 0:
        return np.zeros(0, dtype=np.float32)
    idx = np.linspace(0, orig_len - 1, target_len)
    left = np.floor(idx).astype(np.int64)
    right = np.minimum(left + 1, orig_len - 1)
    frac = (idx - left).astype(np.float32)
    return (waveform[left] * (1.0 - frac) + waveform[right] * frac).astype(np.float32)


# ---------------------------------------------------------------------------
# Signal cleaning helpers
# ---------------------------------------------------------------------------

def _remove_dc_offset(waveform: np.ndarray) -> np.ndarray:
    if waveform.size == 0:
        return waveform
    return (waveform - waveform.mean()).astype(np.float32)


def _trim_silence(
    waveform: np.ndarray,
    sr: int,
    frame_ms: int = 20,
    threshold_rms: float = 0.008,
    pad_ms: int = 100,
) -> np.ndarray:
    """Remove leading/trailing silence using short-time RMS framing."""
    if waveform.size == 0:
        return waveform
    frame_len = max(1, int(sr * frame_ms / 1000))
    n_frames = len(waveform) // frame_len
    if n_frames == 0:
        return waveform
    frames = waveform[: n_frames * frame_len].reshape(n_frames, frame_len)
    rms_per_frame = np.sqrt(np.mean(frames ** 2, axis=1))
    active = np.where(rms_per_frame >= threshold_rms)[0]
    if active.size == 0:
        return waveform  # entirely silent — let the STT layer handle it
    pad = int(sr * pad_ms / 1000)
    first = max(0, active[0] * frame_len - pad)
    last = min(len(waveform), (active[-1] + 1) * frame_len + pad)
    return waveform[first:last]


def _rms_normalize(waveform: np.ndarray, target_rms: float = 0.08) -> np.ndarray:
    """Scale to a fixed RMS level; cap gain at +20 dB to avoid noise amplification."""
    if waveform.size == 0:
        return waveform
    rms = float(np.sqrt(np.mean(waveform ** 2)))
    if rms < 1e-9:
        return waveform
    gain = min(target_rms / rms, 10.0)  # 10× = 20 dB max
    return np.clip(waveform * gain, -1.0, 1.0).astype(np.float32)


# ---------------------------------------------------------------------------
# Quality metrics
# ---------------------------------------------------------------------------

@dataclass
class AudioQualityMetrics:
    duration_seconds: float
    peak: float
    rms: float
    clipping_ratio: float  # fraction of samples at/near full scale
    is_silent: bool        # RMS below speech floor
    is_clipped: bool       # >1% samples clipped
    is_too_short: bool     # under 300 ms — unlikely to be real speech


def _compute_metrics(waveform: np.ndarray, sr: int) -> AudioQualityMetrics:
    if waveform.size == 0:
        return AudioQualityMetrics(0.0, 0.0, 0.0, 0.0, True, False, True)
    peak = float(np.max(np.abs(waveform)))
    rms = float(np.sqrt(np.mean(waveform ** 2)))
    clipping_ratio = float(np.mean(np.abs(waveform) >= 0.99))
    duration = len(waveform) / max(sr, 1)
    return AudioQualityMetrics(
        duration_seconds=duration,
        peak=peak,
        rms=rms,
        clipping_ratio=clipping_ratio,
        is_silent=rms < 0.005,
        is_clipped=clipping_ratio > 0.01,
        is_too_short=duration < 0.3,
    )


# ---------------------------------------------------------------------------
# Public pipeline class
# ---------------------------------------------------------------------------

class AudioPipeline:
    def __init__(self, target_rate: int = 16000) -> None:
        self.target_rate = target_rate

    def process_wav_bytes(self, wav_bytes: bytes) -> tuple[np.ndarray, AudioQualityMetrics]:
        """Full pipeline: decode → mono → resample → DC remove → trim silence → RMS normalize.

        Returns a float32 waveform at ``target_rate`` Hz and quality metrics.
        Supports 8, 16, 24, 32-bit PCM and 32-bit float WAV from any channel count.
        """
        waveform, sr = _decode_wav_to_float32(wav_bytes)
        if sr != self.target_rate:
            waveform = _resample(waveform, sr, self.target_rate)
        waveform = _remove_dc_offset(waveform)
        waveform = _trim_silence(waveform, self.target_rate)
        waveform = _rms_normalize(waveform)
        metrics = _compute_metrics(waveform, self.target_rate)
        return waveform, metrics

    def normalize_wav_to_pcm16_16k(self, wav_bytes: bytes) -> tuple[bytes, int]:
        """Backward-compat method used by legacy callers. Prefer process_wav_bytes()."""
        waveform, _ = self.process_wav_bytes(wav_bytes)
        pcm = np.clip(waveform * 32767.0, -32768, 32767).astype(np.int16)
        return pcm.tobytes(), self.target_rate

    @staticmethod
    def pcm16_to_float32(pcm16_bytes: bytes) -> np.ndarray:
        return np.frombuffer(pcm16_bytes, dtype=np.int16).astype(np.float32) / 32768.0

    @staticmethod
    def float32_mono_to_wav_bytes(waveform: np.ndarray, sample_rate: int | None = None) -> bytes:
        """Encode mono float32 [-1, 1] PCM as 16-bit LE WAV (for cloud STT uploads)."""
        rate = sample_rate if sample_rate is not None else 16000
        pcm = np.clip(waveform.astype(np.float64) * 32767.0, -32768, 32767).astype(np.int16)
        buf = BytesIO()
        with wave.open(buf, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(rate)
            wf.writeframes(pcm.tobytes())
        return buf.getvalue()


class RetentionStore:
    def __init__(self, root: Path, retention_seconds: int) -> None:
        self.root = root
        self.retention_seconds = retention_seconds
        self.root.mkdir(parents=True, exist_ok=True)

    def save_audio(self, session_id: str, wav_bytes: bytes) -> Path:
        target = self.root / f"{session_id}.wav"
        target.write_bytes(wav_bytes)
        return target
