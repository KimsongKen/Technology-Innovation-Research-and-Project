import 'package:flutter/material.dart';

import '../core/enums/app_language.dart';
import '../core/enums/report_mode.dart';
import '../core/language/language_keys.dart';
import '../core/language/language_service.dart';
import '../core/theme/saca_colors.dart';
import '../models/triage_session.dart';
import '../services/speech_input_service.dart';
import '../services/speech_output_service.dart';
import '../services/triage_service.dart';
import '../state/saca_state_scope.dart';
import '../widgets/base_card.dart';
import '../widgets/speak_button.dart';
import 'result_summary_page.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.mode,
    required this.heroTag,
    required this.triageService,
    required this.speechInputService,
    required this.speechOutputService,
  });

  final ReportMode mode;
  final String heroTag;
  final TriageService triageService;
  final SpeechInputService speechInputService;
  final SpeechOutputService speechOutputService;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _chiefComplaintController =
      TextEditingController();
  final TextEditingController _onsetController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  late final TriageSession _session;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  int _currentStep = 0;
  bool _isWorsening = false;
  bool _isRapidlyWorsening = false;
  bool _isListening = false;
  String _liveTranscript = '';
  String _voiceFeedback = '';
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
      isRapidlyWorsening: false,
      medications: '',
      allergies: '',
      painLocation: <String>[],
    );
  }

  @override
  void dispose() {
    widget.speechInputService.cancelListening();
    _pulseController.dispose();
    _chiefComplaintController.dispose();
    _onsetController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceConfig config = _workspaceConfig();

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
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _t(L.pointToPain),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: SACAColors.charcoal,
                    ),
                  ),
                ),
                SpeakButton(
                  text: _t(L.pointToPain),
                  speechOutputService: widget.speechOutputService,
                  tooltip: _t(L.readAloud),
                ),
              ],
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
                              ? SACAColors.warlpiriOrange.withValues(alpha: 0.08)
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
                onPressed: _submitSelection,
                child: Text(_t(L.calculate)),
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
    final String question = _stepQuestion(_currentStep);

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
        ],
        Expanded(
          child: BaseCard(
            active: false,
            accentColor: config.accentColor,
            child: Column(
              crossAxisAlignment: showVoicePrompt
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: <Widget>[
                if (showVoicePrompt) ...<Widget>[
                  Text(
                    _t(L.tapToSpeak),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: config.accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        question,
                        textAlign: showVoicePrompt
                            ? TextAlign.center
                            : TextAlign.start,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: SACAColors.charcoal,
                        ),
                      ),
                    ),
                    SpeakButton(
                      text: question,
                      speechOutputService: widget.speechOutputService,
                      tooltip: _t(L.readAloud),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: showVoicePrompt
                      ? _buildVoiceCaptureArea(config)
                      : _buildStepInput(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _currentStep == 0
                          ? null
                          : () => setState(() => _currentStep -= 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(_t(L.back)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: config.accentColor,
                      ),
                      onPressed:
                          showVoicePrompt &&
                              !_capturedVoiceSteps.contains(_currentStep)
                          ? null
                          : _goNextOrSubmit,
                      child: Text(
                        _currentStep == 4 ? _t(L.calculate) : _t(L.next),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ScaleTransition(
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
                    color: config.accentColor.withValues(
                      alpha: _isListening ? 0.18 : 0.1,
                    ),
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
                      child: Icon(
                        _isListening ? Icons.hearing_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isListening ? _t(L.listening) : _t(L.tapMicToAnswer),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: config.accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SACAColors.subtleBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _t(L.heard),
                    style: const TextStyle(
                      color: SACAColors.secondaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _liveTranscript.isEmpty
                        ? _t(L.noSpeechDetected)
                        : _liveTranscript,
                    style: const TextStyle(
                      color: SACAColors.charcoal,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_voiceFeedback.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      _voiceFeedback,
                      style: const TextStyle(
                        color: SACAColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInput() {
    switch (_currentStep) {
      case 0:
        return _inputField(
          controller: _chiefComplaintController,
          hintText: _t(L.describeSymptomsHint),
        );
      case 1:
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ChoiceChip(
              label: Text(_t(L.gettingBetter)),
              selected: !_isWorsening,
              onSelected: (_) => setState(() => _isWorsening = false),
            ),
            ChoiceChip(
              label: Text(_t(L.gettingWorse)),
              selected: _isWorsening,
              onSelected: (_) => setState(() => _isWorsening = true),
            ),
          ],
        );
      case 2:
        return _inputField(
          controller: _onsetController,
          hintText: _t(L.onsetHint),
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _t(L.rapidlyWorsening),
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
                  label: Text(_t(L.no)),
                  selected: !_isRapidlyWorsening,
                  onSelected: (_) =>
                      setState(() => _isRapidlyWorsening = false),
                ),
                ChoiceChip(
                  label: Text(_t(L.yes)),
                  selected: _isRapidlyWorsening,
                  onSelected: (_) =>
                      setState(() => _isRapidlyWorsening = true),
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
              hintText: _t(L.medications),
            ),
            const SizedBox(height: 10),
            _inputField(
              controller: _allergiesController,
              hintText: _t(L.allergies),
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
        return _t(L.qSymptoms);
      case 1:
        return _t(L.qBetterWorse);
      case 2:
        return _t(L.qWhenStart);
      case 3:
        return _t(L.qWorseQuick);
      case 4:
        return _t(L.qMedAllergy);
      default:
        return '';
    }
  }

  WorkspaceConfig _workspaceConfig() {
    switch (widget.mode) {
      case ReportMode.voice:
        return WorkspaceConfig(
          title: _t(L.voice),
          subtitle: _t(L.voiceFlowSubtitle),
          accentColor: SACAColors.deepClinicalGreen,
        );
      case ReportMode.selection:
        return WorkspaceConfig(
          title: _t(L.selection),
          subtitle: _t(L.selectionFlowSubtitle),
          accentColor: SACAColors.earthClay,
        );
      case ReportMode.text:
        return WorkspaceConfig(
          title: _t(L.text),
          subtitle: _t(L.textFlowSubtitle),
          accentColor: SACAColors.warningRedBrown,
        );
    }
  }

  String _t(String key) {
    final AppLanguage language = SACAStateScope.of(context).selectedLanguage;
    return LanguageService.get(language, key);
  }

  void _goNextOrSubmit() {
    _session.chiefComplaint = _chiefComplaintController.text.trim();
    _session.onset = _onsetController.text.trim();
    _session.medications = _medicationsController.text.trim();
    _session.allergies = _allergiesController.text.trim();
    _session.isWorsening = _isWorsening;
    _session.isRapidlyWorsening = _isRapidlyWorsening;

    if (_currentStep < 4) {
      setState(() {
        _currentStep += 1;
        if (widget.mode == ReportMode.voice) {
          _liveTranscript = _transcriptForStep(_currentStep);
          _voiceFeedback = '';
        }
      });
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultSummaryPage(
          session: _session,
          speechOutputService: widget.speechOutputService,
        ),
      ),
    );
  }

  Future<void> _submitSelection() async {
    await widget.triageService.sendSelectionPayload(_session.painLocation);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultSummaryPage(
          session: _session,
          speechOutputService: widget.speechOutputService,
        ),
      ),
    );
  }

  Future<void> _captureVoiceStep() async {
    if (_isListening) {
      await widget.speechInputService.stopListening();
      _finishVoiceCapture();
      return;
    }

    final bool available = await widget.speechInputService.initialize();
    if (!available) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceFeedback = _t(L.speechUnavailable);
      });
      return;
    }

    setState(() {
      _isListening = true;
      _liveTranscript = _transcriptForStep(_currentStep);
      _voiceFeedback = '';
    });
    _pulseController.repeat(reverse: true);

    final bool didStart = await widget.speechInputService.startListening(
      localeId: _localeIdForCurrentLanguage(),
      onResult: (String words, bool isFinal) {
        if (!mounted) {
          return;
        }
        setState(() {
          _liveTranscript = words;
          _voiceFeedback = isFinal ? _t(L.voiceCaptured) : '';
        });
        _applyTranscriptToCurrentStep(words);
        if (isFinal) {
          _finishVoiceCapture();
        }
      },
    );

    if (!didStart && mounted) {
      setState(() {
        _isListening = false;
        _voiceFeedback = widget.speechInputService.lastError.isEmpty
            ? _t(L.speechUnavailable)
            : widget.speechInputService.lastError;
      });
      _stopPulseAnimation();
    }
  }

  void _finishVoiceCapture() {
    _stopPulseAnimation();
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      if (_liveTranscript.trim().isNotEmpty) {
        _capturedVoiceSteps.add(_currentStep);
        _voiceFeedback = _t(L.voiceCaptured);
      } else {
        _voiceFeedback = _t(L.noSpeechDetected);
      }
    });
  }

  void _applyTranscriptToCurrentStep(String words) {
    final String cleanWords = words.trim();
    if (cleanWords.isEmpty) {
      return;
    }

    switch (_currentStep) {
      case 0:
        _chiefComplaintController.text = cleanWords;
        break;
      case 1:
        final String lowerWords = cleanWords.toLowerCase();
        _isWorsening = lowerWords.contains('worse') ||
            lowerWords.contains('getting worse') ||
            lowerWords.contains('bad');
        break;
      case 2:
        _onsetController.text = cleanWords;
        break;
      case 3:
        final String lowerWords = cleanWords.toLowerCase();
        _isRapidlyWorsening = lowerWords.contains('yes') ||
            lowerWords.contains('quick') ||
            lowerWords.contains('rapid') ||
            lowerWords.contains('fast');
        break;
      case 4:
        final RegExp allergySplitPattern = RegExp(
          r'\ballerg(?:y|ies)\b',
          caseSensitive: false,
        );
        final List<String> segments = cleanWords
            .split(allergySplitPattern)
            .map((String part) => part.trim())
            .where((String part) => part.isNotEmpty)
            .toList();
        if (segments.length > 1) {
          _medicationsController.text = segments.first;
          _allergiesController.text = segments.sublist(1).join(' ');
        } else {
          _medicationsController.text = cleanWords;
          _allergiesController.text = cleanWords;
        }
        break;
    }
  }

  String _transcriptForStep(int step) {
    switch (step) {
      case 0:
        return _chiefComplaintController.text.trim();
      case 1:
        return _isWorsening ? _t(L.gettingWorse) : _t(L.gettingBetter);
      case 2:
        return _onsetController.text.trim();
      case 3:
        return _isRapidlyWorsening ? _t(L.yes) : _t(L.no);
      case 4:
        final String medications = _medicationsController.text.trim();
        final String allergies = _allergiesController.text.trim();
        return <String>[medications, allergies]
            .where((String value) => value.isNotEmpty)
            .join(' | ');
      default:
        return '';
    }
  }

  String _localeIdForCurrentLanguage() {
    final AppLanguage language = SACAStateScope.of(context).selectedLanguage;
    switch (language) {
      case AppLanguage.english:
        return 'en_AU';
      case AppLanguage.warlpiri:
        return 'en_AU';
    }
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.reset();
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
