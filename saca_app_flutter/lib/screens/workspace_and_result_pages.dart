part of '../main.dart';

enum AssessmentPreOutcome { redo }

/// 1→10 pain highlight: teal/green toward amber then red as pain increases.
Color _painHeatColor(double sliderValue) {
  final double t =
      (((sliderValue - 1) / 9)).clamp(0.0, 1.0);
  const Color low = Color(0xFF1E5C42);
  const Color mid = Color(0xFFD68C38);
  const Color high = Color(0xFFC41E3A);
  if (t <= 0.5) {
    return Color.lerp(low, mid, t / 0.5)!;
  }
  return Color.lerp(mid, high, (t - 0.5) / 0.5)!;
}

class _PainIntensityBlock extends StatelessWidget {
  const _PainIntensityBlock({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  String _numericBadge(BuildContext context) {
    final int v = value.round().clamp(1, 10);
    if (v <= 1) {
      return SACAStrings.tr(
        context: context,
        english: '$v — Little pain',
        warlpiri: '$v — Little pain',
      );
    }
    if (v >= 10) {
      return SACAStrings.tr(
        context: context,
        english: '$v — Unbearable',
        warlpiri: '$v — Unbearable',
      );
    }
    if (v == 5) {
      return SACAStrings.tr(
        context: context,
        english: '$v — Medium pain',
        warlpiri: '$v — Medium pain',
      );
    }
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final double slid = value.clamp(1, 10);
    final Color heat = _painHeatColor(slid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              SACAStrings.tr(
                context: context,
                english: 'Rate your pain',
                warlpiri: 'Rate your pain',
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: SACATriageTypography.painPrompt,
                color: SACAColors.charcoal.withValues(alpha: 0.88),
              ),
            ),
            Text(
              _numericBadge(context),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: heat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: heat,
            inactiveTrackColor: SACAColors.subtleBorder,
            thumbColor: heat,
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          ),
          child: Slider(
            value: slid,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${slid.round()}',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                SACAStrings.tr(
                  context: context,
                  english: '1 — Little pain',
                  warlpiri: '1 — Little pain',
                ),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: _painHeatColor(1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                SACAStrings.tr(
                  context: context,
                  english: '5 — Medium pain',
                  warlpiri: '5 — Medium pain',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: _painHeatColor(5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                SACAStrings.tr(
                  context: context,
                  english: '10 — Unbearable',
                  warlpiri: '10 — Unbearable',
                ),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: _painHeatColor(10),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
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
  final TextEditingController _chiefComplaintController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  late final TriageSession _session;
  int _currentStep = 0;
  bool _isWorsening = false;
  final Map<int, String> _capturedAnswers = <int, String>{};
  /// Selected onset duration for typed flow (step 2).
  String _selectedOnsetOption = '';

  static const List<String> _onsetDurationOptions = <String>[
    '1 day',
    '2-3 days',
    '4-6 days',
    '7 days or more',
  ];
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
      painScore: 5,
      additionalConcerns: '',
    );
  }

  void _resetAssessment() {
    setState(() {
      _currentStep = 0;
      _capturedAnswers.clear();
      _isWorsening = false;
      _chiefComplaintController.clear();
      _medicationsController.clear();
      _allergiesController.clear();
      _selectedOnsetOption = '';
      _session.chiefComplaint = '';
      _session.onset = '';
      _session.isWorsening = false;
      _session.medications = '';
      _session.allergies = '';
      _session.painLocation.clear();
      _session.painScore = 5;
      _session.additionalConcerns = '';
    });
  }

  IconData _flowHeroIcon() {
    switch (widget.mode) {
      case ReportMode.selection:
        return Icons.touch_app_rounded;
      case ReportMode.voice:
      case ReportMode.text:
        return Icons.edit_note_rounded;
    }
  }

  void _navigateToPreResultCapture() {
    if (widget.mode == ReportMode.selection) {
      Navigator.of(context)
          .push<AssessmentPreOutcome>(
            MaterialPageRoute<AssessmentPreOutcome>(
              builder: (_) => PreResultPainPage(
                session: _session,
                triageService: widget.triageService,
                workspace: _workspaceConfig(context),
                heroTag: widget.heroTag,
                heroIcon: _flowHeroIcon(),
              ),
            ),
          )
          .then((AssessmentPreOutcome? outcome) {
            if (!mounted) return;
            if (outcome == AssessmentPreOutcome.redo) {
              _resetAssessment();
            }
          });
      return;
    }
    Navigator.of(context)
        .push<AssessmentPreOutcome>(
          MaterialPageRoute<AssessmentPreOutcome>(
            builder: (_) => PreResultNotesPage(
              session: _session,
              triageService: widget.triageService,
              workspace: _workspaceConfig(context),
              heroTag: widget.heroTag,
              heroIcon: _flowHeroIcon(),
            ),
          ),
        )
        .then((AssessmentPreOutcome? outcome) {
          if (!mounted) return;
          if (outcome == AssessmentPreOutcome.redo) {
            _resetAssessment();
          }
        });
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
                      fontSize: SACATriageTypography.pageHeadline,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.subtitle,
                    style: const TextStyle(
                      color: SACAColors.secondaryText,
                      fontSize: SACATriageTypography.pageSubtitle,
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
                          valueColor: AlwaysStoppedAnimation<Color>(config.accentColor),
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
                  color: config.accentColor.withValues(alpha: 0.14),
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
                fontSize: SACATriageTypography.sectionLead,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? SACAColors.warlpiriOrange.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: selected ? SACAColors.warlpiriOrange : SACAColors.subtleBorder,
                            width: selected ? 2.3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            bodyPart,
                            style: const TextStyle(
                              color: SACAColors.charcoal,
                              fontSize: SACATriageTypography.gridLabel,
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
                onPressed: _navigateToPreResultCapture,
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
              color: config.accentColor.withValues(alpha: 0.14),
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
                    _currentStep == 1
                        ? _painMainCardQuestion()
                        : _stepQuestion(_currentStep),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: SACATriageTypography.cardQuestion,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Expanded(
                  child: widget.mode == ReportMode.voice && _currentStep == 1
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              _painMainCardQuestion(),
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                fontSize: SACATriageTypography.cardQuestion,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                color: SACAColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _PainIntensityBlock(
                              value: _session.painScore.toDouble(),
                              onChanged: (double v) {
                                setState(() {
                                  _session.painScore = v.round().clamp(1, 10);
                                });
                              },
                            ),
                            _betterWorseDividerBlock(),
                            const SizedBox(height: 4),
                            _betterWorseSubheading(),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ClinicalInputCard(
                                questionText: _stepQuestion(1),
                                triageService: widget.triageService,
                                accentColor: config.accentColor,
                                initialTranscript:
                                    _capturedAnswers[_currentStep] ?? '',
                                onConfirmed: _handleClinicalConfirm,
                              ),
                            ),
                          ],
                        )
                      : widget.mode == ReportMode.voice
                          ? ClinicalInputCard(
                              questionText: _stepQuestion(_currentStep),
                              triageService: widget.triageService,
                              accentColor: config.accentColor,
                              initialTranscript:
                                  _capturedAnswers[_currentStep] ?? '',
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
                        onPressed: _goNextOrSubmit,
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
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _PainIntensityBlock(
                      value: _session.painScore.toDouble(),
                      onChanged: (double v) {
                        setState(() {
                          _session.painScore = v.round().clamp(1, 10);
                        });
                      },
                    ),
                    _betterWorseDividerBlock(),
                    const SizedBox(height: 2),
                    _betterWorseSubheading(),
                    const SizedBox(height: 14),
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
                          onSelected: (_) =>
                              setState(() => _isWorsening = false),
                        ),
                        ChoiceChip(
                          label: Text(
                            _bilingualPrompt(
                              english: 'Getting Worse',
                              warlpiri: 'Panu',
                            ),
                          ),
                          selected: _isWorsening,
                          onSelected: (_) =>
                              setState(() => _isWorsening = true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case 2:
        return Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _onsetDurationOptions.map((String option) {
                final bool chosen = _selectedOnsetOption == option;
                return ChoiceChip(
                  label: Text(
                    _bilingualPrompt(
                      english: option,
                      warlpiri: option,
                    ),
                  ),
                  selected: chosen,
                  onSelected: (_) => setState(() => _selectedOnsetOption = option),
                );
              }).toList(),
            ),
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
                fontSize: SACATriageTypography.sectionSub,
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
                  label: Text(_bilingualPrompt(english: 'Yes', warlpiri: 'Yea')),
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

  String _painMainCardQuestion() {
    return _bilingualPrompt(
      english: 'How intense is your pain right now?',
      warlpiri: 'How intense is your pain right now?',
    );
  }

  Widget _betterWorseDividerBlock() {
    return Divider(
      height: 28,
      thickness: 1,
      color: SACAColors.subtleBorder.withValues(alpha: 0.95),
    );
  }

  Widget _betterWorseSubheading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          SACAStrings.tr(
            context: context,
            english: 'Symptoms trend',
            warlpiri: 'Symptoms trend',
          ),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: SACAColors.secondaryText.withValues(alpha: 0.9),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _stepQuestion(1),
          style: TextStyle(
            fontSize: SACATriageTypography.sectionSub + 1,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: SACAColors.secondaryText,
          ),
        ),
      ],
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
    if (widget.mode == ReportMode.text &&
        _currentStep == 2 &&
        _selectedOnsetOption.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            SACAStrings.tr(
              context: context,
              english: 'Please choose how long this has been going on.',
              warlpiri: 'Please choose how long this has been going on.',
            ),
          ),
        ),
      );
      return;
    }
    if (widget.mode == ReportMode.voice) {
      _session.chiefComplaint = (_capturedAnswers[0] ?? '').trim();
      _session.onset = (_capturedAnswers[2] ?? '').trim();
      final String medsAllergies = (_capturedAnswers[4] ?? '').trim();
      _session.medications = medsAllergies;
      _session.allergies = medsAllergies;
    } else {
      _session.chiefComplaint = _chiefComplaintController.text.trim();
      _session.onset = _selectedOnsetOption.trim();
      _session.medications = _medicationsController.text.trim();
      _session.allergies = _allergiesController.text.trim();
    }
    _session.isWorsening = _isWorsening;
    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
      return;
    }
    _navigateToPreResultCapture();
  }

  void _handleClinicalConfirm(String value) {
    final String cleaned = value.trim();
    _capturedAnswers[_currentStep] = cleaned;
    if (_currentStep == 1 || _currentStep == 3) {
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

class PreResultPainPage extends StatefulWidget {
  const PreResultPainPage({
    super.key,
    required this.session,
    required this.triageService,
    required this.workspace,
    required this.heroTag,
    required this.heroIcon,
  });

  final TriageSession session;
  final TriageService triageService;
  final WorkspaceConfig workspace;
  final String heroTag;
  final IconData heroIcon;

  @override
  State<PreResultPainPage> createState() => _PreResultPainPageState();
}

class _PreResultPainPageState extends State<PreResultPainPage> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.session.painScore.clamp(1, 10).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.workspace.accentColor;

    return Scaffold(
      backgroundColor: SACAColors.pageBackground,
      appBar: AppBar(
        backgroundColor: SACAColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.workspace.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      SACAStrings.tr(
                        context: context,
                        english: 'How intense is your pain right now?',
                        warlpiri: 'How intense is your pain right now?',
                      ),
                      style: const TextStyle(
                        fontSize: SACATriageTypography.sectionLead,
                        fontWeight: FontWeight.w800,
                        color: SACAColors.charcoal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      SACAStrings.tr(
                        context: context,
                        english: '1 — little pain · 5 — medium · 10 — unbearable',
                        warlpiri: '1 — little pain · 5 — medium · 10 — unbearable',
                      ),
                      style: const TextStyle(
                        color: SACAColors.secondaryText,
                        fontSize: SACATriageTypography.sectionSub,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BaseCard(
                      active: false,
                      accentColor: accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _PainIntensityBlock(
                            value: _sliderValue,
                            onChanged: (double v) =>
                                setState(() => _sliderValue = v),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(AssessmentPreOutcome.redo);
                                },
                                icon: const Icon(Icons.replay_rounded),
                                label: Text(
                                  SACAStrings.tr(
                                    context: context,
                                    english: 'Redo assessment',
                                    warlpiri: 'Redo assessment',
                                  ),
                                ),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  widget.session.painScore =
                                      _sliderValue.round().clamp(1, 10);
                                  Navigator.of(context)
                                      .push<AssessmentPreOutcome>(
                                    MaterialPageRoute<AssessmentPreOutcome>(
                                      builder: (_) => PreResultNotesPage(
                                        session: widget.session,
                                        triageService: widget.triageService,
                                        workspace: widget.workspace,
                                        heroTag: widget.heroTag,
                                        heroIcon: widget.heroIcon,
                                      ),
                                    ),
                                  ).then((AssessmentPreOutcome? outcome) {
                                    if (!context.mounted) return;
                                    if (outcome == AssessmentPreOutcome.redo) {
                                      Navigator.of(context)
                                          .pop(AssessmentPreOutcome.redo);
                                    }
                                  });
                                },
                                child: Text(
                                  SACAStrings.tr(
                                    context: context,
                                    english: 'Continue',
                                    warlpiri: 'Continue',
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class PreResultNotesPage extends StatefulWidget {
  const PreResultNotesPage({
    super.key,
    required this.session,
    required this.triageService,
    required this.workspace,
    required this.heroTag,
    required this.heroIcon,
  });

  final TriageSession session;
  final TriageService triageService;
  final WorkspaceConfig workspace;
  final String heroTag;
  final IconData heroIcon;

  @override
  State<PreResultNotesPage> createState() => _PreResultNotesPageState();
}

class _PreResultNotesPageState extends State<PreResultNotesPage> {
  final TextEditingController _additionalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _additionalController.text = widget.session.additionalConcerns;
  }

  @override
  void dispose() {
    _additionalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceConfig config = widget.workspace;
    final Color accent = config.accentColor;

    return Scaffold(
      backgroundColor: SACAColors.pageBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          config.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
                      fontSize: SACATriageTypography.pageHeadline,
                      fontWeight: FontWeight.w800,
                      color: SACAColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.subtitle,
                    style: const TextStyle(
                      color: SACAColors.secondaryText,
                      fontSize: SACATriageTypography.pageSubtitle,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: 1,
                        backgroundColor: SACAColors.subtleBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Hero(
                          tag: widget.heroTag,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.heroIcon,
                              color: accent,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _BaseCard(
                            active: false,
                            accentColor: accent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  SACAStrings.tr(
                                    context: context,
                                    english:
                                        'Anything else — other symptoms or '
                                        'something you want the clinic to know?',
                                    warlpiri:
                                        'Anything else — other symptoms or '
                                        'something you want the clinic to know?',
                                  ),
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    fontSize: SACATriageTypography.cardQuestion,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    color: SACAColors.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  SACAStrings.tr(
                                    context: context,
                                    english:
                                        'Optional — add details if something '
                                        'was not covered above.',
                                    warlpiri:
                                        'Optional — add details if something '
                                        'was not covered above.',
                                  ),
                                  style: const TextStyle(
                                    color: SACAColors.secondaryText,
                                    fontSize: SACATriageTypography.sectionSub,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  child: TextField(
                                    controller: _additionalController,
                                    expands: true,
                                    maxLines: null,
                                    minLines: null,
                                    textAlignVertical: TextAlignVertical.top,
                                    cursorColor: accent,
                                    decoration: InputDecoration(
                                      hintText: SACAStrings.tr(
                                        context: context,
                                        english: 'Optional — type here…',
                                        warlpiri: 'Optional — type here…',
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                          color: SACAColors.subtleBorder,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                          color: SACAColors.subtleBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: accent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop(
                                          AssessmentPreOutcome.redo,
                                        );
                                      },
                                      icon: const Icon(Icons.replay_rounded),
                                      label: Text(
                                        SACAStrings.tr(
                                          context: context,
                                          english: 'Redo assessment',
                                          warlpiri: 'Redo assessment',
                                        ),
                                      ),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: accent,
                                      ),
                                      onPressed: () {
                                        widget.session.additionalConcerns =
                                            _additionalController.text.trim();
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => ResultSummaryPage(
                                              session: widget.session,
                                              triageService:
                                                  widget.triageService,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        SACAStrings.tr(
                                          context: context,
                                          english: 'See triage results',
                                          warlpiri: 'See triage results',
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
  late Future<TriageApiResult> _future;
  bool _initialised = false;
  Color _actionColor = const Color(0xFF1A5241);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final AppLanguage selectedLanguage = SACAStateScope.of(context).selectedLanguage;
    _future = widget.apiResult != null
        ? Future<TriageApiResult>.value(widget.apiResult!)
        : widget.triageService.submitSession(
            widget.session,
            language: selectedLanguage,
          );
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
          Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
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
                builder: (BuildContext context, AsyncSnapshot<TriageApiResult> snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Failed to fetch triage result: ${snapshot.error}'),
                    );
                  }
                  final TriageApiResult result = snapshot.data!;
                  final Color resolvedColor = _triageColor(result.triageLevel);
                  final AppLanguage appLang = SACAStateScope.of(context).selectedLanguage;
                  final String languageBadge =
                      appLang == AppLanguage.warlpiri ? 'Warlpiri (wbp)' : 'English';
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
                        languageBadge: languageBadge,
                      ),
                      const SizedBox(height: 18),
                      _PatientTranscriptBox(transcript: result.transcriptFinal),
                      if (result.warlpiriRawTranscript != null &&
                          result.warlpiriRawTranscript!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: SACAColors.subtleBorder),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                              childrenPadding: const EdgeInsets.only(bottom: 12),
                              title: const Text(
                                'Voice transcript (as recognized)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: SACAColors.secondaryText,
                                ),
                              ),
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      result.warlpiriRawTranscript!,
                                      style: const TextStyle(
                                        color: SACAColors.charcoal,
                                        fontSize: 14,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      _ActionPlanBox(
                        triageLevel: result.triageLevel,
                        recommendation: result.recommendation,
                      ),
                      const SizedBox(height: 16),
                      _SymptomWrap(
                        symptoms: result.top3Symptoms.isNotEmpty
                            ? result.top3Symptoms
                            : <String>[
                                if (widget.session.chiefComplaint.isNotEmpty)
                                  widget.session.chiefComplaint,
                                if (widget.session.onset.isNotEmpty)
                                  'Onset: ${widget.session.onset}',
                                if (widget.session.medications.isNotEmpty)
                                  'Meds: ${widget.session.medications}',
                                if (widget.session.allergies.isNotEmpty)
                                  'Allergies: ${widget.session.allergies}',
                                'Pain intensity: ${widget.session.painScore.clamp(1, 10)}/10',
                                if (painLocationText.isNotEmpty &&
                                    painLocationText != 'None selected')
                                  'Pain location: $painLocationText',
                                if (widget.session.additionalConcerns
                                    .trim()
                                    .isNotEmpty)
                                  'Patient notes: ${widget.session.additionalConcerns.trim()}',
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
