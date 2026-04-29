part of '../main.dart';

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
                      _PatientTranscriptBox(transcript: result.transcriptFinal),
                      const SizedBox(height: 14),
                      _ActionPlanBox(
                        triageLevel: result.triageLevel,
                        recommendation: result.recommendation,
                      ),
                      const SizedBox(height: 16),
                      _SymptomWrap(
                        symptoms: <String>[
                          if (widget.session.chiefComplaint.isNotEmpty) widget.session.chiefComplaint,
                          if (widget.session.onset.isNotEmpty) 'Onset: ${widget.session.onset}',
                          if (widget.session.medications.isNotEmpty)
                            'Meds: ${widget.session.medications}',
                          if (widget.session.allergies.isNotEmpty)
                            'Allergies: ${widget.session.allergies}',
                          if (painLocationText.isNotEmpty) 'Pain: $painLocationText',
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
