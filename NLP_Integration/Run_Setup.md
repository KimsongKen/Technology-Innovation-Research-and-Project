# SACA Run Setup Guide (Backend + Flutter)

This guide is the complete setup and run checklist for local development and Android emulator testing.

## 1) Prerequisites

Install these first:

- Python 3.10 or 3.11
- Flutter SDK (stable)
- Android Studio (SDK + emulator tools)
- Git

Recommended:

- Windows PowerShell
- At least 8 GB RAM free for STT models

## 2) Project Paths Used In This Guide

- Backend repo root: `c:/Users/kimso/Desktop/Technology Project`
- Flutter app root: `c:/Users/kimso/develop/saca_app`

If your paths differ, adjust commands accordingly.

## 3) Backend Setup

Open PowerShell in `c:/Users/kimso/Desktop/Technology Project`.

### 3.1 Create and activate virtual environment

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

### 3.2 Install backend dependencies

```powershell
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Optional training dependencies:

```powershell
pip install -r requirements.training.txt
```

### 3.3 Configure STT runtime variables (recommended local config)

```powershell
$env:SACA_USE_MOCK_TRANSCRIBE="0"
$env:SACA_USE_FASTER_WHISPER="1"
$env:SACA_WHISPER_DEVICE="cpu"
$env:SACA_WHISPER_COMPUTE_TYPE="int8"
$env:SACA_USE_WHISPER_TINY_FALLBACK="1"
$env:SACA_WHISPER_TINY_MODEL="tiny"
$env:SACA_STT_TIMEOUT_SECONDS="20"
$env:SACA_STT_FAILURE_WARN_SECONDS="8"
$env:SACA_LOG_TRANSCRIPTS="0"
```

### 3.4 Run FastAPI

```powershell
.\run_api.ps1
```

By default this enables **English** STT (faster-whisper) and **Warlpiri voice** (Meta MMS). First MMS run downloads a large model.

Lighter server (English intake only; `wbp` **voice** will error until you use MMS or dev fallback):

```powershell
.\run_api.ps1 -EnglishOnly
```

Expected:

- Server starts with no import errors
- `GET http://127.0.0.1:8000/health` returns JSON status

## 4) Backend API Contract (Unified)

Primary triage endpoint:

- `POST /triage/predict`

Input:

- JSON body:
  - `raw_transcript`
  - `verified_transcript`
  - `language` (`en` or `wbp`)

Output JSON:

- `triage_level`
- `top_condition`
- `confidence`
- `top_3_symptoms`
- `recommendation`
- `escalation_triggered`

Voice transcription endpoints (for recorded WAV uploads):

- `POST /triage/transcribe`
- `POST /triage/analyze-voice`

## 5) Backend Smoke Test (PowerShell)

From backend root, with server running:

```powershell
curl.exe -X POST "http://127.0.0.1:8000/triage/predict" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer dev-token" `
  -d "{\"raw_transcript\":\"chest pan cant breath\",\"verified_transcript\":\"chest pain cant breathe\",\"language\":\"en\"}"
```

Voice transcribe smoke test:

```powershell
curl.exe -X POST "http://127.0.0.1:8000/triage/transcribe" `
  -H "Authorization: Bearer dev-token" `
  -F "audio_file=@temp\audio_debug\your_test.wav"
```

If you see `422` with transcript failure, inspect logs for:

- `audio_signal_stats`
- `STT MODEL FAILURE`

## 6) Flutter Setup

Open a new terminal in `c:/Users/kimso/develop/saca_app`.

### 6.1 Install Flutter packages

```powershell
flutter pub get
```

### 6.2 Verify device and toolchain

```powershell
flutter doctor
flutter devices
```

### 6.3 Run on Android emulator

```powershell
flutter run -d emulator-5554
```

The app uses Android emulator default backend host:

- `http://10.0.2.2:8000`

You can override with compile-time define:

```powershell
flutter run --dart-define=SACA_API_BASE_URL=http://10.0.2.2:8000 -d emulator-5554
```

## 7) Android Manifest and Network Checklist

File: `android/app/src/main/AndroidManifest.xml`

Ensure:

- `INTERNET` permission
- `RECORD_AUDIO` permission
- `android:usesCleartextTraffic="true"` on `<application>` for local HTTP testing
- network security config reference if used

File: `android/app/src/main/res/xml/network_security_config.xml`

- Must contain only one XML declaration at top
- Must be valid XML (no duplicate `<?xml ... ?>` line)

## 8) Voice Flow Test Checklist

1. Start backend server first.
2. Start Flutter app on emulator.
3. Tap mic to start recording.
4. Speak clearly for 2-3 seconds.
5. Tap mic again to stop and upload.
6. Confirm transcript appears in the input card.
7. Submit and confirm triage result screen.

## 9) Troubleshooting

### 9.1 Backend returns 422 Failed to generate transcript

Common causes:

- Audio is too quiet
- Emulator microphone not passing real sound
- STT provider timeout or empty decode

Checks:

- Review backend log `audio_signal_stats peak=... rms=...`
- If RMS is near zero, mic signal is not reaching app
- Check emulator mic settings in Android Emulator extended controls

### 9.2 Same transcript every time

Cause:

- Mock transcription enabled

Fix:

- Set `SACA_USE_MOCK_TRANSCRIBE="0"` and restart backend

### 9.3 Flutter cannot connect to backend

Checks:

- Backend is running on `127.0.0.1:8000` (host machine)
- Flutter emulator uses `10.0.2.2:8000`
- Windows firewall allows Python process on local network profile

### 9.4 Build fails with network security XML error

Cause:

- malformed `network_security_config.xml` (often duplicate XML declaration)

Fix:

- keep only one `<?xml version="1.0" encoding="utf-8"?>`
- rebuild with `flutter clean` then `flutter run`

### 9.5 RenderFlex overflow in cards

Fix path:

- verify latest responsive UI updates in `lib/widgets/cards.dart`

## 10) Clean Restart Procedure

If environment becomes unstable:

Backend terminal:

1. Stop server (`Ctrl + C`)
2. Re-activate venv
3. Re-export env vars
4. Restart uvicorn

Flutter terminal:

1. `flutter clean`
2. `flutter pub get`
3. `flutter run -d emulator-5554`

## 11) Daily Run Commands (Quick Copy)

Backend:

```powershell
cd "c:\Users\kimso\Desktop\Technology Project"
.\.venv\Scripts\Activate.ps1
$env:SACA_USE_MOCK_TRANSCRIBE="0"
$env:SACA_USE_FASTER_WHISPER="1"
$env:SACA_WHISPER_DEVICE="cpu"
$env:SACA_WHISPER_COMPUTE_TYPE="int8"
$env:SACA_USE_WHISPER_TINY_FALLBACK="1"
.\.venv\Scripts\python.exe -m uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload
```

Flutter:

```powershell
cd "c:\Users\kimso\develop\saca_app"
flutter pub get
flutter run -d emulator-5554
```

## 12) Related Docs

- Repo overview: `README.md`
- Integration archive notes: `archive/README.md`
