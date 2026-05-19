#!/usr/bin/env python3
"""
Generate WAV test audio for all 10 Warlpiri clinical scenarios.

Each file contains a spoken English sentence that:
  1. Introduces the scenario ("A Warlpiri patient says:")
  2. Reads the Warlpiri phrase phonetically (as an Australian English speaker
     would approximate it — not real Warlpiri pronunciation, but sufficient to
     test the audio pipeline)
  3. Translates it to English for the listener

This gives you 10 WAV files you can:
  • Play during a demo to illustrate what the system hears
  • Send to the API via curl or test_warlpiri_api.py to test the full pipeline

Requirements (one of the following):
  Option A — edge-tts  (recommended, Australian English voice, needs internet on first run)
      pip install edge-tts
  Option B — pyttsx3   (offline fallback, voice quality varies by OS)
      pip install pyttsx3
  Option C — gTTS      (Google TTS, needs internet)
      pip install gtts

Run:
    python tests/generate_test_audio.py

Output: tests/audio/TC-01_heart_attack.wav  … TC-10_anaemia.wav
"""

from __future__ import annotations

import asyncio
import json
import sys
import wave
from pathlib import Path

_ROOT = Path(__file__).resolve().parent.parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

CASES_PATH = Path(__file__).parent / "warlpiri_test_cases.json"
AUDIO_DIR  = Path(__file__).parent / "audio"
AUDIO_DIR.mkdir(exist_ok=True)

# Australian English voice for edge-tts
EDGE_VOICE = "en-AU-NatashaNeural"


def _spoken_script(case: dict) -> str:
    """Build the spoken text for each test case."""
    phrase    = case["speak_as"]
    scenario  = case["scenario"]
    english   = case["warlpiri_english_description"]
    triage    = case["expected_triage"]
    return (
        f"Test case {case['id']}. Scenario: {scenario}. "
        f"A Warlpiri patient says: {phrase}. "
        f"This means: {english}. "
        f"Expected triage level: {triage}."
    )


def _safe_filename(case: dict) -> str:
    slug = case["scenario"].lower().replace(" ", "_").replace("/", "_").replace("—", "")
    slug = "".join(c for c in slug if c.isalnum() or c == "_")
    return f"{case['id']}_{slug}.wav"


# ── Option A: edge-tts ────────────────────────────────────────────────────────

async def _generate_edge_tts(cases: list[dict]) -> bool:
    try:
        import edge_tts  # type: ignore
    except ImportError:
        return False

    print("Using edge-tts (en-AU-NatashaNeural) …\n")
    for case in cases:
        script = _spoken_script(case)
        out_path = AUDIO_DIR / _safe_filename(case)
        communicate = edge_tts.Communicate(script, EDGE_VOICE)
        # edge-tts saves MP3 by default; we need WAV
        mp3_path = out_path.with_suffix(".mp3")
        await communicate.save(str(mp3_path))
        _mp3_to_wav(mp3_path, out_path)
        mp3_path.unlink(missing_ok=True)
        print(f"  [ok] {out_path.name}")
    return True


def _mp3_to_wav(mp3_path: Path, wav_path: Path) -> None:
    """Convert mp3 → wav using pydub if available, else keep as mp3 renamed."""
    try:
        from pydub import AudioSegment  # type: ignore
        AudioSegment.from_mp3(str(mp3_path)).set_frame_rate(16000).set_channels(1).export(
            str(wav_path), format="wav"
        )
    except Exception:
        # pydub not available — rename mp3 to wav (API will reject it but it plays in browsers)
        mp3_path.rename(wav_path.with_suffix(".mp3"))
        print(f"    (saved as .mp3 — install pydub+ffmpeg for true WAV conversion)")


# ── Option B: pyttsx3 (offline) ───────────────────────────────────────────────

def _generate_pyttsx3(cases: list[dict]) -> bool:
    try:
        import pyttsx3  # type: ignore
    except ImportError:
        return False

    print("Using pyttsx3 (offline) …\n")
    engine = pyttsx3.init()
    # Prefer a slower rate so Warlpiri words are clearer
    engine.setProperty("rate", 150)
    # Try to find an Australian or clear English voice
    voices = engine.getProperty("voices")
    for v in voices:
        if "australia" in (v.name or "").lower() or "natasha" in (v.name or "").lower():
            engine.setProperty("voice", v.id)
            break

    for case in cases:
        script = _spoken_script(case)
        out_path = AUDIO_DIR / _safe_filename(case)
        engine.save_to_file(script, str(out_path))
        engine.runAndWait()
        _ensure_pcm16_wav(out_path)
        print(f"  [ok] {out_path.name}")
    return True


