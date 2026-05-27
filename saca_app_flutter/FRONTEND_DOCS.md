# SACA App — Frontend Developer Reference

**Smart Adaptive Clinical Assistant**  
Platform: Windows desktop (primary), Android, iOS, Web  
Language: Dart / Flutter (Material 3, `part of` file architecture)

---

## Architecture Overview

All Dart source files live under `lib/` and are wired together through a single `part of '../main.dart'` directive. This means the entire app compiles as one logical unit — no package imports between internal files, just `part` declarations. `main.dart` is the root; every other file is a fragment of it.

```
lib/
├── main.dart                          ← App root + global state
├── models/
│   └── app_models.dart                ← Data models & enums
├── services/
│   ├── asset_server.dart              ← Local HTTP server for GLB files
│   └── triage_service.dart            ← API client (transcribe + predict)
├── screens/
│   ├── language_and_method_pages.dart ← Onboarding flow (steps 1–2)
│   └── workspace_and_result_pages.dart← Clinical flow (steps 3–end)
└── widgets/
    ├── app_tokens.dart                ← Design tokens (colours, typography)
    ├── body_part.dart                 ← Interactive 3D body selector widget
    ├── body_part_bridge.dart          ← Mesh-name → pain-location mapper
    ├── cards.dart                     ← Reusable card shells
    ├── clinical_input_card.dart       ← Voice/audio recording UI card
    ├── result_widgets.dart            ← Result page sub-widgets
    └── windows_model_viewer.dart      ← Windows WebView 3D model viewer
```

---

## File-by-File Reference

---

### `lib/main.dart`
**Role:** App entry point, global state, theme, and route root.

| Symbol | Type | What it does |
|---|---|---|
| `main()` | function | Calls `runApp(const SACAApp())` |
| `SACAAppState` | `ChangeNotifier` | Holds `_selectedLanguage` (English / Warlpiri); notifies listeners on change |
| `SACAAppState.setLanguage()` | method | Switches `_selectedLanguage`, calls `notifyListeners()` |
| `SACAStateScope` | `InheritedNotifier` | Propagates `SACAAppState` down the widget tree without passing it manually |
| `SACAStateScope.of(context)` | static method | Retrieves the nearest `SACAAppState` — used in every screen that needs language |
| `SACAApp` | `StatefulWidget` | Root widget; builds `MaterialApp` with deep-clinical-green theme and `Inter` font |

**Theme:** Material 3, `fontFamily: 'Inter'`, seed colour `SACAColors.deepClinicalGreen` (`#1A5241`).  
**Entry screen:** `LanguageSelectionPage(triageService: _triageService)`.

---

### `lib/models/app_models.dart`
**Role:** All data contracts — enums, session state, and API result shape.

| Symbol | Type | What it does |
|---|---|---|
| `AppLanguage` | enum | `english`, `warlpiri` — drives all bilingual string decisions |
| `ReportMode` | enum | `voice`, `selection`, `text` — controls which workspace flow is shown |
| `TriageSession` | class | Mutable bag of patient data collected across all steps |
| `TriageSession.chiefComplaint` | field | Combined selected symptoms string, joined with `, ` |
| `TriageSession.painLocation` | `List<String>` | Coarse location strings: `'Head'`, `'Chest'`, `'Arm'`, `'Leg'`, etc. |
| `TriageSession.painScore` | `int` | 1–10 slider value |
| `TriageApiResult` | class | Immutable result from the prediction endpoint |
| `TriageApiResult.triageLevel` | field | `'Mild'`, `'Moderate'`, `'High'` / `'Severe'` — drives colour coding |
| `TriageApiResult.escalationTriggered` | `bool` | Shows red escalation banner when true |
| `TriagePresentation` | class | Static helpers to translate triage level into UI colours and text |
| `TriagePresentation.colorForLevel()` | static method | `'High'/'Severe'` → `#8B0000`, `'Moderate'` → `#B8860B`, else → `#1A5241` |
| `TriagePresentation.recommendationForLevel()` | static method | Returns fallback recommendation string when API has none |
| `WorkspaceConfig` | class | Title, subtitle, accent colour for a given `ReportMode` |
| `SACAStrings.tr()` | static method | Returns bilingual string: `'$english / $warlpiri'` in Warlpiri mode, else just `english` |

---

