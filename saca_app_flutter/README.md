# SACA Flutter App

Smart Adaptive Clinical Assistant (SACA) is an offline-first Flutter triage prototype designed for use in remote community settings, with bilingual support for English and Warlpiri.

Repository path: [Technology-Innovation-Research-and-Project / saca_app_flutter](https://github.com/KimsongKen/Technology-Innovation-Research-and-Project/tree/main/saca_app_flutter)

## Project Goal

SACA helps health workers capture symptoms quickly through:
- Voice-guided capture with transcript confirmation
- Typed clinical input
- Visual body-area selection

The app then generates a focused, action-oriented triage summary:
- Single triage level
- Most likely top condition
- Recommendation / action plan

## Core Features

- Bilingual UI language selection (English / Warlpiri)
- Multi-step clinical questionnaire flow
- Voice recording with backend transcription integration
- Transcript append-and-edit before confirmation
- Interactive pain-location body grid
- Minimalist clinical result dashboard
- Windows-friendly desktop UX with hover and card interactions

## Current Structure

The app has been cleaned and modularized into:

```text
lib/
  main.dart
  models/
    app_models.dart
  services/
    triage_service.dart
  screens/
    language_and_method_pages.dart
    workspace_and_result_pages.dart
  widgets/
    app_tokens.dart
    cards.dart
    clinical_input_card.dart
    result_widgets.dart
```

## Tech Stack

- Flutter (Material 3)
- Dart SDK: `^3.11.5`
- HTTP client: `http`
- Audio recording: `record`
- Temp file paths: `path_provider`

## Run Locally (Windows)

From project root:

```powershell
flutter pub get
flutter run -d windows
```

## If Windows Symlink Error Appears

If you see an error similar to:
`PathExistsException ... .plugin_symlinks ... errno = 183`

run:

```powershell
if (Test-Path "windows\flutter\ephemeral\.plugin_symlinks") { Remove-Item "windows\flutter\ephemeral\.plugin_symlinks" -Recurse -Force }
flutter clean
flutter pub get
flutter run -d windows
```

This clears stale plugin symlinks and rebuilds cleanly.

## Triage API Integration

`TriageService` currently supports:
- `transcribeAudio(File wavFile)`
- `submitSession(TriageSession session, {File? wavFile})`

### Transcription endpoint fallback order
- `/v2/transcribe`
- `/transcribe`
- `/triage/transcribe`

### Analyze endpoint fallback order
- `/triage/analyze-voice`
- `/v2/triage/analyze-voice`

### Expected response fields

The app reads these keys from backend JSON where available:
- `triage_level`
- `top_condition` (or `predicted_disease`)
- `transcript_final` / `transcript_final_text` / `transcript`
- `recommendation`

## UX Notes

- Organic clinical styling with rounded cards
- Hover scale interaction on desktop
- Progress-aware questionnaire flow
- Result screen designed for immediate action:
  - `ALERT CLINIC`
  - `NEW ASSESSMENT`

## Quality Status

- Codebase cleaned from dead code and unused dependencies
- Refactored into models/services/screens/widgets
- `flutter analyze` passes with no issues

## Development Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## References

- Project repo directory: [saca_app_flutter](https://github.com/KimsongKen/Technology-Innovation-Research-and-Project/tree/main/saca_app_flutter)
- Flutter documentation: [docs.flutter.dev](https://docs.flutter.dev/)
