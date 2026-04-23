import 'dart:io';

import 'package:flutter/material.dart';

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
    final SACAStateScope? scope =
        context.dependOnInheritedWidgetOfExactType<SACAStateScope>();
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
  static const Color pageBackground = Color(0xFFF7F6F3);
  static const Color cardBackground = Colors.white;
  static const Color charcoal = Color(0xFF1F1F1F);
  static const Color secondaryText = Color(0xFF5E5A56);
  static const Color subtleBorder = Color(0xFFE8E2D8);
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
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final int columns = constraints.maxWidth >= 980 ? 3 : 1;
                        return GridView.builder(
                          itemCount: methods.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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

class _WorkspacePageState extends State<WorkspacePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _chiefComplaintController = TextEditingController();
  final TextEditingController _onsetController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  late final TriageSession _session;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  int _currentStep = 0;
  bool _isWorsening = false;
  bool _isListening = false;
  final Set<int> _capturedVoiceSteps = <int>{};
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
    _pulseController.dispose();
    _chiefComplaintController.dispose();
    _onsetController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
        return _buildQuestionnaire(config: config, showVoicePrompt: true);
      case ReportMode.text:
        return _buildQuestionnaire(config: config, showVoicePrompt: false);
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
                  final bool selected = _session.painLocation.contains(bodyPart);
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
                      builder: (_) => ResultSummaryPage(session: _session),
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

  Widget _buildQuestionnaire({
    required WorkspaceConfig config,
    required bool showVoicePrompt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!showVoicePrompt) ...<Widget>[
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
        ],
        Expanded(
          child: _BaseCard(
            active: false,
            accentColor: config.accentColor,
            child: Column(
              crossAxisAlignment: showVoicePrompt
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: <Widget>[
                if (showVoicePrompt) ...<Widget>[
                  Text(
                    _bilingualPrompt(
                      english: 'Tap to Speak',
                      warlpiri: 'Nyangkura-pinyi',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: config.accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  _stepQuestion(_currentStep),
                  textAlign: showVoicePrompt ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: SACAColors.charcoal,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: showVoicePrompt
                      ? _buildVoiceCaptureArea(config)
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
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: config.accentColor,
                      ),
                      onPressed:
                          (showVoicePrompt && !_capturedVoiceSteps.contains(_currentStep))
                          ? null
                          : () => _goNextOrSubmit(),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCaptureArea(WorkspaceConfig config) {
    return Center(
      child: ScaleTransition(
        scale: _pulseScale,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _isListening ? 176 : 150,
              height: _isListening ? 176 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.accentColor.withOpacity(_isListening ? 0.18 : 0.1),
              ),
            ),
            Hero(
              tag: widget.heroTag,
              child: GestureDetector(
                onTap: _captureVoiceStep,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SACAColors.deepClinicalGreen,
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                    _bilingualPrompt(english: 'Getting Worse', warlpiri: 'Panu'),
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
                  label: Text(
                    _bilingualPrompt(english: 'No', warlpiri: 'No'),
                  ),
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
          warlpiri: 'Ngula-kari yimi-ngarrka nyinami warlalja-warnu, panu-kari yinyami?',
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
      _session.chiefComplaint = _capturedVoiceSteps.contains(0)
          ? 'Voice response captured (symptoms)'
          : _session.chiefComplaint;
      _session.onset = _capturedVoiceSteps.contains(2)
          ? 'Voice response captured (onset)'
          : _session.onset;
      _session.medications = _capturedVoiceSteps.contains(4)
          ? 'Voice response captured (medications)'
          : _session.medications;
      _session.allergies = _capturedVoiceSteps.contains(4)
          ? 'Voice response captured (allergies)'
          : _session.allergies;
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
        builder: (_) => ResultSummaryPage(session: _session),
      ),
    );
  }

  Future<void> _captureVoiceStep() async {
    if (_isListening) return;
    setState(() {
      _isListening = true;
    });
    _pulseController.repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isListening = false;
      _capturedVoiceSteps.add(_currentStep);
    });
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

class ResultSummaryPage extends StatelessWidget {
  const ResultSummaryPage({super.key, required this.session});

  final TriageSession session;

  @override
  Widget build(BuildContext context) {
    final String painLocationText = session.painLocation.isEmpty
        ? 'None selected'
        : session.painLocation.join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          SACAStrings.tr(
            context: context,
            english: 'Result Summary',
            warlpiri: 'Result Summary',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _BaseCard(
                active: false,
                accentColor: SACAColors.deepClinicalGreen,
                child: ListView(
                  children: <Widget>[
                    _summaryRow('Chief complaint', session.chiefComplaint),
                    _summaryRow('Onset', session.onset),
                    _summaryRow(
                      'Worsening',
                      session.isWorsening ? 'Yes' : 'No',
                    ),
                    _summaryRow('Medications', session.medications),
                    _summaryRow('Allergies', session.allergies),
                    _summaryRow('Pain location', painLocationText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: SACAColors.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: SACAColors.charcoal,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
  const HoverScaleCard({
    super.key,
    required this.onTap,
    required this.builder,
  });

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
  Future<void> sendToInference(String text, File? image) async {
    // Backend integration hook for FastAPI triage inference.
  }

  Future<void> sendVoiceTranscript(String transcript) async {
    // Backend integration hook for speech-to-triage payloads.
  }

  Future<void> sendSelectionPayload(List<String> selectedCodes) async {
    // Backend integration hook for coded picklist submissions.
  }
}