### `lib/services/asset_server.dart`
**Role:** Spins up a local HTTP server so the WebView-based 3D viewer can load `HumanModel.glb` over `http://127.0.0.1:<port>/`.

| Symbol | Type | What it does |
|---|---|---|
| `AssetServer` | class | Singleton-style static class |
| `AssetServer.start()` | static async method | Copies `HumanModel.glb` from Flutter asset bundle to the OS temp directory; binds a `shelf_static` server on a random loopback port; no-ops if already started |
| `AssetServer.port` | static getter | Returns the port number once started |

**Why needed:** WebView cannot load `file://` asset paths on Windows. The server converts the bundled GLB into a localhost URL the WebView can fetch normally.

---

### `lib/services/triage_service.dart`
**Role:** HTTP client that talks to the Python/FastAPI triage backend.

| Symbol | Type | What it does |
|---|---|---|
| `TriageService` | class | Wraps all API calls; resolves base URL from env var or platform defaults |
| `TriageService._baseUrl` | getter | Checks `SACA_API_BASE_URL` env var; falls back to `10.0.2.2` on Android emulator or `127.0.0.1` on desktop |
| `TriageService.transcribeAudio()` | async method | `POST /triage/transcribe` — sends a WAV file as multipart form data with language code (`en` / `wbp`); returns transcript string |
| `TriageService.submitSession()` | async method | `POST /triage/predict` — serialises `TriageSession` to JSON and sends; returns `TriageApiResult`; falls back gracefully if API is unreachable |

**Auth:** `Authorization: Bearer dev-token` header on all requests.  
**Timeout:** 20 seconds on `submitSession`.

---

### `lib/screens/language_and_method_pages.dart`
**Role:** The first two screens a user sees — language selection and report mode selection.

| Symbol | Type | What it does |
|---|---|---|
| `LanguageSelectionPage` | `StatelessWidget` | Displays two language cards (English, Warlpiri); on tap calls `SACAStateScope.of(context).setLanguage()` and pushes `MethodSelectionPage` |
| `MethodSelectionPage` | `StatelessWidget` | Displays three `ReportModeCard` tiles (Voice, Selection, Text); routes to `WorkspacePage` with the chosen `ReportMode` and a unique `heroTag` |

**Hero animation:** Each mode card has a `Hero` widget keyed on `heroTag` that animates into the workspace page icon.

---

### `lib/screens/workspace_and_result_pages.dart`
**Role:** The entire clinical data-collection and results flow. The largest file in the project (~2 500 lines).

#### `WorkspacePage`
Entry point for voice and text modes; also hosts the body-map for selection mode.

| Symbol | Type | What it does |
|---|---|---|
| `WorkspacePage` | `StatefulWidget` | Accepts `ReportMode`, `heroTag`, `triageService` |
| `_WorkspacePageState._currentStep` | `int` | 0–4 step counter for text/voice questionnaire |
| `_buildWorkspaceBody()` | method | Switches on `ReportMode` — renders body selector or questionnaire card |
| `_buildQuestionnaire()` | method | Renders the 5-step card flow for voice/text modes |
| `_buildStepInput()` | method | Switch on `_currentStep`: step 0 = text field, 1 = pain slider + worsening chips, 2 = onset chips, 3 = quick-worsening chips, 4 = text fields for medications/allergies |
| `_goNextOrSubmit()` | method | Advances step or, at step 4, pushes `PreResultNotesPage` |
| `_handleClinicalConfirm()` | method | Called by `ClinicalInputCard` when voice capture is confirmed; stores answer, calls `_goNextOrSubmit()` |
| `_workspaceConfig()` | method | Returns `WorkspaceConfig` (title, accent colour) for the current mode |

#### `_IllnessSelectionPage` (Selection mode only)
Shown after the user taps body parts on the 3D model. 6-step flow.

