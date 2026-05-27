part of '../main.dart';

// ── Symptom → Image83 asset path map ─────────────────────────────────────
// Every key matches a symptom label in _kSymptomCatalog or _kSystemicCategories.
// Used only by _IllnessSelectionPage (point-and-selection section).
const _kSymptomImages = <String, String>{
  // Head / Neck / Face / Throat
  'Headache':                                    'assets/Image83/1.Headache.jpg',
  'Head injury or bump':                         'assets/Image83/2.Head injury or bump.jpg',
  'Neck pain or stiffness':                      'assets/Image83/3.Neck pain or stiffness.jpg',
  'Jaw pain':                                    'assets/Image83/4.Jaw_pain.jpg',
  'Facial swelling or bruising':                 'assets/Image83/5.Facial swelling or bruising.jpg',
  'Eye injury or pain':                          'assets/Image83/6.Eye injury or pain.jpg',
  'Ear pain':                                    'assets/Image83/7.Ear Pain.jpg',
  'Toothache or mouth pain':                     'assets/Image83/8.Toothache or mouth pain.jpg',
  'Sore throat':                                 'assets/Image83/9.Sore throat.jpg',
  'Difficulty swallowing':                       'assets/Image83/10.Difficulty swallowing.jpg',
  'Facial numbness or tingling':                 'assets/Image83/11.Facial numbness or tingling.jpg',
  // Chest / Abdomen / Back / Pelvis / Urinary
  'Sharp chest pain':                            'assets/Image83/12.Sharp chest pain.jpg',
  'Burning chest pain':                          'assets/Image83/13.Burning chest pain.jpg',
  'Rib pain or tenderness':                      'assets/Image83/14.Rib pain or tenderness.jpg',
  'Heartburn':                                   'assets/Image83/15.Heartburn.jpg',
  'Upper abdominal pain':                        'assets/Image83/16.Upper abdominal pain.jpg',
  'Lower abdominal pain':                        'assets/Image83/17.Lower abdominal pain.jpg',
  'Side or flank pain':                          'assets/Image83/18.Side or flank pain.jpg',
  'Stomach bloating or cramping':                'assets/Image83/19.Stomach bloating or cramping.jpg',
  'Groin or pelvic pain':                        'assets/Image83/20.Groin or pelvic pain.jpg',
  'Upper back pain':                             'assets/Image83/21.Upper back pain.jpg',
  'Lower back pain':                             'assets/Image83/22.Lower back pain.jpg',
  'Blood in stool or black stool':               'assets/Image83/23.Blood in stool or black stool.jpg',
  'Vomiting blood':                              'assets/Image83/24.Vomiting blood.jpg',
  'Blood in urine':                              'assets/Image83/25.Blood in urine.jpg',
  'Painful urination':                           'assets/Image83/26.Painful urination.jpg',
  'Frequent urination':                          'assets/Image83/26-1.Frequent urination.jpg',
  // Arms / Shoulders / Hands
  'Arm pain':                                    'assets/Image83/27.Arm pain.jpg',
  'Shoulder pain or injury':                     'assets/Image83/28.Shoulder pain or injury.jpg',
  'Elbow pain or injury':                        'assets/Image83/29.Elbow pain or injury.jpg',
  'Wrist pain or sprain':                        'assets/Image83/30.Wrist pain or sprain.jpg',
  'Hand or finger pain':                         'assets/Image83/31.Hand or finger pain.jpg',
  'Arm or hand swelling':                        'assets/Image83/32.Arm or hand swelling.jpg',
  'Suspected fracture (arm)':                    'assets/Image83/33.Suspected fracture (arm).jpg',
  'Arm numbness or tingling':                    'assets/Image83/34.Arm numbness or tingling.jpg',
  // Legs / Hips / Feet
  'Leg pain':                                    'assets/Image83/35.Leg pain.jpg',
  'Knee pain or injury':                         'assets/Image83/36.Knee pain or injury.jpg',
  'Ankle pain or sprain':                        'assets/Image83/37.Ankle pain or sprain.jpg',
  'Hip pain':                                    'assets/Image83/38.Hip pain.jpg',
  'Foot or toe pain':                            'assets/Image83/39.Foot or toe pain.jpg',
  'Leg or ankle swelling':                       'assets/Image83/40.Leg or ankle swelling.jpg',
  'Calf tightness or pain':                      'assets/Image83/41.Calf tightness or pain.jpg',
  'Suspected fracture (leg)':                    'assets/Image83/42.Suspected fracture (leg).jpg',
  'Leg numbness or tingling':                    'assets/Image83/43.Leg numbness or tingling.jpg',
  // Flu / Cold / Chest (systemic)
  'Fever or high temperature':                   'assets/Image83/44.Fever or high temperature.jpg',
  'Chills or shivering':                         'assets/Image83/45.Chills or shivering.jpg',
  'Body aches all over':                         'assets/Image83/46.Body aches all over.jpg',
  'Runny or blocked nose':                       'assets/Image83/47.Runny or blocked nose.jpg',
  'Sneezing':                                    'assets/Image83/48.Sneezing.jpg',
  'Cough':                                       'assets/Image83/49.Cough.jpg',
  'Coughing up blood':                           'assets/Image83/50.Coughing up blood.jpg',
  'Wheezing':                                    'assets/Image83/51.Wheezing.jpg',
  'Shortness of breath':                         'assets/Image83/52.Shortness of breath.jpg',
  // Allergies / Skin (systemic)
  'Itchy or watery eyes':                        'assets/Image83/53.Itchy or watery eyes.jpg',
  'Hives or skin welts':                         'assets/Image83/54.Hives or skin welts.jpg',
  'Itchy skin':                                  'assets/Image83/55.Itchy skin.jpg',
  'Skin rash':                                   'assets/Image83/55-1.Skin rash.jpg',
  'Dry or peeling skin':                         'assets/Image83/56.Dry or peeling skin.jpg',
  // Stomach & Digestion (systemic)
  'Nausea':                                      'assets/Image83/57.Nausea.jpg',
  'Vomiting':                                    'assets/Image83/58.Vomiting.jpg',
  'Diarrhoea':                                   'assets/Image83/59.Diarrhoea.jpg',
  'Loss of appetite':                            'assets/Image83/60.Loss of appetite.jpg',
  // Heart & Circulation (systemic)
  'Chest tightness or pressure':                 'assets/Image83/61.Chest tightness or pressure.jpg',
  'Racing heart or palpitations':                'assets/Image83/62.Racing heart or palpitations.jpg',
  'Fainting or near-fainting':                   'assets/Image83/63.Fainting or near-fainting.jpg',
  'Unexpected sweating':                         'assets/Image83/64.Unexpected sweating.jpg',
  // Anxiety & Panic (systemic)
  'Trembling or shaking':                        'assets/Image83/65.Trembling or shaking.jpg',
  'Sudden intense fear (panic attack)':          'assets/Image83/66.Sudden intense fear (panic attack).jpg',
  'Rapid shallow breathing':                     'assets/Image83/67.Rapid shallow breathing.jpg',
  // Sleep & Energy (systemic)
  'Insomnia or trouble sleeping':                'assets/Image83/68.Insomnia or trouble sleeping.jpg',
  'Excessive daytime sleepiness':                'assets/Image83/69.Excessive daytime sleepiness.jpg',
  'Loud snoring or stopping breathing in sleep': 'assets/Image83/70.Loud snoring or stopping breathing in sleep.jpg',
  'Fatigue or extreme tiredness':                'assets/Image83/71.Fatigue or tiredness.jpg',
  'General weakness':                            'assets/Image83/72.General weakness.jpg',
  // Neurological (systemic)
  'Dizziness or lightheadedness':                'assets/Image83/73.Dizziness or lightheadedness.jpg',
  'Confusion or disorientation':                 'assets/Image83/74.Confusion or disorientation.jpg',
  'Numbness or tingling (body-wide)':            'assets/Image83/75.Numbness or tingling (body-wide).jpg',
  'Involuntary or abnormal movements':           'assets/Image83/76.Involuntary or abnormal movements.jpg',
  'Difficulty with coordination or walking':     'assets/Image83/77.Difficulty with coordination or walking.jpg',
  'Seizures':                                    'assets/Image83/78.Seizures.jpg',
  // Blood Sugar (systemic)
  'Excessive thirst':                            'assets/Image83/79.Excessive thirst.jpg',
  'Shakiness or trembling when hungry':          'assets/Image83/80.Shakiness or trembling when hungry.jpg',
  'Feeling faint after skipping meals':          'assets/Image83/81.Feeling faint after skipping meals.jpg',
};

