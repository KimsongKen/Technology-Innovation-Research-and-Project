import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

void main() {
  runApp(const SACAApp());
}

enum AppLanguage { warlpiri, english }

enum ReportMode { voice, selection, text }

class TriageSession {
  TriageSession({
    required this.chiefComplaint,
    required this.onset,
    required this.isWorsening,
    required this.medications,
    required this.allergies,
    required this.painLocation,
  });

  String chiefComplaint;
  String onset;
  bool isWorsening;
  String medications;
  String allergies;
  List<String> painLocation;
}

class TriageApiResult {
  TriageApiResult({
    required this.triageLevel,
    required this.topCondition,
    required this.transcriptFinal,
    required this.recommendation,
  });

  factory TriageApiResult.fromJson(Map<String, dynamic> json) {
    return TriageApiResult(
      triageLevel: (json['triage_level'] ?? 'Moderate').toString(),
      topCondition: (json['top_condition'] ?? json['predicted_disease'] ?? '-')
          .toString(),
      transcriptFinal: (json['transcript_final'] ?? json['transcript_final_text'] ?? json['transcript'] ?? '').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
    );
  }

  final String triageLevel;
  final String topCondition;
  final String transcriptFinal;
  final String recommendation;
}

class SACAAppState extends ChangeNotifier {
  AppLanguage _selectedLanguage = AppLanguage.english;

  AppLanguage get selectedLanguage => _selectedLanguage;

  void setLanguage(AppLanguage language) {
    if (_selectedLanguage == language) return;
    _selectedLanguage = language;
    notifyListeners();
  }
}

class SACAStateScope extends InheritedNotifier<SACAAppState> {
  const SACAStateScope({
    super.key,
    required SACAAppState state,
    required Widget child,
  }) : super(notifier: state, child: child);

  static SACAAppState of(BuildContext context) {
    final SACAStateScope? scope = context
        .dependOnInheritedWidgetOfExactType<SACAStateScope>();
    assert(scope != null, 'SACAStateScope not found in context');
    return scope!.notifier!;
  }
}

class SACAApp extends StatefulWidget {
  const SACAApp({super.key});

  @override
  State<SACAApp> createState() => _SACAAppState();
}

class _SACAAppState extends State<SACAApp> {
  final SACAAppState _state = SACAAppState();
  final TriageService _triageService = TriageService();

  @override
  Widget build(BuildContext context) {
    return SACAStateScope(
      state: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SACA - Smart Adaptive Clinical Assistant',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: SACAColors.pageBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: SACAColors.deepClinicalGreen,
            brightness: Brightness.light,
          ),
        ),
        home: LanguageSelectionPage(triageService: _triageService),
      ),
    );
  }
}

class SACAColors {
  static const Color warlpiriOrange = Color(0xFFD17E2F);
  static const Color deepClinicalGreen = Color(0xFF1A5241);
  static const Color warningRedBrown = Color(0xFF9B4433);
  static const Color earthClay = Color(0xFFB15D2C);
  static const Color pageBackground = Color(0xFFFAF8F5);
  static const Color cardBackground = Colors.white;
  static const Color charcoal = Color(0xFF1F1F1F);
  static const Color secondaryText = Color(0xFF5E5A56);
  static const Color subtleBorder = Color(0xFFE8E2D8);
  static const Color triageCrimson = Color(0xFFB24A4A);
  static const Color triageMarigold = Color(0xFFC6922B);
  static const Color triageSafeGreen = Color(0xFF3E8A63);
}

