# SACA Flutter App

Smart Adaptive Clinical Assistant (SACA) is a Flutter triage prototype for remote clinical workflows, with bilingual support for English and Warlpiri.

Repository path: [Technology-Innovation-Research-and-Project / saca_app_flutter](https://github.com/KimsongKen/Technology-Innovation-Research-and-Project/tree/main/saca_app_flutter)

## What This App Does

- Capture patient input through:
  - Voice (microphone recording + STT transcript via Groq / faster-whisper)
  - Text typing
  - Visual body-area selection (interactive 3-D body model)
- Run triage analysis through a FastAPI backend
- Present a clean, action-oriented result:
  - Triage level
  - Top condition
  - Recommendation
  - Escalation alert

## Current Feature Set

- **Full bilingual UI** — English and Warlpiri (wbp) — toggle from the quick-actions menu
- 3-D interactive body model with bilingual region labels (front + back view)
- Multi-step clinical questionnaire (voice, text, and point-and-select modes)
- Live pain slider — moves in real-time as STT returns speech ("six out of ten" → 6)
- Voice transcript append + editable verification per step
- Real-time permission UX for microphone access
- Result dashboard with `ALERT CLINIC` and `NEW ASSESSMENT` (bilingual)
- Desktop-friendly hover interactions and modern card UI

## Project Structure

```text
lib/
  main.dart                          — App entry, state (SACAStateScope), theme, routing
  models/
    app_models.dart                  — TriageSession, AppLanguage, ReportMode
  services/
    triage_service.dart              — HTTP client for /triage endpoints
    kokoro_tts_service.dart          — Text-to-speech readback (Kokoro / flutter_tts)
  screens/
    language_and_method_pages.dart   — Language toggle + input method selection
    workspace_and_result_pages.dart  — Workspace questionnaire + result pages
  widgets/
    app_tokens.dart                  — Design tokens (colours, typography)
    cards.dart                       — Shared card widgets
    clinical_input_card.dart         — Voice-input card (STT + live transcript)
    body_part.dart                   — 3-D interactive body model (bilingual labels)
    result_widgets.dart              — Assessment result cards (bilingual)
```

All `lib/` files use `part of '../main.dart'` — they share one Dart library scope.

## Tech Stack

- Flutter (Material 3)
- Dart SDK `^3.11.5`
- `http` for backend requests
- `record` for voice capture
- `path_provider` for temp audio files
- `app_settings` for “open system settings” UX

## Android Readiness

Android support includes:
- `INTERNET` + `RECORD_AUDIO` permissions
- Cleartext HTTP enabled for local-network backend testing
- `network_security_config.xml` configured for local HTTP use
- `minSdk` enforced to at least 23

### Important (Local Backend on Emulator)

If FastAPI runs on your computer:
- Android emulator should use `http://10.0.2.2:8000`
- Real Android tablet should use your LAN IP, e.g. `http://192.168.x.x:8000`
- Do not use `127.0.0.1` on Android unless backend runs on the Android device itself

## Run the App

### 1) Install dependencies

```powershell
flutter pub get
```

### 2) Run on Windows

```powershell
flutter run -d windows
```

### 3) Run on Android emulator/device

```powershell
flutter devices
flutter run -d emulator-5554
```

Or use your physical device ID from `flutter devices`.

### 4) Build APK

```powershell
# Release APK (smaller, obfuscated — use this for device testing)
flutter build apk --release

# Debug APK (larger, debug symbols included)
flutter build apk --debug
```

Release output: `build/app/outputs/flutter-apk/app-release.apk` (~200 MB)
Debug output:   `build/app/outputs/flutter-apk/app-debug.apk`

> **Gradle KGP warning:** Several plugins (`app_settings`, `audioplayers_android`, `flutter_tts`, `record_android`, `webview_flutter_android`) still apply the Kotlin Gradle Plugin directly. This prints warnings but does **not** fail the build. Upgrade those plugins to KGP-clean versions when available.

## FastAPI Integration Contract

`TriageService` calls with endpoint fallback chain:

**Transcribe (audio → text)**
1. `/triage/transcribe`
2. `/v2/transcribe`
3. `/transcribe`

**Assess (text → triage)**
1. `/triage/analyze-voice`
2. `/v2/triage/analyze-voice`

Expected response fields:
- `triage_level`
- `top_condition` or `predicted_disease`
- `transcript_final` / `transcript_final_text` / `transcript`
- `recommendation`

### Warlpiri voice
Pass `language: wbp` in the transcribe request body. The backend routes to Meta MMS (`facebook/mms-1b-all`) with graceful fallback to English STT when the adapter is unavailable.

## Troubleshooting

### Windows build fails with plugin symlink/NuGet errors

```powershell
flutter clean
flutter pub get
flutter run -d windows
```

### Android microphone denied

The app now:
- prompts permission through `record`
- shows retry guidance
- provides “Open app settings” path for blocked permission

### Zero-byte recording

If recording returns `0 bytes`, the app fails fast and shows a user-visible error.

## Quality Status

- `flutter analyze` passing (no errors or warnings)
- Release APK build verified (`app-release.apk`, ~200 MB)
- Bilingual body model, result page, and workspace questionnaire all tested
- Pain slider live-update on STT transcription verified

## Useful Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter run -d emulator-5554
flutter build apk --release

# Port-forward backend to physical Android device
adb reverse tcp:8000 tcp:8000
```

## References

- Project folder: [saca_app_flutter](https://github.com/KimsongKen/Technology-Innovation-Research-and-Project/tree/main/saca_app_flutter)
- Flutter docs: [docs.flutter.dev](https://docs.flutter.dev/)
- Backend README: see `Technology Project/README.md`