| Symbol | Type | What it does |
|---|---|---|
| `_IllnessSelectionPage` | `StatefulWidget` | Receives `selectedBodyParts: List<String>` from the body model tap |
| `_selectedSymptoms` | `Set<String>` | Physical symptom chips selected in step 0 |
| `_selectedSystemicSymptoms` | `Set<String>` | Systemic/general symptom chips selected in step 1 |
| `_selectedMedications` | `Set<String>` | Medication chips selected in step 5 |
| `_selectedAllergies` | `Set<String>` | Allergy chips selected in step 5 |
| `_regionGroups` | getter | Maps `selectedBodyParts` strings (`'Chest'`, `'Arm'`) to catalog keys (`'body'`, `'left arm'`, `'right arm'`) and returns labeled section groups |
| `_buildIllnessSelectionGrid()` | method | Step 0 UI — single-region: flat chip wrap; multi-region: grouped sections with green pill headers per body part |
| `_buildSectionHeader()` | method | Green pill header row with label icon and region name |
| `_buildSymptomWrap()` | method | `Wrap` of `AnimatedContainer` chips; accepts optional `selectionSet` so it works for both physical and systemic buckets |
| `_buildSystemicSymptomsStep()` | method | Step 1 UI — 8 named category groups (Flu/Cold, Allergies, Stomach, Heart, Anxiety, Sleep, Neurological, Blood Sugar) each with icon header + chip wrap |
| `_buildSystemicCategoryHeader()` | method | Icon + bold label row for each systemic category |
| `_buildMedAllergyStep()` | method | Step 5 UI — two `_buildChipGroup()` sections for medications and allergies |
| `_buildChipGroup()` | method | Reusable chip group with heading, subtitle, and `AnimatedContainer` chip tiles; "None" chip clears all others |
| `_goNext()` | method | Validates step 0 (must pick ≥1 symptom); step 3 validates onset; at step 5 merges physical + systemic into `chiefComplaint` and navigates to `PreResultNotesPage` |

#### Symptom Catalogues (module-level constants)

| Constant | Type | What it contains |
|---|---|---|
| `_kSymptomCatalog` | `List<_SymptomEntry>` | 44 physical symptoms, each tagged with which body-part catalog keys they apply to (`'head'`, `'body'`, `'left arm'`, `'right arm'`, `'leg'`) |
| `_kSystemicCategories` | `List<_SystemicCategory>` | 8 disease-family groups, 39 systemic symptoms total |
| `_kCommonMedications` | `List<String>` | 13 common medications including "None" |
| `_kCommonAllergies` | `List<String>` | 11 common allergies including "None" |

#### Result / Pre-result Pages

| Page | What it does |
|---|---|
| `PreResultNotesPage` | Final optional free-text notes screen; on submit navigates to `ResultSummaryPage` |
| `ResultSummaryPage` | Calls `TriageService.submitSession()`, shows animated triage header, action plan box, and assessment details tile |

---

### `lib/widgets/app_tokens.dart`
**Role:** Single source of truth for all design constants.

| Symbol | What it is |
|---|---|
| `SACAColors.deepClinicalGreen` | `Color(0xFF1A5241)` — primary brand colour |
| `SACAColors.triageSafeGreen` | `Color(0xFF3E8A63)` — body-part label unselected colour |
| `SACAColors.earthClay` | Warm orange — selection mode accent |
| `SACAColors.warningRedBrown` | Deep red — text mode accent |
| `SACAColors.charcoal` | Near-black text colour |
| `SACAColors.secondaryText` | Muted grey for subtitles |
| `SACAColors.subtleBorder` | Light grey for card/input borders |
| `SACAColors.pageBackground` | Off-white cream background |
| `SACATriageTypography.pageHeadline` | `double` — font size for page H1s |
| `SACATriageTypography.cardQuestion` | `double` — font size for question text in cards |
| `SACATriageTypography.sectionLead` | `double` — font size for section headings |
| `SACATriageTypography.sectionSub` | `double` — font size for section subheadings |

---

### `lib/widgets/body_part.dart`
**Role:** The interactive 3D human body selector shown in selection mode. Switches implementation by platform.

| Symbol | Type | What it does |
|---|---|---|
| `InteractiveBodyWidget` | `StatefulWidget` | Top-level body selector; accepts `session` and `onSelectionChanged` callback |
| `_InteractiveBodyWidgetState._build()` | method | On Windows: renders `WindowsModelViewer` + label overlay. On other platforms: renders `ModelViewer` (model_viewer_plus) with overlaid tappable labels |
| `_buildLabelOverlay()` | method | Positions green/red pill labels on top of the 3D model using `Stack` + `Positioned`; label turns red when that region is selected |
| `_buildSingleLabel()` | method | One pill chip — green with light-green tint when unselected, red fill when selected; tapping calls `togglePartByMeshName()` then `onSelectionChanged()` |
| `_BodyLinePainter` | `CustomPainter` | Draws connecting lines from each label pill to its body region using `_kGreen` when unselected and red when selected |
| `_kLabelPositions` | const map | Fractional `(dx, dy)` positions for each region label within the model viewport |