class SACAStrings {
  static String tr({
    required BuildContext context,
    required String english,
    required String warlpiri,
  }) {
    final AppLanguage language = SACAStateScope.of(context).selectedLanguage;
    return language == AppLanguage.english ? english : warlpiri;
  }
}

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key, required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Smart Adaptive Clinical Assistant',
                    style: const TextStyle(
                      color: SACAColors.charcoal,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose language / Pina yimi',
                    style: const TextStyle(
                      color: SACAColors.secondaryText,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: LanguageCard(
                            accentColor: SACAColors.warlpiriOrange,
                            title: 'Warlpiri',
                            subtitle: 'Wayi!  Yuendumu',
                            icon: Icons.record_voice_over_rounded,
                            onTap: () {
                              SACAStateScope.of(
                                context,
                              ).setLanguage(AppLanguage.warlpiri);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReportingMethodPage(
                                    triageService: triageService,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: LanguageCard(
                            accentColor: SACAColors.deepClinicalGreen,
                            title: 'English',
                            subtitle: 'Hello!  Clinical mode',
                            icon: Icons.language_rounded,
                            onTap: () {
                              SACAStateScope.of(
                                context,
                              ).setLanguage(AppLanguage.english);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReportingMethodPage(
                                    triageService: triageService,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportingMethodPage extends StatelessWidget {
  const ReportingMethodPage({super.key, required this.triageService});

  final TriageService triageService;

  @override
  Widget build(BuildContext context) {
    final List<ReportModeCardData> methods = <ReportModeCardData>[
      ReportModeCardData(
        mode: ReportMode.voice,
        heroTag: 'mode-voice',
        icon: Icons.mic_rounded,
        accentColor: SACAColors.deepClinicalGreen,
        title: SACAStrings.tr(
          context: context,
          english: 'Voice / Spoken',
          warlpiri: 'Yarn / Speak',
        ),
        description: SACAStrings.tr(
          context: context,
          english: 'Record speech for rapid triage notes',
          warlpiri: 'Wangka-ku record marda triage notes',
        ),
        recommended: true,
      ),
      ReportModeCardData(
        mode: ReportMode.selection,
        heroTag: 'mode-selection',
        icon: Icons.touch_app_rounded,
        accentColor: SACAColors.earthClay,
        title: SACAStrings.tr(
          context: context,
          english: 'Point to Pictures',
          warlpiri: 'Point-kurra Picture-kurra',
        ),
        description: SACAStrings.tr(
          context: context,
          english: 'Use visual picklists and body-map prompts',
          warlpiri: 'Picture picklist and body-map prompt',
        ),
      ),
      ReportModeCardData(
        mode: ReportMode.text,
        heroTag: 'mode-text',
        icon: Icons.edit_note_rounded,
        accentColor: SACAColors.warningRedBrown,
        title: SACAStrings.tr(
          context: context,
          english: 'Type Symptom',
          warlpiri: 'Type symptom',
        ),
        description: SACAStrings.tr(
          context: context,
          english: 'Enter structured clinical notes by keyboard',
          warlpiri: 'Keyboard-kurra clinical notes type',
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(
                      SACAStrings.tr(
                        context: context,
                        english: 'Back',
                        warlpiri: 'Rete',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    SACAStrings.tr(
                      context: context,
                      english: 'Choose How to Report',
                      warlpiri: 'Nyampu report nyarrpa',
                    ),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    SACAStrings.tr(
                      context: context,
                      english: 'Pick one clinical input method',
                      warlpiri: 'Clinical input nyampu pina',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: SACAColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final int columns = constraints.maxWidth >= 980
                                ? 3
                                : 1;
                            return GridView.builder(
                              itemCount: methods.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    childAspectRatio: columns == 3 ? 1.03 : 1.7,
                                  ),
                              itemBuilder: (BuildContext context, int index) {
                                final ReportModeCardData data = methods[index];
                                return ReportModeCard(
                                  data: data,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => WorkspacePage(
                                          mode: data.mode,
                                          heroTag: data.heroTag,
                                          triageService: triageService,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.mode,
    required this.heroTag,
    required this.triageService,
  });

  final ReportMode mode;
  final String heroTag;
  final TriageService triageService;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  final TextEditingController _chiefComplaintController =
      TextEditingController();
  final TextEditingController _onsetController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  late final TriageSession _session;
  int _currentStep = 0;
  bool _isWorsening = false;
  final Map<int, String> _capturedAnswers = <int, String>{};
  static const List<String> _bodyParts = <String>[
    'Head',
    'Chest',
    'Stomach',
    'Back',
    'Arms',
    'Legs',
  ];

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _onsetController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _session = TriageSession(
      chiefComplaint: '',
      onset: '',
      isWorsening: false,
      medications: '',
      allergies: '',
      painLocation: <String>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceConfig config = _workspaceConfig(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(config.title),
        backgroundColor: SACAColors.pageBackground,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    config.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.subtitle,
                    style: const TextStyle(
                      color: SACAColors.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (widget.mode != ReportMode.selection)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: (_currentStep + 1) / 5,
                          backgroundColor: SACAColors.subtleBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            config.accentColor,
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: _buildWorkspaceBody(config)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceBody(WorkspaceConfig config) {
    switch (widget.mode) {
      case ReportMode.voice:
        return _buildQuestionnaire(config: config);
      case ReportMode.text:
        return _buildQuestionnaire(config: config);
      case ReportMode.selection:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Hero(
              tag: widget.heroTag,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: config.accentColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  color: config.accentColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _bilingualPrompt(
                english: 'Point to where it hurts',
                warlpiri: 'Nyarrpara-kapurlu pinyi?',
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: SACAColors.charcoal,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _bodyParts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final String bodyPart = _bodyParts[index];
                  final bool selected = _session.painLocation.contains(
                    bodyPart,
                  );
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _session.painLocation.remove(bodyPart);
                          } else {
                            _session.painLocation.add(bodyPart);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? SACAColors.warlpiriOrange.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: selected
                                ? SACAColors.warlpiriOrange
                                : SACAColors.subtleBorder,
                            width: selected ? 2.3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            bodyPart,
                            style: const TextStyle(
                              color: SACAColors.charcoal,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: config.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ResultSummaryPage(
                        session: _session,
                        triageService: widget.triageService,
                      ),
                    ),
                  );
                },
                child: Text(
                  SACAStrings.tr(
                    context: context,
                    english: 'Calculate Triage',
                    warlpiri: 'Calculate Triage',
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildQuestionnaire({required WorkspaceConfig config}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Hero(
          tag: widget.heroTag,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: config.accentColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: config.accentColor,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _BaseCard(
            active: false,
            accentColor: config.accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (widget.mode != ReportMode.voice) ...<Widget>[
                  Text(
                    _stepQuestion(_currentStep),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 23,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Expanded(
                  child: widget.mode == ReportMode.voice
                      ? ClinicalInputCard(
                          questionText: _stepQuestion(_currentStep),
                          triageService: widget.triageService,
                          accentColor: config.accentColor,
                          initialTranscript: _capturedAnswers[_currentStep] ?? '',
                          onConfirmed: _handleClinicalConfirm,
                        )
                      : _buildStepInput(config),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _currentStep == 0
                          ? null
                          : () {
                              setState(() => _currentStep -= 1);
                            },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(
                        SACAStrings.tr(
                          context: context,
                          english: 'Back',
                          warlpiri: 'Rete',
                        ),
                      ),
                    ),
                    if (widget.mode != ReportMode.voice)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: config.accentColor,
                        ),
                        onPressed: () => _goNextOrSubmit(),
                        child: Text(
                          _currentStep == 4
                              ? SACAStrings.tr(
                                  context: context,
                                  english: 'Calculate Triage',
                                  warlpiri: 'Calculate Triage',
                                )
                              : SACAStrings.tr(
                                  context: context,
                                  english: 'Next',
                                  warlpiri: 'Next',
                                ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepInput(WorkspaceConfig config) {
    switch (_currentStep) {
      case 0:
        return _inputField(
          controller: _chiefComplaintController,
          hintText: _bilingualPrompt(
            english: 'Describe your symptoms',
            warlpiri: 'Nyuntu symptoms describe',
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ChoiceChip(
                  label: Text(
                    _bilingualPrompt(
                      english: 'Getting Better',
                      warlpiri: 'Ngurrju-jarri',
                    ),
                  ),
                  selected: !_isWorsening,
                  onSelected: (_) => setState(() => _isWorsening = false),
                ),
                ChoiceChip(
                  label: Text(
                    _bilingualPrompt(
                      english: 'Getting Worse',
                      warlpiri: 'Panu',
                    ),
                  ),
                  selected: _isWorsening,
                  onSelected: (_) => setState(() => _isWorsening = true),
                ),
              ],
            ),
          ],
        );
      case 2:
        return _inputField(
          controller: _onsetController,
          hintText: _bilingualPrompt(
            english: 'Example: started 2 days ago',
            warlpiri: 'Example: 2 days before start',
          ),
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _bilingualPrompt(
                english: 'Getting worse quickly',
                warlpiri: 'Kapingkilypa panu nyinami',
              ),
              style: const TextStyle(
                color: SACAColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ChoiceChip(
                  label: Text(_bilingualPrompt(english: 'No', warlpiri: 'No')),
                  selected: !_isWorsening,
                  onSelected: (_) => setState(() => _isWorsening = false),
                ),
                ChoiceChip(
                  label: Text(
                    _bilingualPrompt(english: 'Yes', warlpiri: 'Yea'),
                  ),
                  selected: _isWorsening,
                  onSelected: (_) => setState(() => _isWorsening = true),
                ),
              ],
            ),
          ],
        );
      case 4:
        return Column(
          children: <Widget>[
            _inputField(
              controller: _medicationsController,
              hintText: _bilingualPrompt(
                english: 'Medications',
                warlpiri: 'Pawuju (medications)',
              ),
            ),
            const SizedBox(height: 10),
            _inputField(
              controller: _allergiesController,
              hintText: _bilingualPrompt(
                english: 'Allergies',
                warlpiri: 'Yarnunjuku (allergies)',
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: SACAColors.subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: SACAColors.subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: SACAColors.deepClinicalGreen),
        ),
      ),
    );
  }

  String _stepQuestion(int step) {
    switch (step) {
      case 0:
        return _bilingualPrompt(
          english: 'What are your symptoms?',
          warlpiri: 'Ngurrju-kari-ngirli nyuntu warlu wirridi?',
        );
      case 1:
        return _bilingualPrompt(
          english: 'Are the symptoms getting better or worse?',
          warlpiri:
              'Ngula-kari yimi-ngarrka nyinami warlalja-warnu, panu-kari yinyami?',
        );
      case 2:
        return _bilingualPrompt(
          english: 'When did this start?',
          warlpiri: 'Yaa pitjiri ka nyinanyi?',
        );
      case 3:
        return _bilingualPrompt(
          english: 'Is it getting worse quickly?',
          warlpiri: 'Yalumpu kuja kapingkilypa nyinami?',
        );
      case 4:
        return _bilingualPrompt(
          english: 'List your medications and allergies.',
          warlpiri: 'Yimi ngarrka-jarri karlipa pawuju manu yarnunjuku?',
        );
      default:
        return '';
    }
  }

  String _bilingualPrompt({required String english, required String warlpiri}) {
    final AppLanguage language = SACAStateScope.of(context).selectedLanguage;
    if (language == AppLanguage.warlpiri) {
      return '$english / $warlpiri';
    }
    return english;
  }

  WorkspaceConfig _workspaceConfig(BuildContext context) {
    switch (widget.mode) {
      case ReportMode.voice:
        return WorkspaceConfig(
          title: SACAStrings.tr(
            context: context,
            english: 'Voice / Spoken',
            warlpiri: 'Yarn / Speak',
          ),
          subtitle: SACAStrings.tr(
            context: context,
            english: 'Core Triage Flow - spoken guidance',
            warlpiri: 'Core Triage Flow - spoken guidance',
          ),
          accentColor: SACAColors.deepClinicalGreen,
        );
      case ReportMode.selection:
        return WorkspaceConfig(
          title: SACAStrings.tr(
            context: context,
            english: 'Point to Pictures',
            warlpiri: 'Point-kurra Picture-kurra',
          ),
          subtitle: SACAStrings.tr(
            context: context,
            english: 'Interactive body map grid',
            warlpiri: 'Interactive body map grid',
          ),
          accentColor: SACAColors.earthClay,
        );
      case ReportMode.text:
        return WorkspaceConfig(
          title: SACAStrings.tr(
            context: context,
            english: 'Text / Write',
            warlpiri: 'Text / Write',
          ),
          subtitle: SACAStrings.tr(
            context: context,
            english: 'Core Triage Flow - typed responses',
            warlpiri: 'Core Triage Flow - typed responses',
          ),
          accentColor: SACAColors.warningRedBrown,
        );
    }
  }

  void _goNextOrSubmit() {
    if (widget.mode == ReportMode.voice) {
      _session.chiefComplaint = (_capturedAnswers[0] ?? '').trim();
      _session.onset = (_capturedAnswers[2] ?? '').trim();
      final String medsAllergies = (_capturedAnswers[4] ?? '').trim();
      _session.medications = medsAllergies;
      _session.allergies = medsAllergies;
    } else {
      _session.chiefComplaint = _chiefComplaintController.text.trim();
      _session.onset = _onsetController.text.trim();
      _session.medications = _medicationsController.text.trim();
      _session.allergies = _allergiesController.text.trim();
    }
    _session.isWorsening = _isWorsening;
    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultSummaryPage(
          session: _session,
          triageService: widget.triageService,
        ),
      ),
    );
  }

  void _handleClinicalConfirm(String value) {
    final String cleaned = value.trim();
    _capturedAnswers[_currentStep] = cleaned;

    if (_currentStep == 1) {
      _isWorsening = _parseWorsening(cleaned);
    } else if (_currentStep == 3) {
      _isWorsening = _parseWorsening(cleaned);
    }

    _goNextOrSubmit();
  }

  bool _parseWorsening(String text) {
    final String s = text.toLowerCase();
    if (s.contains('no') || s.contains('better') || s.contains('improve')) {
      return false;
    }
    if (s.contains('yes') || s.contains('worse') || s.contains('panu')) {
      return true;
    }
    return _isWorsening;
  }

}

enum _VoiceCaptureState { idle, recording, processing }

class ClinicalInputCard extends StatefulWidget {
  const ClinicalInputCard({
    super.key,
    required this.questionText,
    required this.triageService,
    required this.accentColor,
    required this.initialTranscript,
    required this.onConfirmed,
  });

  final String questionText;
  final TriageService triageService;
  final Color accentColor;
  final String initialTranscript;
  final ValueChanged<String> onConfirmed;

  @override
  State<ClinicalInputCard> createState() => _ClinicalInputCardState();
}

class _ClinicalInputCardState extends State<ClinicalInputCard>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  late final TextEditingController _transcriptController;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _permissionError = false;

  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _transcriptController =
        TextEditingController(text: widget.initialTranscript);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant ClinicalInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTranscript != oldWidget.initialTranscript &&
        !_isRecording &&
        !_isProcessing) {
      _transcriptController.text = widget.initialTranscript;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }

    final bool hasPermission = await _recorder.hasPermission(request: true);
    debugPrint('[VOICE] Microphone permission granted: $hasPermission');
    if (!hasPermission) {
      setState(() => _permissionError = true);
      return;
    }
    setState(() => _permissionError = false);

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
        '${tempDir.path}/saca_${DateTime.now().millisecondsSinceEpoch}.wav';
    _audioPath = filePath;
    debugPrint('[VOICE] Recording path: $_audioPath');

    await _recorder.start(
      RecordConfig(encoder: AudioEncoder.wav),
      path: _audioPath!,
    );

    setState(() => _isRecording = true);
    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopAndTranscribe() async {
    if (!_isRecording) return;

    setState(() => _isProcessing = true);
    _pulseController.stop();
    _pulseController.reset();
    await _recorder.stop();

    final String? path = _audioPath;
    if (path == null || path.trim().isEmpty) {
      debugPrint('[VOICE] Recording stopped but no output path was returned.');
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      return;
    }

    final File recordedFile = File(path);
    if (!await recordedFile.exists()) {
      debugPrint('[VOICE] Recorded file does not exist at path: $path');
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      return;
    }

    final int fileSize = await recordedFile.length();
    debugPrint('[VOICE] Recorded file ready path=$path size_bytes=$fileSize');
    if (fileSize <= 0) {
      debugPrint('[VOICE] Recorded file is empty (0 bytes).');
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      return;
    }

    String transcript = '';
    try {
      transcript = await widget.triageService.transcribeAudio(recordedFile);
      debugPrint('[VOICE] Transcription received: "${transcript.trim()}"');
    } catch (e) {
      debugPrint('[VOICE] Transcription error: $e');
      transcript = '';
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      final String existing = _transcriptController.text.trim();
      if (existing.isEmpty) {
        _transcriptController.text = transcript;
      } else if (transcript.isNotEmpty) {
        _transcriptController.text = '$existing ${transcript.trim()}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canConfirm =
        !_isProcessing && _transcriptController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          SACAStrings.tr(
            context: context,
            english: 'Tap to Speak',
            warlpiri: 'Nyangkura-pinyi',
          ),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: widget.accentColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.questionText,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.2,
            color: SACAColors.charcoal,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ScaleTransition(
            scale: _isRecording ? _pulseScale : const AlwaysStoppedAnimation(1),
            child: GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SACAColors.deepClinicalGreen,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(_isRecording ? 0.22 : 0.12),
                      blurRadius: _isRecording ? 26 : 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _isProcessing
                ? SACAStrings.tr(
                    context: context,
                    english: 'Analyzing speech...',
                    warlpiri: 'Yuwa kuja nyinami (analyzing)...',
                  )
                : _isRecording
                    ? SACAStrings.tr(
                        context: context,
                        english: 'Recording... Tap to stop.',
                        warlpiri: 'Recording... Tap-kurra stop.',
                      )
                    : (_permissionError
                        ? 'Microphone permission denied.'
                        : ''),
            style: TextStyle(
              color: SACAColors.secondaryText,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (_isProcessing) ...<Widget>[
          const SizedBox(height: 10),
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _transcriptController,
          minLines: 4,
          maxLines: 6,
          enabled: !_isProcessing,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: SACAStrings.tr(
              context: context,
              english: 'Transcript will appear here...',
              warlpiri: 'Transcript nyampu kuja...',
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: SACAColors.subtleBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  BorderSide(color: widget.accentColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_transcriptController.text.trim().isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: canConfirm
                  ? () => widget.onConfirmed(_transcriptController.text.trim())
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: widget.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                SACAStrings.tr(
                  context: context,
                  english: 'Confirm & Continue',
                  warlpiri: 'Confirm & Continue',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class VoiceAudioCaptureScreen extends StatefulWidget {
  const VoiceAudioCaptureScreen({
    super.key,
    required this.triageService,
    required this.accentColor,
  });

  final TriageService triageService;
  final Color accentColor;

  @override
  State<VoiceAudioCaptureScreen> createState() =>
      _VoiceAudioCaptureScreenState();
}

class _VoiceAudioCaptureScreenState extends State<VoiceAudioCaptureScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  _VoiceCaptureState _state = _VoiceCaptureState.idle;
  String _transcriptPreview = '';
  String _statusText = 'Tap the microphone to record your symptoms.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.16,
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final bool hasPermission = await _recorder.hasPermission(
      request: true,
    );
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied.')),
      );
      return;
    }

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
        '${tempDir.path}/saca_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      RecordConfig(encoder: AudioEncoder.wav),
      path: filePath,
    );
    setState(() {
      _state = _VoiceCaptureState.recording;
      _statusText = 'Recording... tap again to stop and analyze.';
      _transcriptPreview = '';
    });
    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopAndProcess() async {
    if (_state != _VoiceCaptureState.recording) return;
    setState(() {
      _state = _VoiceCaptureState.processing;
      _statusText = 'Transcribing and analyzing...';
    });
    _pulseController.stop();
    _pulseController.reset();

    final String? path = await _recorder.stop();
    if (!mounted) return;
    if (path == null || path.trim().isEmpty) {
      setState(() {
        _state = _VoiceCaptureState.idle;
        _statusText = 'No audio captured. Try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio captured. Try again.')),
      );
      return;
    }

    final TriageSession dummySession = TriageSession(
      chiefComplaint: '',
      onset: '',
      isWorsening: false,
      medications: '',
      allergies: '',
      painLocation: <String>[],
    );

    try {
      final TriageApiResult apiResult = await widget.triageService
          .submitSession(dummySession, wavFile: File(path));

      if (!mounted) return;

      dummySession.chiefComplaint = apiResult.transcriptFinal;
      setState(() {
        _transcriptPreview = apiResult.transcriptFinal.trim();
        _statusText = 'Transcript ready. Opening analysis...';
      });

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultSummaryPage(
            session: dummySession,
            triageService: widget.triageService,
            apiResult: apiResult,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _VoiceCaptureState.idle;
        _statusText = 'Speech analysis failed. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech analysis failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool recording = _state == _VoiceCaptureState.recording;
    final bool processing = _state == _VoiceCaptureState.processing;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _BaseCard(
          active: recording,
          accentColor: widget.accentColor,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  SACAStrings.tr(
                    context: context,
                    english: 'Tap to Speak',
                    warlpiri: 'Nyangkura-pinyi',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (processing) ...<Widget>[
                  const SizedBox(height: 10),
                  const SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    SACAStrings.tr(
                      context: context,
                      english: 'Analyzing speech...',
                      warlpiri: 'Yuwa kuja nyinami (Analyzing)...',
                    ),
                    style: TextStyle(
                      color: SACAColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  GestureDetector(
                    onTap: () async {
                      if (_state == _VoiceCaptureState.idle) {
                        await _startRecording();
                      } else if (_state ==
                          _VoiceCaptureState.recording) {
                        await _stopAndProcess();
                      }
                    },
                    child: ScaleTransition(
                      scale: recording ? _pulseScale : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SACAColors.deepClinicalGreen,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(recording ? 0.22 : 0.12),
                              blurRadius: recording ? 24 : 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                if (recording)
                  Text(
                    SACAStrings.tr(
                      context: context,
                      english: 'Recording... Tap to stop.',
                      warlpiri: 'Recording... Tap-kurra stop.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SACAColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SACAColors.subtleBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Transcript',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: SACAColors.secondaryText,
                          letterSpacing: 0.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _transcriptPreview.trim().isNotEmpty
                            ? _transcriptPreview
                            : (processing
                                  ? 'Waiting for final transcript...'
                                  : 'Your final speech transcript will appear here.'),
                        style: const TextStyle(
                          color: SACAColors.charcoal,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SACAColors.secondaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkspaceConfig {
  const WorkspaceConfig({
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
}

class ResultSummaryPage extends StatefulWidget {
  const ResultSummaryPage({
    super.key,
    required this.session,
    required this.triageService,
    this.apiResult,
  });

  final TriageSession session;
  final TriageService triageService;
  final TriageApiResult? apiResult;

  @override
  State<ResultSummaryPage> createState() => _ResultSummaryPageState();
}

class _ResultSummaryPageState extends State<ResultSummaryPage> {
  late final Future<TriageApiResult> _future;
  Color _actionColor = const Color(0xFF1A5241);

  @override
  void initState() {
    super.initState();
    _future = widget.apiResult != null
        ? Future<TriageApiResult>.value(widget.apiResult!)
        : widget.triageService.submitSession(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    final String painLocationText = widget.session.painLocation.isEmpty
        ? 'None selected'
        : widget.session.painLocation.join(', ');

    return Scaffold(
      backgroundColor: SACAColors.pageBackground,
      appBar: AppBar(
        backgroundColor: SACAColors.pageBackground,
        elevation: 0,
        title: Text(
          SACAStrings.tr(
            context: context,
            english: 'Clinical Dashboard',
            warlpiri: 'Clinical Dashboard',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      bottomNavigationBar: _ResultActionBar(
        triageColor: _actionColor,
        onAlertClinic: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clinic alert workflow connected.')),
          );
        },
        onReturnHome: () {
          Navigator.of(
            context,
          ).popUntil((Route<dynamic> route) => route.isFirst);
        },
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<TriageApiResult>(
                future: _future,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<TriageApiResult> snapshot,
                    ) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to fetch triage result: ${snapshot.error}',
                          ),
                        );
                      }
                      final TriageApiResult result = snapshot.data!;
                      final Color resolvedColor = _triageColor(
                        result.triageLevel,
                      );
                      if (_actionColor != resolvedColor) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _actionColor = resolvedColor);
                        });
                      }
                      return ListView(
                        children: <Widget>[
                          _TriageHeader(
                            triageLevel: result.triageLevel,
                            topCondition: result.topCondition,
                          ),
                          const SizedBox(height: 18),
                          _PatientTranscriptBox(
                            transcript: result.transcriptFinal,
                          ),
                          const SizedBox(height: 14),
                          _ActionPlanBox(
                            triageLevel: result.triageLevel,
                            recommendation: result.recommendation,
                          ),
                          const SizedBox(height: 16),
                          _SymptomWrap(
                            symptoms: <String>[
                              if (widget.session.chiefComplaint.isNotEmpty)
                                widget.session.chiefComplaint,
                              if (widget.session.onset.isNotEmpty)
                                'Onset: ${widget.session.onset}',
                              if (widget.session.medications.isNotEmpty)
                                'Meds: ${widget.session.medications}',
                              if (widget.session.allergies.isNotEmpty)
                                'Allergies: ${widget.session.allergies}',
                              if (painLocationText.isNotEmpty)
                                'Pain: $painLocationText',
                            ],
                          ),
                        ],
                      );
                    },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TriageHeader extends StatefulWidget {
  const _TriageHeader({required this.triageLevel, required this.topCondition});

  final String triageLevel;
  final String topCondition;

  @override
  State<_TriageHeader> createState() => _TriageHeaderState();
}

class _TriageHeaderState extends State<_TriageHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color triageColor = _triageColor(widget.triageLevel);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: RadialGradient(
          center: const Alignment(-0.7, -0.8),
          radius: 1.3,
          colors: <Color>[triageColor.withOpacity(0.28), Colors.white],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: triageColor.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ScaleTransition(
            scale: _pulseScale,
            child: Icon(Icons.favorite, color: triageColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.triageLevel.toUpperCase(),
                  style: TextStyle(
                    color: triageColor,
                    fontSize: 34,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.topCondition,
                  style: const TextStyle(
                    color: SACAColors.charcoal,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTranscriptBox extends StatelessWidget {
  const _PatientTranscriptBox({required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    final String value = transcript.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SACAColors.subtleBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Patient Transcript:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SACAColors.secondaryText,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: SACAColors.charcoal,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPlanBox extends StatelessWidget {
  const _ActionPlanBox({
    required this.triageLevel,
    required this.recommendation,
  });

  final String triageLevel;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final Color tone = _triageColor(triageLevel);
    final String resolvedRecommendation = recommendation.trim().isNotEmpty
        ? recommendation
        : _defaultRecommendationForLevel(triageLevel);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.09),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tone.withOpacity(0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tone.withOpacity(0.11),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Action Plan',
            style: TextStyle(
              color: tone,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resolvedRecommendation,
            style: const TextStyle(
              color: SACAColors.charcoal,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomWrap extends StatelessWidget {
  const _SymptomWrap({required this.symptoms});

  final List<String> symptoms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SACAColors.subtleBorder.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Symptom Summary',
            style: TextStyle(
              color: SACAColors.secondaryText.withOpacity(0.8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            symptoms.where((String s) => s.trim().isNotEmpty).join('  •  '),
            style: TextStyle(
              color: SACAColors.secondaryText.withOpacity(0.9),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActionBar extends StatelessWidget {
  const _ResultActionBar({
    required this.triageColor,
    required this.onAlertClinic,
    required this.onReturnHome,
  });

  final Color triageColor;
  final VoidCallback onAlertClinic;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: onReturnHome,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: SACAColors.deepClinicalGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('NEW ASSESSMENT'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: triageColor,
                foregroundColor: Colors.white,
                elevation: 6,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onAlertClinic,
              child: const Text('ALERT CLINIC'),
            ),
          ),
        ],
      ),
    );
  }
}

Color _triageColor(String level) {
  final String normalized = level.toLowerCase();
  if (normalized.contains('severe') ||
      normalized.contains('high') ||
      normalized.contains('critical')) {
    return const Color(0xFF8B0000);
  }
  if (normalized.contains('moderate') || normalized.contains('medium')) {
    return const Color(0xFFB8860B);
  }
  return const Color(0xFF1A5241);
}

String _defaultRecommendationForLevel(String level) {
  final String normalized = level.toLowerCase();
  if (normalized.contains('severe') ||
      normalized.contains('high') ||
      normalized.contains('critical')) {
    return 'Evacuate immediately. Alert the nearest medical officer. '
        'Monitor vitals every 5 minutes.';
  }
  if (normalized.contains('moderate') || normalized.contains('medium')) {
    return 'Schedule clinic visit within 4 hours. Keep patient hydrated. '
        'Monitor for worsening symptoms.';
  }
  return 'Routine check-up recommended. Provide home care instructions. '
      'Follow up if symptoms persist.';
}

class LanguageCard extends StatelessWidget {
  const LanguageCard({
    super.key,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final Color accentColor;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard(
      onTap: onTap,
      builder: (bool active) {
        return _BaseCard(
          active: active,
          accentColor: accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.16),
                ),
                child: Icon(icon, color: accentColor, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: SACAColors.charcoal,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReportModeCardData {
  const ReportModeCardData({
    required this.mode,
    required this.heroTag,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    this.recommended = false,
  });

  final ReportMode mode;
  final String heroTag;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final bool recommended;
}

class ReportModeCard extends StatelessWidget {
  const ReportModeCard({super.key, required this.data, required this.onTap});

  final ReportModeCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard(
      onTap: onTap,
      builder: (bool active) {
        return _BaseCard(
          active: active,
          accentColor: data.accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (data.recommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: data.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    SACAStrings.tr(
                      context: context,
                      english: 'Recommended',
                      warlpiri: 'Recommended',
                    ),
                    style: TextStyle(
                      color: data.accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (data.recommended) const SizedBox(height: 12),
              Hero(
                tag: data.heroTag,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.accentColor.withOpacity(0.14),
                  ),
                  child: Icon(data.icon, color: data.accentColor, size: 31),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: const TextStyle(
                  color: SACAColors.charcoal,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.description,
                style: const TextStyle(
                  color: SACAColors.secondaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({super.key, required this.onTap, required this.builder});

  final VoidCallback onTap;
  final Widget Function(bool active) builder;

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _isHovered || _isPressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: active ? 1.02 : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: widget.onTap,
            onHighlightChanged: (bool pressed) {
              if (_isPressed != pressed) {
                setState(() => _isPressed = pressed);
              }
            },
            child: widget.builder(active),
          ),
        ),
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({
    required this.active,
    required this.accentColor,
    required this.child,
  });

  final bool active;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SACAColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: active ? accentColor : SACAColors.subtleBorder,
          width: active ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(active ? 0.12 : 0.08),
            blurRadius: active ? 24 : 15,
            offset: Offset(0, active ? 10 : 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TriageService {
  TriageService({
    this.baseUrl = 'http://127.0.0.1:8000',
    this.authToken = 'dev-token',
  });

  final String baseUrl;
  final String authToken;
  String? _lastRecordedWavPath;

  Future<String> transcribeAudio(File wavFile) async {
    _lastRecordedWavPath = wavFile.path;
    final List<String> candidatePaths = <String>[
      '$baseUrl/v2/transcribe',
      '$baseUrl/transcribe',
      '$baseUrl/triage/transcribe',
    ];

    for (final String url in candidatePaths) {
      try {
        final int wavSize = await wavFile.length();
        debugPrint(
          '[VOICE][UPLOAD] Transcribe request url=$url file=${wavFile.path} size_bytes=$wavSize',
        );
        if (wavSize <= 0) {
          throw Exception('Recorded file is empty (0 bytes).');
        }
        final Uri uri = Uri.parse(url);
        final http.MultipartRequest req = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $authToken';

        req.files.add(
          await http.MultipartFile.fromPath(
            'audio_file',
            wavFile.path,
            filename: 'voice_note.wav',
          ),
        );

        final http.StreamedResponse streamed = await req.send();
        final String body = await streamed.stream.bytesToString();
        debugPrint(
          '[VOICE][UPLOAD] Transcribe response url=$url status=${streamed.statusCode} body=${body.length > 180 ? "${body.substring(0, 180)}..." : body}',
        );
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          continue;
        }

        final dynamic decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;
        final Map<String, dynamic> jsonMap = decoded;
        final String transcript = (jsonMap['transcript_final'] ??
                jsonMap['transcript_final_text'] ??
                jsonMap['transcript'] ??
                jsonMap['text'] ??
                '')
            .toString();
        if (transcript.trim().isNotEmpty) return transcript;
      } catch (e) {
        debugPrint('[VOICE][UPLOAD] Transcribe request failed url=$url error=$e');
        // Try the next endpoint.
      }
    }

    throw Exception('Transcription failed (no valid response received).');
  }

  Future<TriageApiResult> submitSession(
    TriageSession session, {
    File? wavFile,
  }) async {
    final File? resolvedWavFile = wavFile ??
        ((_lastRecordedWavPath != null) ? File(_lastRecordedWavPath!) : null);

    final String narrative = [
      session.chiefComplaint,
      if (session.onset.isNotEmpty) 'Onset: ${session.onset}',
      if (session.medications.isNotEmpty) 'Medications: ${session.medications}',
      if (session.allergies.isNotEmpty) 'Allergies: ${session.allergies}',
      'Worsening: ${session.isWorsening ? "yes" : "no"}',
    ].where((String s) => s.trim().isNotEmpty).join('. ');

    final List<String> urls = <String>[
      '$baseUrl/triage/analyze-voice',
      '$baseUrl/v2/triage/analyze-voice',
    ];

    for (final String url in urls) {
      try {
        final Uri uri = Uri.parse(url);
        final http.MultipartRequest req = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $authToken'
          ..fields['text_input'] = narrative
          ..fields['voice_transcript'] = session.chiefComplaint
          ..fields['pain_locations'] = jsonEncode(session.painLocation);

        if (resolvedWavFile != null && await resolvedWavFile.exists()) {
          req.files.add(
            await http.MultipartFile.fromPath(
              'audio_file',
              resolvedWavFile.path,
              filename: 'voice_note.wav',
            ),
          );
        } else {
          req.files.add(
            http.MultipartFile.fromBytes(
              'audio_file',
              _buildFallbackWavBytes(),
              filename: 'fallback.wav',
            ),
          );
        }

        final http.StreamedResponse streamed = await req.send().timeout(
          const Duration(seconds: 20),
        );
        final String body = await streamed.stream.bytesToString().timeout(
          const Duration(seconds: 20),
        );
        debugPrint(
          '[VOICE][UPLOAD] Analyze response url=$url status=${streamed.statusCode} body=${body.length > 220 ? "${body.substring(0, 220)}..." : body}',
        );
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          continue;
        }
        final dynamic decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return TriageApiResult.fromJson(decoded);
        }
      } catch (e) {
        debugPrint('[VOICE][UPLOAD] Analyze request failed url=$url error=$e');
      }
    }

    final String fallbackLevel = session.isWorsening ? 'Moderate' : 'Mild';
    return TriageApiResult(
      triageLevel: fallbackLevel,
      topCondition: session.chiefComplaint.isEmpty
          ? 'General clinical review'
          : 'Symptom review required',
      transcriptFinal: session.chiefComplaint,
      recommendation: _defaultRecommendationForLevel(fallbackLevel),
    );
  }

  Uint8List _buildFallbackWavBytes() {
    const int sampleRate = 16000;
    const int seconds = 1;
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int dataSize = sampleRate * seconds * blockAlign;
    final ByteData header = ByteData(44);

    void writeAscii(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // PCM chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final Uint8List out = Uint8List(44 + dataSize);
    out.setRange(0, 44, header.buffer.asUint8List());
    // Data bytes are already zero -> 1 second of silence.
    return out;
  }
}