# ── Option C: gTTS ────────────────────────────────────────────────────────────

def _generate_gtts(cases: list[dict]) -> bool:
    try:
        from gtts import gTTS  # type: ignore
    except ImportError:
        return False

    print("Using gTTS (en-AU, Google TTS) …\n")
    for case in cases:
        script = _spoken_script(case)
        out_path = AUDIO_DIR / _safe_filename(case)
        tts = gTTS(text=script, lang="en", tld="com.au", slow=False)
        mp3_path = out_path.with_suffix(".mp3")
        tts.save(str(mp3_path))
        _mp3_to_wav(mp3_path, out_path)
        mp3_path.unlink(missing_ok=True)
        print(f"  [ok] {out_path.name}")
    return True


# ── Option D: silent WAV fallback (tests pipeline without meaningful speech) ──

def _generate_silent_wav(case: dict) -> Path:
    """1 second of silence — useful as a structural placeholder for the test suite."""
    import numpy as np
    out_path = AUDIO_DIR / _safe_filename(case)
    sr = 16000
    silence = np.zeros(sr, dtype=np.int16)
    with wave.open(str(out_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(silence.tobytes())
    return out_path


def _ensure_pcm16_wav(path: Path) -> None:
    """Verify or re-encode to PCM16 16 kHz mono (for pyttsx3 output)."""
    try:
        with wave.open(str(path), "rb") as wf:
            if wf.getsampwidth() == 2 and wf.getframerate() == 16000:
                return  # already correct
            # Re-read and downsample
            import numpy as np
            frames = wf.readframes(wf.getnframes())
            sr = wf.getframerate()
            sw = wf.getsampwidth()
            ch = wf.getnchannels()
        if sw == 2:
            arr = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0
        else:
            arr = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0
        if ch > 1:
            arr = arr.reshape(-1, ch).mean(axis=1)
        # Resample to 16k
        target_len = int(len(arr) * 16000 / sr)
        idx = np.linspace(0, len(arr) - 1, target_len)
        left = np.floor(idx).astype(np.int64)
        right = np.minimum(left + 1, len(arr) - 1)
        frac = (idx - left).astype(np.float32)
        arr = (arr[left] * (1 - frac) + arr[right] * frac).astype(np.float32)
        pcm = np.clip(arr * 32767, -32768, 32767).astype(np.int16)
        with wave.open(str(path), "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(16000)
            wf.writeframes(pcm.tobytes())
    except Exception:
        pass  # leave file as-is if re-encoding fails


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    cases = json.loads(CASES_PATH.read_text(encoding="utf-8"))

    print(f"\nGenerating {len(cases)} Warlpiri clinical test audio files")
    print(f"Output directory: {AUDIO_DIR}\n")

    # Try each TTS option in order of quality
    success = asyncio.run(_generate_edge_tts(cases))
    if not success:
        success = _generate_pyttsx3(cases)
    if not success:
        success = _generate_gtts(cases)

    if not success:
        print(
            "No TTS library found. Install one of:\n"
            "  pip install edge-tts          (best quality, Australian voice)\n"
            "  pip install pyttsx3           (offline)\n"
            "  pip install gtts              (Google TTS)\n\n"
            "Generating silent placeholder WAV files instead …\n"
        )
        for case in cases:
            path = _generate_silent_wav(case)
            print(f"  (silent) {path.name}")

    print(f"\nDone. {len(list(AUDIO_DIR.glob('*.wav')))} WAV files in {AUDIO_DIR}")
    print("\nNext steps:")
    print("  1. Play any file to hear the scenario description")
    print("  2. Run:  python tests/test_warlpiri_api.py  (needs the API running)")
    print("  3. Or send one file manually:")
    print('     curl -X POST http://localhost:8000/triage/analyze-voice \\')
    print('          -H "Authorization: Bearer dev-token" \\')
    print('          -F "audio_file=@tests/audio/TC-01_heart_attack.wav" \\')
    print('          -F "language=wbp"')


if __name__ == "__main__":
    main()