**Platform split:** `io.Platform.isWindows` check switches between `WindowsModelViewer` and `ModelViewer`.

---

### `lib/widgets/body_part_bridge.dart`
**Role:** Translation layer between the granular `BodyParts` object (from `body_part_selector`) and the coarse region strings used throughout the app.

| Symbol | Type | What it does |
|---|---|---|
| `bodyPartsToPainLocation()` | function | Inspects all boolean fields on a `BodyParts` object; returns a `List<String>` of coarse pain location strings: `'Head'`, `'Chest'`, `'Abdominal'`, `'Hip'`, `'Arm'`, `'Leg'` |
| `painLocationToBodyParts()` | function | Reverse: takes coarse strings, returns a `BodyParts` instance with the correct booleans set to `true` |
| `togglePartByMeshName()` | function | Takes a raw GLB mesh name (e.g. `'Left Arm'`, `'Body'`), matches it case-insensitively, and toggles the corresponding regions on the `BodyParts` object |
| `selectedPartDisplayNames()` | function | Generates human-readable pill labels for whichever regions are currently selected (e.g. `'Head'`, `'Arm'`, `'Leg'`) |

**Critical mapping:** `bodyPartsToPainLocation()` output strings must match the cases handled in `_IllnessSelectionPage._regionGroups` (which maps `'Chest'`/`'Abdominal'`/`'Hip'` → `'body'` catalog key, `'Arm'` → `['left arm', 'right arm']`).

---

### `lib/widgets/cards.dart`
**Role:** Reusable card shells used by questionnaire and result screens.

| Symbol | Type | What it does |
|---|---|---|
| `_BaseCard` | `StatelessWidget` | White rounded card with optional left-side accent border when `active: true`; wraps arbitrary `child` |
| `ReportModeCard` | `StatelessWidget` | The large tappable card on `MethodSelectionPage`; contains a `Hero`-wrapped icon, title, and subtitle; navigates to workspace on tap |

---

### `lib/widgets/clinical_input_card.dart`
**Role:** The voice recording UI used in voice mode steps.

| Symbol | Type | What it does |
|---|---|---|
| `ClinicalInputCard` | `StatefulWidget` | Accepts `questionText`, `triageService`, `accentColor`, `initialTranscript`, `onConfirmed` callback |
| `_ClinicalInputCardState._record` | `AudioRecorder` | From the `record` package; manages microphone access |
| `_startRecording()` | method | Checks mic permission; requests via `app_settings` if denied; starts WAV recording to a temp file |
| `_stopRecording()` | method | Stops recording; calls `TriageService.transcribeAudio()` to get transcript; populates text field |
| `_confirm()` | method | Calls `onConfirmed` with the current transcript text |
| `_permissionDenied` | `bool` state | Shows "Open Settings" prompt if mic permission was permanently denied |

---

### `lib/widgets/result_widgets.dart`
**Role:** All sub-widgets that compose the `ResultSummaryPage`.

| Symbol | Type | What it does |
|---|---|---|
| `_TriageHeader` | `StatelessWidget` | Large coloured badge showing triage level (`HIGH` / `MODERATE` / `MILD`), top condition name, language badge, and confidence percentage chip |
| `_ActionPlanBox` | `StatelessWidget` | Coloured card with the recommendation text and a "what to do" icon row based on severity |
| `_AssessmentDetailsTile` | `StatefulWidget` | Collapsible `ExpansionTile` showing the AI transcript, detected symptom chips, and raw Warlpiri transcript (if available) |
| `_EscalationBanner` | `StatelessWidget` | Full-width red banner shown when `escalationTriggered` is true; flashes attention to urgent cases |
| `_ResultActionBar` | `StatelessWidget` | Bottom bar with two buttons: "NEW ASSESSMENT" (pops to root) and "ALERT CLINIC" (triggers clinic alert workflow) |
| `_PainIntensityBlock` | `StatelessWidget` | Heat-coloured slider (green → amber → red) with 1–10 labels; shared by workspace and result pages |

---

### `lib/widgets/windows_model_viewer.dart`
**Role:** Windows-only 3D model viewer backed by `webview_windows`.

