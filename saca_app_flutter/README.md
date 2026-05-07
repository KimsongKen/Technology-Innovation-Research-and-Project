# SACA Flutter App

Smart Adaptive Clinical Assistant (SACA) is a Flutter triage prototype for remote clinical workflows, with bilingual support for English and Warlpiri.

Repository path: [Technology-Innovation-Research-and-Project / saca_app_flutter](https://github.com/KimsongKen/Technology-Innovation-Research-and-Project/tree/main/saca_app_flutter)

## What This App Does

- Capture patient input through:
  - Voice (microphone recording + transcript review)
  - Text typing
  - Visual body-area selection
- Run triage analysis through a FastAPI backend
- Present a clean, action-oriented result:
  - Triage level
  - Top condition
  - Recommendation

## Current Feature Set

- Global language mode (English/Warlpiri)
- Multi-step clinical questionnaire
- Voice transcript append + editable verification
- Real-time permission UX for microphone access
- Result dashboard with `ALERT CLINIC` and `NEW ASSESSMENT`
- Desktop-friendly hover interactions and modern card UI

## Project Structure

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

### 4) Build APK (debug)

```powershell
flutter build apk --debug
```

Output:
`build/app/outputs/flutter-apk/app-debug.apk`

## FastAPI Integration Contract

`TriageService` currently calls:
- Transcribe endpoints (fallback order):
  - `/v2/transcribe`
  - `/transcribe`
  - `/triage/transcribe`
- Analyze endpoints (fallback order):
  - `/triage/analyze-voice`
  - `/v2/triage/analyze-voice`

Expected response fields:
- `triage_level`
- `top_condition` or `predicted_disease`
- `transcript_final` / `transcript_final_text` / `transcript`
- `recommendation`

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

- Refactored and cleaned codebase
- Android manifest + network config updated for local testing
- `flutter analyze` passing
- Debug APK build verified

## Useful Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter run -d emulator-5554
flutter build apk --debug
```

## References

- Project folder: [saca_app_flutter](https://github.com/KimsongKen/Technology-Innovation-Research-and-Project/tree/main/saca_app_flutter)
- Flutter docs: [docs.flutter.dev](https://docs.flutter.dev/)


 flutter run -d emulator-
 