enum AssessmentPreOutcome { redo }

// ---------------------------------------------------------------------------
// Pain score voice parser
// ---------------------------------------------------------------------------

/// Extracts a 1-10 integer from free-form speech like:
///   "about a six", "7 out of 10", "severe pain maybe 8", "ngurluju six"
/// Returns null when no valid score can be found.
int? _parsePainScoreFromText(String text) {
  final String s = text.toLowerCase().trim();

  const Map<String, int> wordNums = <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'for': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
  };

  // 1a. Digit "X out of 10" / "X/10" — e.g. "7 out of 10", "8/10"
  final RegExp outOf = RegExp(r'(\d+)\s*(?:out\s*of|/)\s*10');
  final RegExpMatch? m1 = outOf.firstMatch(s);
  if (m1 != null) {
    final int? v = int.tryParse(m1.group(1)!);
    if (v != null && v >= 1 && v <= 10) return v;
  }

  // 1b. Word "X out of ten/10" — e.g. "six out of ten", "about a six out of ten"
  //     Must run BEFORE the generic word-form tier to prevent "ten" stealing the match.
  const Map<String, int> wordNums2 = <String, int>{
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'for': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
  };
  final RegExp wordOutOf = RegExp(
    r'\b(zero|one|two|three|four|for|five|six|seven|eight|nine|ten)\b'
    r'\s*out\s*of\s*(?:ten\b|10\b)',
  );
  final RegExpMatch? m1b = wordOutOf.firstMatch(s);
  if (m1b != null) {
    final int? v = wordNums2[m1b.group(1)!];
    if (v != null && v >= 1 && v <= 10) return v;
  }

  // 2. Digit 1-10 anywhere in the text (first occurrence wins)
  final RegExp digits = RegExp(r'\b(10|[1-9])\b');
  final RegExpMatch? m2 = digits.firstMatch(s);
  if (m2 != null) {
    final int? v = int.tryParse(m2.group(1)!);
    if (v != null) return v;
  }

  // 3. Word form — use \b word boundaries so "intensity" never matches "ten",
  //    "stone" never matches "one", etc.  Check highest values first.
  final List<MapEntry<String, int>> sorted = wordNums.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  for (final MapEntry<String, int> entry in sorted) {
    if (entry.value >= 1 &&
        entry.value <= 10 &&
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b').hasMatch(s)) {
      return entry.value;
    }
  }

  return null;
}

/// 1→10 pain highlight: teal/green toward amber then red as pain increases.
Color _painHeatColor(double sliderValue) {
  final double t = (((sliderValue - 1) / 9)).clamp(0.0, 1.0);
  const Color low = Color(0xFF1E5C42);
  const Color mid = Color(0xFFD68C38);
  const Color high = Color(0xFFC41E3A);
  if (t <= 0.5) {
    return Color.lerp(low, mid, t / 0.5)!;
  }
  return Color.lerp(mid, high, (t - 0.5) / 0.5)!;
}