| Symbol | Type | What it does |
|---|---|---|
| `WindowsModelViewer` | `StatefulWidget` | Accepts `isFrontView`, `selectedMeshNames`, `onMeshTapped` |
| `_WindowsModelViewerState._init()` | async method | Starts `AssetServer`; creates and initialises `WebviewController`; loads inline HTML via `loadStringContent()` |
| `_syncSelection()` | method | Calls `executeScript("syncSelection('$json')")` to push the current selected-region list into the WebView's JavaScript |
| `didUpdateWidget()` | override | Detects changes to `isFrontView` (rotates camera via JS) or `selectedMeshNames` (calls `_syncSelection`) |
| `_buildHtml()` | static method | Generates the complete HTML/JS page inline: loads `model-viewer` 3.3.0 from CDN, defines `matByName()` (material lookup), `storeOriginals()` (captures base colours), `syncSelection()` (applies red / restore), and click handler that calls `window.chrome.webview.postMessage(meshName)` |

**Mesh highlight mechanism:** On selection, `syncSelection()` calls `mat.pbrMetallicRoughness.setBaseColorFactor([1, 0.15, 0.15, 1])` (red). On deselect it restores from `origColors` captured at model load time.

---

## Data Flow — Selection Mode (end to end)

```
User taps body on 3D model
        │
        ▼
WindowsModelViewer JS (click handler)
  → surfaceFromPoint() → mesh name
  → chrome.webview.postMessage("head")
        │
        ▼
_WindowsModelViewerState.webMessage.listen()
  → widget.onMeshTapped("head")
        │
        ▼
InteractiveBodyWidget._onMeshTapped()
  → togglePartByMeshName("head", bodyParts)
  → session.painLocation updated via bodyPartsToPainLocation()
  → onSelectionChanged() → setState()
        │
        ▼
_syncSelection(["head"]) → JS applies red material
Label pill turns red
        │
        ▼
User taps "Choose illness symptoms"
        │
        ▼
_IllnessSelectionPage(selectedBodyParts: ["Head"])
  Step 0: _regionGroups → [{ label:'Head', keys:['head'] }]
          _buildIllnessSelectionGrid() → flat chip wrap (single region)
  Step 1: _buildSystemicSymptomsStep() → 8 category groups
  Step 2: Pain slider + better/worse chips
  Step 3: Onset duration chips
  Step 4: Quick-worsening chips
  Step 5: Medication + Allergy chip groups
        │
        ▼
_goNext() at step 5:
  chiefComplaint = _selectedSymptoms ∪ _selectedSystemicSymptoms (joined)
  onset, isWorsening, medications, allergies → session fields
        │
        ▼
PreResultNotesPage → additionalConcerns text
        │
        ▼
ResultSummaryPage → TriageService.submitSession()
        │
        ▼
TriageApiResult displayed:
  _TriageHeader (level + condition)
  _ActionPlanBox (recommendation)
  _AssessmentDetailsTile (symptoms + transcript)
```

---

## Assets

| File | Used by | Purpose |
|---|---|---|
| `assets/models/HumanModel.glb` | `AssetServer`, `WindowsModelViewer`, `ModelViewer` | Blender-segmented 3D human body with 5 named material slots: `head`, `body`, `left arm`, `right arm`, `leg` |

---

## Key Dependencies

| Package | Version | Used for |
|---|---|---|
| `http` | ^1.2.2 | API calls in `TriageService` |
| `record` | ^6.2.0 | Microphone recording in `ClinicalInputCard` |
| `path_provider` | ^2.1.5 | Temp directory for audio + GLB file copy |
| `app_settings` | ^6.1.1 | Opens OS settings when mic permission denied |
| `body_part_selector` | git (talharasool) | `BodyParts` data class used in bridge mapping |
| `model_viewer_plus` | ^1.8.0 | 3D GLB viewer for non-Windows platforms |
| `webview_flutter` | ^4.0.0 | WebView for non-Windows model viewer |
| `webview_windows` | ^0.2.2 | WebView2 for Windows model viewer |
| `shelf` + `shelf_static` | ^1.4.1 / ^1.1.2 | Local HTTP server in `AssetServer` |

---

## Test Coverage

| File | What it tests |
|---|---|
| `test/widget_test.dart` | Smoke test — app loads, language screen renders with correct icon |
| `test/result_summary_page_test.dart` | `TriagePresentation.colorForLevel()`, `recommendationForLevel()`, `ResultSummaryPage` widget rendering (triage level display, confidence badge visibility, escalation banner, symptom chips, action buttons) |
