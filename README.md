# SACA Integration Archive README

This document is the consolidated technical record of the current SACA integration state across backend and frontend.

It covers:

- What is currently deployed and used
- What was migrated/removed from legacy flows
- API contract used by Flutter
- STT model options and runtime toggles
- Debugging and operations guidance
- Archive policy for old artifacts

---

## 1) Project State (Current)

SACA now runs as a **Secure Bridge FastAPI service** for voice triage:

1. Flutter records audio (`.wav`)
2. Backend receives `UploadFile`
3. STT transcribes speech to text
4. SBERT encodes transcript to semantic vector
5. Triage service returns a deterministic JSON response

Primary endpoint:

- `POST /triage/analyze-voice`

Primary response fields:

- `transcript` (string)
- `triage_level` (`Severe` | `Moderate` | `Mild`)
- `top_condition` (string)
- `recommendation` (string)

---

## 2) Backend Architecture

Backend app entry:

- `api/main.py`

Core router:

- `api/bridge/router.py`

Supporting services:

- `api/bridge/stt_service.py`
- `api/bridge/nlp_service.py`
- `api/bridge/triage_service.py`
- `api/bridge/audio_pipeline.py`
- `api/bridge/security.py`
- `api/bridge/config.py`

### Pipeline

- Audio normalization: mono PCM16 @ 16kHz
- STT providers:
  - faster-whisper (primary when enabled)
  - whisper-tiny (optional fallback when enabled)
  - mock mode (for deterministic bridge tests)
- NLP:
  - `sentence-transformers/all-MiniLM-L6-v2`
- Triage:
  - symptom phrase matching + pain map + semantic risk bias

---

## 3) Frontend Integration (Flutter)

Frontend app:

- `c:/Users/kimso/develop/saca_app/lib/main.dart`

Integrated behavior:

- Voice mode:
  - records `.wav`
  - sends to backend for transcription and triage
  - displays transcript in UI
  - continues to result screen
- Text mode:
  - mic interaction removed
  - text-only user flow
- Added verbose diagnostics:
  - permission status
  - recorded file path and size
  - upload URL, status code, response snippet

Resolved UI issues:

- Removed duplicate question rendering in voice flow
- Corrected route mismatch and fallback upload behavior

---

## 4) API Routes (Current + Compatibility)

### Core production route

- `POST /triage/analyze-voice`

### Compatibility routes (kept during migration)

- `POST /v2/triage/analyze-voice`
- `POST /v2/triage/predict-multipart`
- `POST /triage/predict-multipart`
- `POST /v2/transcribe`
- `POST /transcribe`
- `POST /triage/transcribe`

These compatibility routes exist to prevent frontend downtime while old clients are phased out.

---

## 5) STT Runtime Controls (Env Vars)

Set before launching uvicorn:

- `SACA_USE_MOCK_TRANSCRIBE` (`0`/`1`)
- `SACA_USE_FASTER_WHISPER` (`0`/`1`)
- `SACA_WHISPER_MODEL` (default: `small`)
- `SACA_WHISPER_DEVICE` (default: `cpu`)
- `SACA_WHISPER_COMPUTE_TYPE` (default: `int8`)
- `SACA_USE_WHISPER_TINY_FALLBACK` (`0`/`1`)
- `SACA_WHISPER_TINY_MODEL` (default: `tiny`)
- `SACA_STT_TIMEOUT_SECONDS` (default: `10.0`)
- `SACA_STT_FAILURE_WARN_SECONDS` (default: `10.0`)
- `SACA_LOG_TRANSCRIPTS` (`0`/`1`)

Recommended stable local config:

- `SACA_USE_MOCK_TRANSCRIBE=0`
- `SACA_USE_FASTER_WHISPER=1`
- `SACA_WHISPER_DEVICE=cpu`
- `SACA_WHISPER_COMPUTE_TYPE=int8`
- `SACA_USE_WHISPER_TINY_FALLBACK=1`

---

## 6) Model and Artifact Notes

Runtime currently reads:

- `disease_names.pkl`
- `symptom_columns.pkl`

Archive/legacy artifacts are retained for rollback/reference and should not be treated as active production runtime inputs unless explicitly wired.

This includes files under:

- `archive/legacy_models/`
- historical training outputs in `model_comparison/` and `model_training2/`

---

## 7) Debugging Guidance

### If transcript is always identical

- Check `SACA_USE_MOCK_TRANSCRIBE`
- If set to `1`, backend intentionally returns mock text

### If transcript returns 422 (`Failed to generate transcript`)

- Audio capture may still be valid; STT provider likely failed or disabled
- Check backend logs for:
  - `STT MODEL FAILURE ... reason=timeout`
  - `... reason=exception`
  - `... reason=empty transcript`

### If faster-whisper fails with CUDA DLL errors

- Use CPU mode:
  - `SACA_WHISPER_DEVICE=cpu`
  - `SACA_WHISPER_COMPUTE_TYPE=int8`

### Verify received audio integrity

- Backend stores temporary debug audio under:
  - `temp/audio_debug/`

---

## 8) Local Run

From `c:/Users/kimso/Desktop/Technology Project`:

```powershell
$env:SACA_USE_MOCK_TRANSCRIBE="0"
$env:SACA_USE_FASTER_WHISPER="1"
$env:SACA_WHISPER_DEVICE="cpu"
$env:SACA_WHISPER_COMPUTE_TYPE="int8"
$env:SACA_USE_WHISPER_TINY_FALLBACK="1"
.\.venv\Scripts\python.exe -m uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload
```

---

## 9) Migration Summary (What Changed)

- Removed websocket/live transcription dependency from core backend architecture
- Standardized around a linear audio-to-JSON pipeline
- Added strict upload/STT instrumentation
- Added fallback STT provider toggle
- Aligned Flutter request/response contract with backend
- Added temporary compatibility routes for legacy clients

---

## 10) Archive Policy

This `archive` area is for:

- Legacy artifacts kept for rollback
- Documentation of past architecture and migration context

Do not delete archived model binaries without explicit approval from project owner.