class _PainIntensityBlock extends StatelessWidget {
  const _PainIntensityBlock({required this.value, required this.onChanged});

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
  final TextEditingController _chiefComplaintController =
      TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  late final TriageSession _session;
  int _currentStep = 0;
  bool _isWorsening = false;
  final Map<int, String> _capturedAnswers = <int, String>{};

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
        backgroundColor: SACAColorScheme.of(context).pageBackground,
        actions: const <Widget>[SACAQuickActions()],
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
                  if (widget.mode == ReportMode.selection)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          config.title,
                          style: TextStyle(
                            fontSize: SACATriageTypography.pageHeadline,
                            fontWeight: FontWeight.w800,
                            color: SACAColorScheme.of(context).charcoal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Hero(
                          tag: widget.heroTag,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: config.accentColor.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.touch_app_rounded,
                              color: config.accentColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...<Widget>[
                    Text(
                      config.title,
                      style: TextStyle(
                        fontSize: SACATriageTypography.pageHeadline,
                        fontWeight: FontWeight.w800,
                        color: SACAColorScheme.of(context).charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.subtitle,
                      style: TextStyle(
                        color: SACAColorScheme.of(context).secondaryText,
                        fontSize: SACATriageTypography.pageSubtitle,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (widget.mode != ReportMode.selection)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: (_currentStep + 1) / 4,
                          backgroundColor: SACAColorScheme.of(context).subtleBorder,
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
      case ReportMode.voice || ReportMode.text:
        return _buildQuestionnaire(config: config);
      case ReportMode.selection:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _bilingualPrompt(
                english: 'Select where it hurts',
                warlpiri: 'Nyarrpara-kapurlu pinyi?',
              ),
              style: const TextStyle(
                fontSize: SACATriageTypography.sectionLead,
                fontWeight: FontWeight.w700,
                color: SACAColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: InteractiveBodyWidget(
                session: _session,
                onSelectionChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: config.accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.local_hospital_rounded),
                label: Text(
                  SACAStrings.tr(
                    context: context,
                    english: 'Choose illness symptoms',
                    warlpiri: 'Choose illness symptoms',
                  ),
                ),
                onPressed: () {
                  if (_session.painLocation.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          SACAStrings.tr(
                            context: context,
                            english:
                                'Please select a body region before choosing illness symptoms.',
                            warlpiri:
                                'Please select a body region before choosing illness symptoms.',
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => _IllnessSelectionPage(
                        session: _session,
                        triageService: widget.triageService,
                        workspace: config,
                        heroTag: widget.heroTag,
                        selectedBodyParts:
                            List<String>.from(_session.painLocation),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildQuestionnaire({required WorkspaceConfig config}) {
    final bool isVoice = widget.mode == ReportMode.voice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Page header: pen icon + "Tap to Speak" badge (voice) ────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: widget.heroTag,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: config.accentColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: config.accentColor,
                  size: 30,
                ),
              ),
            ),
            if (isVoice) ...<Widget>[
              const SizedBox(width: 14),
              // "Tap to Read" pill — reads the current question aloud via TTS.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    // Speak the question for the current step.
                    // Step 1 (pain) prepends the pain question as a preamble.
                    final String question = _currentStep == 1
                        ? _stepQuestion(1)
                        : _stepQuestion(_currentStep);
                    final String? preamble =
                        _currentStep == 1 ? _painMainCardQuestion() : null;
                    KokoroTtsService.speak(
                      question,
                      preamble: preamble,
                      language: SACAStateScope.of(context).selectedLanguage,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: config.accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: config.accentColor.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.record_voice_over_rounded,
                            size: 15, color: config.accentColor),
                        const SizedBox(width: 6),
                        Text(
                          SACAStrings.tr(
                            context: context,
                            english: 'Tap to Read',
                            warlpiri: 'Yimi wangkarra',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: config.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Step counter chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SACAColorScheme.of(context).subtleBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                SACAStrings.tr(
                  context: context,
                  english: 'Step ${_currentStep + 1} of 4',
                  warlpiri: 'Yimi ${_currentStep + 1} / 4',
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SACAColorScheme.of(context).secondaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Main card body ───────────────────────────────────────────────────
        Expanded(
          child: _BaseCard(
            active: false,
            accentColor: config.accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[

                // For text mode: show question heading above input
                if (!isVoice) ...<Widget>[
                  Text(
                    _currentStep == 1
                        ? _painMainCardQuestion()
                        : _stepQuestion(_currentStep),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: SACATriageTypography.cardQuestion,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: SACAColorScheme.of(context).charcoal,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Scrollable content area ──────────────────────────────────
                Expanded(
                  child: isVoice && _currentStep == 1
                      // Step 1 (pain scale + symptoms trend):
                      // Pain slider + voice input all scroll together in one view.
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                _painMainCardQuestion(),
                                style: TextStyle(
                                  fontSize: SACATriageTypography.cardQuestion,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: SACAColorScheme.of(context).charcoal,
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
                              const SizedBox(height: 20),
                              Divider(
                                height: 1,
                                color: SACAColors.subtleBorder.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 20),
                              // Voice input card in shrink-wrap mode
                              // (no internal scroll — this Column owns the scroll).
                              // "Tap to Speak" label has moved to the page header above.
                              ClinicalInputCard(
                                // ValueKey forces a fresh state (empty transcript) on every step.
                                key: ValueKey<int>(_currentStep),
                                shrinkWrap: true,
                                showTapToSpeakLabel: false,
                                questionText: _stepQuestion(1),
                                triageService: widget.triageService,
                                accentColor: config.accentColor,
                                initialTranscript: _capturedAnswers[_currentStep] ?? '',
                                onConfirmed: _handleClinicalConfirm,
                                // Move the slider in real-time the moment STT
                                // returns — no need to tap Confirm first.
                                onTranscriptChanged: (String text) {
                                  final int? detected =
                                      _parsePainScoreFromText(text);
                                  if (detected != null) {
                                    setState(() => _session.painScore =
                                        detected.clamp(1, 10));
                                  }
                                },
                                voiceoverEnabled: SACAStateScope.of(context).isVoiceoverEnabled,
                                voiceoverPreamble: _painMainCardQuestion(),
                                language: SACAStateScope.of(context).selectedLanguage,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        )
                      : isVoice
                          // Other voice steps: ClinicalInputCard handles its own scroll.
                          ? ClinicalInputCard(
                              // ValueKey forces a fresh state (empty transcript) on every step.
                              key: ValueKey<int>(_currentStep),
                              showTapToSpeakLabel: false,
                              questionText: _stepQuestion(_currentStep),
                              triageService: widget.triageService,
                              accentColor: config.accentColor,
                              initialTranscript: _capturedAnswers[_currentStep] ?? '',
                              onConfirmed: _handleClinicalConfirm,
                              voiceoverEnabled: SACAStateScope.of(context).isVoiceoverEnabled,
                              language: SACAStateScope.of(context).selectedLanguage,
                            )
                          // Text / selection modes
                          : _buildStepInput(config),
                ),

                // ── Fixed bottom nav ─────────────────────────────────────────
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _currentStep == 0
                          ? null
                          : () => setState(() => _currentStep -= 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(
                        SACAStrings.tr(
                          context: context,
                          english: 'Back',
                          warlpiri: 'Rete',
                        ),
                      ),
                    ),
                    if (!isVoice)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: config.accentColor,
                        ),
                        onPressed: _goNextOrSubmit,
                        child: Text(
                          _currentStep == 3
                              ? SACAStrings.tr(
                                  context: context,
                                  english: 'Calculate Triage',
                                  warlpiri: 'Triage-nyayirni',
                                )
                              : SACAStrings.tr(
                                  context: context,
                                  english: 'Next',
                                  warlpiri: 'Karlipa',
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
                  label: Text(_bilingualPrompt(english: 'No', warlpiri: 'Yali')),
                  selected: !_isWorsening,
                  onSelected: (_) => setState(() => _isWorsening = false),
                ),
                ChoiceChip(
                  label: Text(
                    _bilingualPrompt(english: 'Yes', warlpiri: 'Yuwayi'),
                  ),
                  selected: _isWorsening,
                  onSelected: (_) => setState(() => _isWorsening = true),
                ),
              ],
            ),
          ],
        );
      case 3:
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
          ),
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
      english:
          'On a scale of 1 to 10, how would you rate your current pain intensity?',
      warlpiri:
          'Panikiki nyuntu warlu nyinami — wangu-wangu kuja, wirliya kujaka?',
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
          english:
              'Please describe your main symptoms and what is concerning you most today.',
          warlpiri: 'Ngurrju-kari-ngirli nyuntu warlu wirridi?',
        );
      case 1:
        return _bilingualPrompt(
          english:
              'Since your symptoms began, have they been improving, staying the same, or getting worse?',
          warlpiri:
              'Ngula-kari yimi-ngarrka nyinami warlalja-warnu, panu-kari yinyami?',
        );
      case 2:
        return _bilingualPrompt(
          english:
              'Are your symptoms deteriorating rapidly, or have they worsened significantly in the last few hours?',
          warlpiri: 'Yalumpu kuja kapingkilypa nyinami?',
        );
      case 3:
        return _bilingualPrompt(
          english:
              'Please list all current medications you are taking, and any known allergies including drug, food, or environmental allergies.',
          warlpiri: 'Yimi ngarrka-jarri karlipa pawuju manu yarnunjuku?',
        );
      default:
        return '';
    }
  }

  String _bilingualPrompt({required String english, required String warlpiri}) {
    final AppLanguage language = SACAStateScope.of(context).selectedLanguage;
    if (language == AppLanguage.warlpiri) {
      // Return Warlpiri only — no English prefix in Warlpiri mode.
      return warlpiri.isNotEmpty ? warlpiri : english;
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
            english: 'Selection Symptoms',
            warlpiri: 'Selection Symptoms',
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
      _session.onset = '';
      final String medsAllergies = (_capturedAnswers[3] ?? '').trim();
      _session.medications = medsAllergies;
      _session.allergies = medsAllergies;
    } else {
      _session.chiefComplaint = _chiefComplaintController.text.trim();
      _session.onset = '';
      _session.medications = _medicationsController.text.trim();
      _session.allergies = _allergiesController.text.trim();
    }
    _session.isWorsening = _isWorsening;
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
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

  void _handleClinicalConfirm(String value) {
    final String cleaned = value.trim();
    _capturedAnswers[_currentStep] = cleaned;
    if (_currentStep == 1 || _currentStep == 2) {
      _isWorsening = _parseWorsening(cleaned);
    }
    // Step 1 is the pain + symptoms-trend step. If the user mentions a number
    // in their spoken answer (e.g. "getting worse, pain is about seven out of ten")
    // automatically snap the slider to that value — no second mic needed.
    if (_currentStep == 1) {
      final int? detected = _parsePainScoreFromText(cleaned);
      if (detected != null) {
        setState(() => _session.painScore = detected.clamp(1, 10));
      }
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

// ── Physical / injury symptom catalogue ──────────────────────────────────
// Step 0: location-specific physical pain and injury only.
// Covers: sprain/strain, fractures, joint injuries, referred organ pain,
// urinary symptoms, GI bleeding, chest/abdominal organ pain.

class _SymptomEntry {
  const _SymptomEntry(this.label, this.parts);
  final String label;
  final List<String> parts;
}

const _kSymptomCatalog = <_SymptomEntry>[
  // ── Head / Neck / Face / Throat ──────────────────────────────────────
  _SymptomEntry('Headache',                          ['head']),
  _SymptomEntry('Head injury or bump',               ['head']),
  _SymptomEntry('Neck pain or stiffness',            ['head']),
  _SymptomEntry('Jaw pain',                          ['head']),
  _SymptomEntry('Facial swelling or bruising',       ['head']),
  _SymptomEntry('Eye injury or pain',                ['head']),
  _SymptomEntry('Ear pain',                          ['head']),
  _SymptomEntry('Toothache or mouth pain',           ['head']),
  _SymptomEntry('Sore throat',                       ['head']),
  _SymptomEntry('Difficulty swallowing',             ['head']),
  _SymptomEntry('Facial numbness or tingling',       ['head']),

  // ── Chest / Abdomen / Back / Pelvis / Urinary ────────────────────────
  _SymptomEntry('Sharp chest pain',                  ['body']),
  _SymptomEntry('Burning chest pain',                ['body']),
  _SymptomEntry('Rib pain or tenderness',            ['body']),
  _SymptomEntry('Heartburn',                         ['body']),
  _SymptomEntry('Upper abdominal pain',              ['body']),
  _SymptomEntry('Lower abdominal pain',              ['body']),
  _SymptomEntry('Side or flank pain',                ['body']),
  _SymptomEntry('Stomach bloating or cramping',      ['body']),
  _SymptomEntry('Groin or pelvic pain',              ['body']),
  _SymptomEntry('Upper back pain',                   ['body']),
  _SymptomEntry('Lower back pain',                   ['body']),
  _SymptomEntry('Blood in stool or black stool',     ['body']),
  _SymptomEntry('Vomiting blood',                    ['body']),
  _SymptomEntry('Blood in urine',                    ['body']),
  _SymptomEntry('Painful urination',                 ['body']),
  _SymptomEntry('Frequent urination',                ['body']),

  // ── Arms / Shoulders / Hands ──────────────────────────────────────────
  _SymptomEntry('Arm pain',                          ['left arm', 'right arm']),
  _SymptomEntry('Shoulder pain or injury',           ['left arm', 'right arm']),
  _SymptomEntry('Elbow pain or injury',              ['left arm', 'right arm']),
  _SymptomEntry('Wrist pain or sprain',              ['left arm', 'right arm']),
  _SymptomEntry('Hand or finger pain',               ['left arm', 'right arm']),
  _SymptomEntry('Arm or hand swelling',              ['left arm', 'right arm']),
  _SymptomEntry('Suspected fracture (arm)',           ['left arm', 'right arm']),
  _SymptomEntry('Arm numbness or tingling',          ['left arm', 'right arm']),

  // ── Legs / Hips / Feet ───────────────────────────────────────────────
  _SymptomEntry('Leg pain',                          ['leg']),
  _SymptomEntry('Knee pain or injury',               ['leg']),
  _SymptomEntry('Ankle pain or sprain',              ['leg']),
  _SymptomEntry('Hip pain',                          ['leg']),
  _SymptomEntry('Foot or toe pain',                  ['leg']),
  _SymptomEntry('Leg or ankle swelling',             ['leg']),
  _SymptomEntry('Calf tightness or pain',            ['leg']),
  _SymptomEntry('Suspected fracture (leg)',           ['leg']),
  _SymptomEntry('Leg numbness or tingling',          ['leg']),
];

// ── Systemic symptom catalogue — grouped by disease family ────────────────
// Step 1: body-wide symptoms organised into recognisable disease groups so
// patients immediately see the category that matches their situation.
// Covers: flu/cold, allergies, COVID-like, GI illness, skin, anxiety/panic,
// sleep disorders, neurological, and serious red-flag systemic signs.

class _SystemicCategory {
  const _SystemicCategory(this.label, this.icon, this.symptoms);
  final String label;
  final IconData icon;
  final List<String> symptoms;
}

const _kSystemicCategories = <_SystemicCategory>[
  _SystemicCategory(
    'Flu, Cold & Chest',
    Icons.sick_rounded,
    <String>[
      'Fever or high temperature',
      'Chills or shivering',
      'Body aches all over',
      'Runny or blocked nose',
      'Sneezing',
      'Cough',
      'Coughing up blood',
      'Wheezing',
      'Shortness of breath',
    ],
  ),
  _SystemicCategory(
    'Allergies & Skin',
    Icons.visibility_rounded,
    <String>[
      'Itchy or watery eyes',
      'Hives or skin welts',
      'Itchy skin',
      'Skin rash',
      'Dry or peeling skin',
    ],
  ),
  _SystemicCategory(
    'Stomach & Digestion',
    Icons.no_food_rounded,
    <String>[
      'Nausea',
      'Vomiting',
      'Diarrhoea',
      'Loss of appetite',
    ],
  ),
  _SystemicCategory(
    'Heart & Circulation',
    Icons.favorite_rounded,
    <String>[
      'Chest tightness or pressure',
      'Racing heart or palpitations',
      'Fainting or near-fainting',
      'Unexpected sweating',
    ],
  ),
  _SystemicCategory(
    'Anxiety & Panic',
    Icons.psychology_rounded,
    <String>[
      'Trembling or shaking',
      'Sudden intense fear (panic attack)',
      'Rapid shallow breathing',
    ],
  ),
  _SystemicCategory(
    'Sleep & Energy',
    Icons.bedtime_rounded,
    <String>[
      'Insomnia or trouble sleeping',
      'Excessive daytime sleepiness',
      'Loud snoring or stopping breathing in sleep',
      'Fatigue or extreme tiredness',
      'General weakness',
    ],
  ),
  _SystemicCategory(
    'Neurological',
    Icons.psychology_alt_rounded,
    <String>[
      'Dizziness or lightheadedness',
      'Confusion or disorientation',
      'Numbness or tingling (body-wide)',
      'Involuntary or abnormal movements',
      'Difficulty with coordination or walking',
      'Seizures',
    ],
  ),
  _SystemicCategory(
    'Blood Sugar',
    Icons.water_drop_rounded,
    <String>[
      'Excessive thirst',
      'Shakiness or trembling when hungry',
      'Feeling faint after skipping meals',
    ],
  ),
];

// ── Medication / Allergy catalogues ──────────────────────────────────────

const _kCommonMedications = <String>[
  'Paracetamol / Panadol',
  'Ibuprofen',
  'Aspirin',
  'Antibiotics',
  'Blood pressure medication',
  'Cholesterol medication',
  'Metformin (diabetes)',
  'Insulin',
  'Antidepressants',
  'Antihistamines',
  'Ventolin inhaler',
  'Blood thinners (Warfarin)',
  'None',
];

const _kCommonAllergies = <String>[
  'Penicillin / Antibiotics',
  'Aspirin / Ibuprofen',
  'Sulfa drugs',
  'Latex',
  'Peanuts',
  'Shellfish',
  'Dairy / Lactose',
  'Eggs',
  'Bee stings',
  'Pollen / Dust',
  'None',
];

const _kMedicationImages = <String, String>{
  'Paracetamol / Panadol':       'assets/Medicine/1. Paracetamol  Panadol.jpg',
  'Ibuprofen':                   'assets/Medicine/2. Ibuprofen.jpg',
  'Aspirin':                     'assets/Medicine/3. aspirin.jpg',
  'Antibiotics':                 'assets/Medicine/4. Amoxicillin.jpg',
  'Blood pressure medication':   'assets/Medicine/5.Blood pressure medication.jpg',
  'Cholesterol medication':      'assets/Medicine/6.Cholesterol medication.jpg',
  'Metformin (diabetes)':        'assets/Medicine/7. Metformin (diabetes).jpg',
  'Insulin':                     'assets/Medicine/8. Insulin.jpg',
  'Antidepressants':             'assets/Medicine/9. Antidepressants.jpg',
  'Antihistamines':              'assets/Medicine/10. Antihistamines.jpg',
  'Ventolin inhaler':            'assets/Medicine/11. Ventolin inhaler.jpg',
  'Blood thinners (Warfarin)':   'assets/Medicine/12. Blood thinners (Warfarin).jpg',
};

const _kAllergyImages = <String, String>{
  'Penicillin / Antibiotics': 'assets/Allergies/1. Penicillin and Antibiot 645689.jpg',
  'Aspirin / Ibuprofen':      'assets/Allergies/2.Aspirin-Ibuprofen. Clea 549817.jpg',
  'Sulfa drugs':              'assets/Allergies/3. Sulfa drugs.jpg',
  'Latex':                    'assets/Allergies/4. Latex.jpg',
  'Peanuts':                  'assets/Allergies/5. Peanuts.jpg',
  'Shellfish':                'assets/Allergies/6. Shellfish.jpg',
  'Dairy / Lactose':          'assets/Allergies/7. Dairy-Lactose.jpg',
  'Eggs':                     'assets/Allergies/8. egg.jpg',
  'Bee stings':               'assets/Allergies/9. bee.jpg',
  'Pollen / Dust':            'assets/Allergies/10. Pollen-Dust.jpg',
};

// ── Illness selection page ────────────────────────────────────────────────

class _IllnessSelectionPage extends StatefulWidget {
  const _IllnessSelectionPage({
    required this.session,
    required this.triageService,
    required this.workspace,
    required this.heroTag,
    required this.selectedBodyParts,
  });

  final TriageSession session;
  final TriageService triageService;
  final WorkspaceConfig workspace;
  final String heroTag;
  final List<String> selectedBodyParts;

  @override
  State<_IllnessSelectionPage> createState() => _IllnessSelectionPageState();
}

class _IllnessSelectionPageState extends State<_IllnessSelectionPage> {
  final Set<String> _selectedSymptoms          = <String>{};
  final Set<String> _selectedSystemicSymptoms  = <String>{};
  final Set<String> _selectedMedications       = <String>{};
  final Set<String> _selectedAllergies         = <String>{};
  // Tracks which section labels are currently collapsed (tapping header toggles).
  final Set<String> _collapsedSections         = <String>{};
  bool _showSymptomLabels                      = true;

  // Returns region groups (display name + catalog keys) for the selected parts.
  List<({String label, List<String> keys})> get _regionGroups {
    final List<({String label, List<String> keys})> groups = [];
    final Set<String> seen = <String>{};
    for (final String part in widget.selectedBodyParts) {
      final String p = part.toLowerCase().trim();
      if (p == 'head' && seen.add('head')) {
        groups.add((label: 'Head', keys: ['head']));
      }
      if ((p == 'chest' || p == 'abdominal' || p == 'hip') && seen.add('body')) {
        groups.add((label: 'Body & Chest', keys: ['body']));
      }
      if (p == 'arm' && seen.add('arm')) {
        groups.add((label: 'Arm', keys: ['left arm', 'right arm']));
      }
      if (p == 'leg' && seen.add('leg')) {
        groups.add((label: 'Leg', keys: ['leg']));
      }
    }
    return groups;
  }
  bool _isWorsening = false;
  int _currentStep = 0;

  @override
  void dispose() {
    super.dispose();
  }

  void _goBack() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentStep -= 1);
  }

  void _goNext() {
    if (_currentStep == 0) {
      if (_selectedSymptoms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SACAStrings.tr(
                context: context,
                english: 'Select at least one symptom to continue.',
                warlpiri: 'Select at least one symptom to continue.',
              ),
            ),
          ),
        );
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }

    // Step 1 (systemic) is optional — no validation needed.

    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
      return;
    }

    // Combine physical + systemic symptoms for chief complaint.
    final Set<String> allSymptoms = <String>{
      ..._selectedSymptoms,
      ..._selectedSystemicSymptoms
          .where((s) => s != 'None of the above'),
    };
    widget.session.chiefComplaint = allSymptoms.join(', ');
    widget.session.onset = '';
    widget.session.isWorsening = _isWorsening;
    widget.session.medications = _selectedMedications.isEmpty
        ? ''
        : _selectedMedications.where((s) => s != 'None').join(', ');
    widget.session.allergies = _selectedAllergies.isEmpty
        ? ''
        : _selectedAllergies.where((s) => s != 'None').join(', ');

    Navigator.of(context)
        .push<AssessmentPreOutcome>(
          MaterialPageRoute<AssessmentPreOutcome>(
            builder: (_) => PreResultNotesPage(
              session: widget.session,
              triageService: widget.triageService,
              workspace: widget.workspace,
              heroTag: widget.heroTag,
              heroIcon: Icons.touch_app_rounded,
            ),
          ),
        )
        .then((AssessmentPreOutcome? outcome) {
          if (!mounted) return;
          if (outcome == AssessmentPreOutcome.redo) {
            Navigator.of(context).pop();
          }
        });
  }

  String _stepQuestion(int step) {
    switch (step) {
      case 1:
        return _bilingualPrompt(
          english:
              'Are you experiencing any general body symptoms such as fever, fatigue, nausea, chills, or dizziness?',
          warlpiri:
              'Nyuntu ngurra-jarra ngurrju-kari nyinami — pirli-pirli, wiri-wiri, nyiya-nyiyami, kirda-kirda kuja?',
        );
      case 2:
        return _bilingualPrompt(
          english:
              'Overall, are your symptoms improving, remaining unchanged, or getting worse?',
          warlpiri:
              'Ngula-kari yimi-ngarrka nyinami warlalja-warnu, panu-kari yinyami?',
        );
      case 3:
        return _bilingualPrompt(
          english:
              'Please list all current medications and any known allergies, including drug, food, or environmental allergies.',
          warlpiri: 'Yimi ngarrka-jarri karlipa pawuju manu yarnunjuku?',
        );
      default:
        return _bilingualPrompt(
          english:
              'Please select all body areas or symptoms that are currently affecting you.',
          warlpiri:
              'Nyuntu yirdi-yirdi nyarrparaki warlu-juku nyinami — nyampuju kuja tap-im.',
        );
    }
  }

  String _painMainCardQuestion() {
    return _bilingualPrompt(
      english:
          'On a scale of 1 to 10, how would you rate your current pain intensity?',
      warlpiri:
          'Panikiki nyuntu warlu nyinami — wangu-wangu kuja, wirliya kujaka?',
    );
  }

  String _bilingualPrompt({required String english, required String warlpiri}) {
    final AppLanguage language = SACAStateScope.of(context).selectedLanguage;
    if (language == AppLanguage.warlpiri) {
      // Return Warlpiri only — no English prefix in Warlpiri mode.
      return warlpiri.isNotEmpty ? warlpiri : english;
    }
    return english;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SACAColorScheme.of(context).pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.workspace.title),
        actions: <Widget>[
          Tooltip(
            message: _showSymptomLabels ? 'Hide labels' : 'Show labels',
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(
                () => _showSymptomLabels = !_showSymptomLabels,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _showSymptomLabels
                      ? Icons.label_off_outlined
                      : Icons.label_outline_rounded,
                  color: SACAColorScheme.of(context).charcoal,
                  size: 22,
                ),
              ),
            ),
          ),
          const SACAQuickActions(),
        ],
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
                    SACAStrings.tr(
                      context: context,
                      english: 'Your Symptoms',
                      warlpiri: 'Your Symptoms',
                    ),
                    style: TextStyle(
                      fontSize: SACATriageTypography.pageHeadline,
                      fontWeight: FontWeight.w800,
                      color: SACAColorScheme.of(context).charcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    SACAStrings.tr(
                      context: context,
                      english: 'Select everything you are feeling right now.',
                      warlpiri: 'Select everything you are feeling right now.',
                    ),
                    style: TextStyle(
                      color: SACAColorScheme.of(context).secondaryText,
                      fontSize: SACATriageTypography.pageSubtitle,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: _currentStep == 0
                        ? _buildIllnessSelectionGrid()
                        : _buildQuestionFlowBody(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllnessSelectionGrid() {
    final List<({String label, List<String> keys})> groups = _regionGroups;

    // Build per-group symptom lists; each symptom appears in at most one section
    // to avoid an overwhelming repetitive list when multiple parts are selected.
    final Set<String> assigned = <String>{};
    final List<({String label, List<String> symptoms})> sections =
        <({String label, List<String> symptoms})>[];
    for (final ({String label, List<String> keys}) group in groups) {
      final List<String> groupSymptoms = <String>[];
      for (final _SymptomEntry entry in _kSymptomCatalog) {
        if (assigned.contains(entry.label)) continue;
        if (entry.parts.any((String p) => group.keys.contains(p))) {
          groupSymptoms.add(entry.label);
          assigned.add(entry.label);
        }
      }
      if (groupSymptoms.isNotEmpty) {
        sections.add((label: group.label, symptoms: groupSymptoms));
      }
    }

    // Fallback: if no body parts are selected yet, show every symptom flat.
    final List<String> flatFallback = sections.isEmpty
        ? _kSymptomCatalog.map((e) => e.label).toList()
        : <String>[];

    final bool isGrouped = sections.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _bilingualPrompt(
            english: 'Tap every symptom you are experiencing',
            warlpiri: 'Nyuntu warlu-juku kuja nyinami — tap-im nyampuju.',
          ),
          style: TextStyle(
            fontSize: SACATriageTypography.sectionLead,
            fontWeight: FontWeight.w700,
            color: SACAColorScheme.of(context).charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _bilingualPrompt(
            english: 'Select all that apply — you can choose more than one.',
            warlpiri: 'Karlipa jintangku-jintangku tap-im — panu-kari kuja nyinami.',
          ),
          style: TextStyle(
            color: SACAColorScheme.of(context).secondaryText,
            fontSize: SACATriageTypography.sectionSub,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: isGrouped
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final ({String label, List<String> symptoms}) sec
                          in sections) ...<Widget>[
                        _buildSectionHeader(sec.label),
                        if (!_collapsedSections.contains(sec.label)) ...<Widget>[
                          const SizedBox(height: 10),
                          _buildSymptomWrap(sec.symptoms),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ],
                  )
                : _buildSymptomWrap(
                    sections.isNotEmpty
                        ? sections.first.symptoms
                        : flatFallback,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (_selectedSymptoms.isNotEmpty)
              Text(
                '${_selectedSymptoms.length} selected',
                style: const TextStyle(
                  color: SACAColors.deepClinicalGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              )
            else
              const SizedBox.shrink(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _selectedSymptoms.isEmpty
                    ? SACAColors.subtleBorder
                    : widget.workspace.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _selectedSymptoms.isEmpty ? null : _goNext,
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
    );
  }

  Widget _buildSectionHeader(String label) {
    final bool isCollapsed = _collapsedSections.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (isCollapsed) {
          _collapsedSections.remove(label);
        } else {
          _collapsedSections.add(label);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: SACAColors.deepClinicalGreen.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SACAColors.deepClinicalGreen.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.label_rounded,
              size: 15,
              color: SACAColors.deepClinicalGreen,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SACAColors.deepClinicalGreen,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              size: 16,
              color: SACAColors.deepClinicalGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomWrap(List<String> symptoms,
      {Set<String>? selectionSet}) {
    final Set<String> bucket = selectionSet ?? _selectedSymptoms;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: symptoms.map((String symptom) {
        final bool selected = bucket.contains(symptom);
        final String? imagePath = _kSymptomImages[symptom];
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              bucket.remove(symptom);
            } else {
              bucket.add(symptom);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 110,
            decoration: BoxDecoration(
              color: selected
                  ? SACAColors.deepClinicalGreen.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? SACAColors.deepClinicalGreen
                    : SACAColors.subtleBorder,
                width: selected ? 2 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: selected
                      ? SACAColors.deepClinicalGreen.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: selected ? 6 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // ── Image area ──────────────────────────────────────
                ClipRRect(
                  borderRadius: _showSymptomLabels
                      ? const BorderRadius.vertical(top: Radius.circular(11))
                      : BorderRadius.circular(11),
                  child: Stack(
                    children: <Widget>[
                      if (imagePath != null)
                        Image.asset(
                          imagePath,
                          width: 110,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          width: 110,
                          height: 72,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.medical_services_outlined,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      if (!_showSymptomLabels && selected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: SACAColors.deepClinicalGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── Label area ──────────────────────────────────────
                AnimatedCrossFade(
                  firstChild: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (selected)
                          Padding(
                            padding: const EdgeInsets.only(right: 3, top: 1),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: SACAColors.deepClinicalGreen,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            symptom,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? SACAColors.deepClinicalGreen
                                  : SACAColors.charcoal,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox(width: 110, height: 0),
                  crossFadeState: _showSymptomLabels
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 220),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionFlowBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (_currentStep + 1) / 4,
              backgroundColor: SACAColorScheme.of(context).subtleBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.workspace.accentColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: _BaseCard(
            active: false,
            accentColor: widget.workspace.accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _currentStep == 2
                      ? _painMainCardQuestion()
                      : _stepQuestion(_currentStep),
                  style: TextStyle(
                    fontSize: SACATriageTypography.cardQuestion,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: SACAColorScheme.of(context).charcoal,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(child: _buildStepInput()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _goBack,
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
                        backgroundColor: widget.workspace.accentColor,
                      ),
                      onPressed: _goNext,
                      child: Text(
                        _currentStep == 3
                            ? SACAStrings.tr(
                                context: context,
                                english: 'Continue',
                                warlpiri: 'Continue',
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

  Widget _buildStepInput() {
    switch (_currentStep) {
      case 1:
        return _buildSystemicSymptomsStep();
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _PainIntensityBlock(
              value: widget.session.painScore.toDouble(),
              onChanged: (double v) {
                setState(() {
                  widget.session.painScore = v.round().clamp(1, 10);
                });
              },
            ),
            _betterWorseDividerBlock(),
            const SizedBox(height: 4),
            _betterWorseSubheading(),
            const SizedBox(height: 12),
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
      case 3:
        return _buildMedAllergyStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSystemicSymptomsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _bilingualPrompt(
              english:
                  'Tap any that apply across all categories — tap Next to skip.',
              warlpiri:
                  'Nyampuju kuja nyinami tap-im — "Next" tap-im kuja nyinami-wangu.',
            ),
            style: const TextStyle(
              color: SACAColors.secondaryText,
              fontSize: SACATriageTypography.sectionSub,
            ),
          ),
          const SizedBox(height: 20),
          for (final _SystemicCategory cat in _kSystemicCategories) ...<Widget>[
            _buildSystemicCategoryHeader(cat.label, cat.icon),
            if (!_collapsedSections.contains(cat.label)) ...<Widget>[
              const SizedBox(height: 10),
              _buildSymptomWrap(
                cat.symptoms,
                selectionSet: _selectedSystemicSymptoms,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemicCategoryHeader(String label, IconData icon) {
    final bool isCollapsed = _collapsedSections.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (isCollapsed) {
          _collapsedSections.remove(label);
        } else {
          _collapsedSections.add(label);
        }
      }),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SACAColors.deepClinicalGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: SACAColors.deepClinicalGreen),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SACAColors.charcoal,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Icon(
            isCollapsed
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_up_rounded,
            size: 18,
            color: SACAColors.deepClinicalGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildMedAllergyStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildImageOptionSection(
            heading: _bilingualPrompt(english: 'Current Medications', warlpiri: 'Pawuju Nyinami'),
            subtitle: _bilingualPrompt(english: 'Select all you are taking, or tap "None"', warlpiri: 'Tap-im nyampuju kuja nyuntu nyangu — "None" kuja wangu.'),
            options: _kCommonMedications,
            imageMap: _kMedicationImages,
            selected: _selectedMedications,
            noneUsesGrey: true,
            onToggle: (String val) => setState(() {
              if (val == 'None') {
                _selectedMedications..clear()..add('None');
              } else {
                _selectedMedications.remove('None');
                if (!_selectedMedications.remove(val)) _selectedMedications.add(val);
              }
            }),
          ),
          const SizedBox(height: 28),
          _buildImageOptionSection(
            heading: _bilingualPrompt(english: 'Known Allergies', warlpiri: 'Yarnunjuku Nyinami'),
            subtitle: _bilingualPrompt(english: 'Select all that apply, or tap "None"', warlpiri: 'Tap-im nyampuju kuja nyuntu-kurra panu — "None" kuja wangu.'),
            options: _kCommonAllergies,
            imageMap: _kAllergyImages,
            selected: _selectedAllergies,
            noneUsesGrey: true,
            onToggle: (String val) => setState(() {
              if (val == 'None') {
                _selectedAllergies..clear()..add('None');
              } else {
                _selectedAllergies.remove('None');
                if (!_selectedAllergies.remove(val)) _selectedAllergies.add(val);
              }
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageOptionSection({
    required String heading,
    required String subtitle,
    required List<String> options,
    required Map<String, String> imageMap,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
    bool noneUsesGrey = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          heading,
          style: const TextStyle(
            fontSize: SACATriageTypography.sectionLead,
            fontWeight: FontWeight.w700,
            color: SACAColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: SACATriageTypography.sectionSub,
            color: SACAColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        _buildImageOptionWrap(
          options: options,
          imageMap: imageMap,
          selected: selected,
          onToggle: onToggle,
          noneUsesGrey: noneUsesGrey,
        ),
      ],
    );
  }

  Widget _buildImageOptionWrap({
    required List<String> options,
    required Map<String, String> imageMap,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
    bool noneUsesGrey = false,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((String option) {
        final bool isOn = selected.contains(option);
        final bool isNone = option == 'None';
        final String? imagePath = imageMap[option];
        final Color accent = isNone && noneUsesGrey
            ? SACAColors.secondaryText
            : SACAColors.deepClinicalGreen;

        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 110,
            decoration: BoxDecoration(
              color: isOn
                  ? accent.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOn ? accent : SACAColors.subtleBorder,
                width: isOn ? 2 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: isOn
                      ? accent.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: isOn ? 6 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipRRect(
                  borderRadius: _showSymptomLabels
                      ? const BorderRadius.vertical(top: Radius.circular(11))
                      : BorderRadius.circular(11),
                  child: Stack(
                    children: <Widget>[
                      if (imagePath != null)
                        Image.asset(
                          imagePath,
                          width: 110,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          width: 110,
                          height: 72,
                          color: isNone
                              ? SACAColors.subtleBorder.withValues(alpha: 0.55)
                              : Colors.grey.shade200,
                          child: Icon(
                            isNone
                                ? Icons.block_rounded
                                : Icons.medical_services_outlined,
                            size: 32,
                            color: isNone
                                ? SACAColors.secondaryText
                                : Colors.grey.shade400,
                          ),
                        ),
                      if (!_showSymptomLabels && isOn)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (isOn)
                          Padding(
                            padding: const EdgeInsets.only(right: 3, top: 1),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: accent,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  isOn ? FontWeight.w700 : FontWeight.w500,
                              color: isOn ? accent : SACAColors.charcoal,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox(width: 110, height: 0),
                  crossFadeState: _showSymptomLabels
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 220),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
          _stepQuestion(2),
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
      backgroundColor: SACAColorScheme.of(context).pageBackground,
      appBar: AppBar(
        backgroundColor: SACAColorScheme.of(context).pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.workspace.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const <Widget>[SACAQuickActions()],
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
                        english:
                            'On a scale of 1 to 10, how would you rate your current pain intensity?',
                        warlpiri:
                            'Panikiki nyuntu warlu nyinami — wangu-wangu kuja, wirliya kujaka?',
                      ),
                      style: TextStyle(
                        fontSize: SACATriageTypography.sectionLead,
                        fontWeight: FontWeight.w800,
                        color: SACAColorScheme.of(context).charcoal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      SACAStrings.tr(
                        context: context,
                        english:
                            '1 — little pain · 5 — medium · 10 — unbearable',
                        warlpiri:
                            '1 — little pain · 5 — medium · 10 — unbearable',
                      ),
                      style: TextStyle(
                        color: SACAColorScheme.of(context).secondaryText,
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
                                  Navigator.of(
                                    context,
                                  ).pop(AssessmentPreOutcome.redo);
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
                                  widget.session.painScore = _sliderValue
                                      .round()
                                      .clamp(1, 10);
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
                                      )
                                      .then((AssessmentPreOutcome? outcome) {
                                        if (!context.mounted) return;
                                        if (outcome ==
                                            AssessmentPreOutcome.redo) {
                                          Navigator.of(
                                            context,
                                          ).pop(AssessmentPreOutcome.redo);
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

  // ── voiceover ──────────────────────────────────────────────────────────────
  static const String _questionEn =
      'Is there anything else you would like the clinical team to know? '
      'Please mention any additional symptoms, relevant medical history, recent travel, '
      'or concerns not covered in the previous steps. This field is optional.';

  static const String _questionWrl =
      'Nyiya-kari nyuntu kuja karlipa yimi ngarrka-jarrijiki? '
      'Warlu-kari, pawuju-kari, nyiya-kari kuja pitjiri-jarri — '
      'yimi-nyangulpa kuja wangu nyinami manu. Ngula pina-nyanu.';

  void _speak() {
    final AppLanguage lang = SACAStateScope.of(context).selectedLanguage;
    final String text =
        lang == AppLanguage.warlpiri ? _questionWrl : _questionEn;
    KokoroTtsService.speak(text, language: lang);
  }

  @override
  void initState() {
    super.initState();
    _additionalController.text = widget.session.additionalConcerns;
    // Auto-speak on page load if voiceover is enabled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && SACAStateScope.of(context).isVoiceoverEnabled) {
        _speak();
      }
    });
  }

  @override
  void dispose() {
    KokoroTtsService.stop();
    _additionalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceConfig config = widget.workspace;
    final Color accent = config.accentColor;

    return Scaffold(
      backgroundColor: SACAColorScheme.of(context).pageBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          config.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: SACAColorScheme.of(context).pageBackground,
        actions: const <Widget>[SACAQuickActions()],
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
                    style: TextStyle(
                      fontSize: SACATriageTypography.pageHeadline,
                      fontWeight: FontWeight.w800,
                      color: SACAColorScheme.of(context).charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.subtitle,
                    style: TextStyle(
                      color: SACAColorScheme.of(context).secondaryText,
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
                        backgroundColor: SACAColorScheme.of(context).subtleBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // ── Icon row: notes icon + voiceover speaker ──────
                        Row(
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
                            const Spacer(),
                            if (SACAStateScope.of(context).isVoiceoverEnabled)
                              Tooltip(
                                message: 'Read question aloud',
                                child: InkWell(
                                  onTap: _speak,
                                  borderRadius: BorderRadius.circular(99),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      color: accent,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                                        'Nyiya-kari — warlu-kari nyuntu kuja '
                                        'yimi ngarrka-jarrijiki?',
                                  ),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: SACATriageTypography.cardQuestion,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    color: SACAColorScheme.of(context).charcoal,
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
                                        'Wangu-kari — yimi-kari kuja '
                                        'wangurnu manu.',
                                  ),
                                  style: TextStyle(
                                    color: SACAColorScheme.of(context).secondaryText,
                                    fontSize: SACATriageTypography.sectionSub,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Flexible(
                                  child: TextField(
                                    controller: _additionalController,
                                    minLines: 4,
                                    maxLines: 6,
                                    textAlignVertical: TextAlignVertical.top,
                                    cursorColor: accent,
                                    decoration: InputDecoration(
                                      hintText: SACAStrings.tr(
                                        context: context,
                                        english: 'Optional — type here…',
                                        warlpiri: 'Wangu-kari — nyampuju wangka…',
                                      ),
                                      filled: true,
                                      fillColor: SACAColorScheme.of(context).inputFill,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: SACAColorScheme.of(context).subtleBorder,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: SACAColorScheme.of(context).subtleBorder,
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
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(
                                            context,
                                          ).pop(AssessmentPreOutcome.redo);
                                        },
                                        icon: const Icon(Icons.replay_rounded),
                                        label: Text(
                                          SACAStrings.tr(
                                            context: context,
                                            english: 'Redo assessment',
                                            warlpiri: 'Yimi-ngurlu jarri',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
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
                                            warlpiri: 'Triage kiji-nyayirni',
                                          ),
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

class _ResultSummaryPageState extends State<ResultSummaryPage>
    with SingleTickerProviderStateMixin {
  late Future<TriageApiResult> _future;
  bool _initialised   = false;
  bool _didPlayEntry  = false;
  bool _didSpeak      = false;          // guard: auto-speak result only once
  TriageApiResult? _loadedResult;       // kept for the AppBar replay button
  Color _actionColor = const Color(0xFF1A5241);
  late final AnimationController _entryController;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _planFade;
  late final Animation<Offset> _planSlide;
  late final Animation<double> _detailsFade;
  late final Animation<Offset> _detailsSlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
          ),
        );
    _planFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.22, 0.72, curve: Curves.easeOutCubic),
    );
    _planSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.22, 0.72, curve: Curves.easeOutCubic),
          ),
        );
    _detailsFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.44, 1.0, curve: Curves.easeOutCubic),
    );
    _detailsSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.44, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    KokoroTtsService.stop();
    _entryController.dispose();
    super.dispose();
  }

  /// Compose a natural-language summary of the result and speak it.
  void _speakResult(TriageApiResult result) {
    final AppLanguage lang = SACAStateScope.of(context).selectedLanguage;
    final String text =
        'Assessment complete. ${result.topCondition}. '
        'Priority level: ${result.triageLevel}. '
        '${result.recommendation}';
    KokoroTtsService.speak(text, language: lang);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final AppLanguage selectedLanguage = SACAStateScope.of(
      context,
    ).selectedLanguage;
    _future = widget.apiResult != null
        ? Future<TriageApiResult>.value(widget.apiResult!)
        : widget.triageService.submitSession(
            widget.session,
            language: selectedLanguage,
          );
  }

  @override
  Widget build(BuildContext context) {
    final bool voiceoverOn = SACAStateScope.of(context).isVoiceoverEnabled;

    return Scaffold(
      backgroundColor: SACAColorScheme.of(context).pageBackground,
      appBar: AppBar(
        backgroundColor: SACAColorScheme.of(context).pageBackground,
        elevation: 0,
        title: Text(
          SACAStrings.tr(
            context: context,
            english: 'Clinical Dashboard',
            warlpiri: 'Yimi Triage Kiji',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        actions: <Widget>[
          if (voiceoverOn && _loadedResult != null)
            Tooltip(
              message: 'Read results aloud',
              child: IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () => _speakResult(_loadedResult!),
              ),
            ),
          const SACAQuickActions(),
        ],
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
                builder: (BuildContext context, AsyncSnapshot<TriageApiResult> snapshot) {
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
                  final Color resolvedColor = TriagePresentation.colorForLevel(
                    result.triageLevel,
                  );
                  final AppLanguage appLang = SACAStateScope.of(
                    context,
                  ).selectedLanguage;
                  final String languageBadge = appLang == AppLanguage.warlpiri
                      ? 'Warlpiri (wbp)'
                      : 'English';

                  // Store result for the AppBar replay button and auto-speak.
                  if (_loadedResult != result) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _loadedResult = result);
                      if (!_didSpeak && voiceoverOn) {
                        _didSpeak = true;
                        _speakResult(result);
                      }
                    });
                  }

                  if (_actionColor != resolvedColor) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _actionColor = resolvedColor);
                    });
                  }
                  if (!_didPlayEntry) {
                    _didPlayEntry = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _entryController.forward(from: 0);
                    });
                  }

                  final Widget headerWidget = FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: _TriageHeader(
                        triageLevel:    result.triageLevel,
                        topCondition:   result.topCondition,
                        languageBadge:  languageBadge,
                        confidence:     result.confidence,
                        top3Symptoms:   result.top3Symptoms,
                        recommendation: result.recommendation,
                      ),
                    ),
                  );

                  final Widget planWidget = FadeTransition(
                    opacity: _planFade,
                    child: SlideTransition(
                      position: _planSlide,
                      child: _ActionPlanBox(
                        triageLevel: result.triageLevel,
                        recommendation: result.recommendation,
                      ),
                    ),
                  );

                  final Widget detailsWidget = FadeTransition(
                    opacity: _detailsFade,
                    child: SlideTransition(
                      position: _detailsSlide,
                      child: _AssessmentDetailsTile(
                        transcript:    result.transcriptFinal,
                        rawTranscript: result.warlpiriRawTranscript,
                        painScore:     widget.session.painScore.clamp(1, 10),
                        symptoms:      result.top3Symptoms,
                      ),
                    ),
                  );

                  /// Single vertical stack on all widths: escalation → outcome →
                  /// actions → supporting details. Easier to scan than split panes.
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: <Widget>[
                      if (result.escalationTriggered) ...<Widget>[
                        const _EscalationBanner(),
                        const SizedBox(height: 16),
                      ],
                      headerWidget,
                      const SizedBox(height: 20),
                      planWidget,
                      const SizedBox(height: 16),
                      detailsWidget,
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
