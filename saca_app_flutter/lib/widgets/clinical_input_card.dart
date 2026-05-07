part of '../main.dart';

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
  bool _permissionDenied = false;
  bool _permissionSuggestSettings = false;
  int _micDenialCount = 0;
  DateTime? _recordingStartedAt;

  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _transcriptController = TextEditingController(text: widget.initialTranscript);
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

  Future<void> _showOpenSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Microphone blocked'),
          content: const Text(
            'Microphone access is turned off for this app. Open Settings, '
            'find SACA, and enable the microphone permission.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await AppSettings.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _ensureMicrophonePermission() async {
    final bool granted = await _recorder.hasPermission(request: true);
    if (granted) {
      setState(() {
        _permissionDenied = false;
        _permissionSuggestSettings = false;
        _micDenialCount = 0;
      });
      return true;
    }

    _micDenialCount++;
    final bool suggestStrong = _micDenialCount >= 2;
    setState(() {
      _permissionDenied = true;
      _permissionSuggestSettings = suggestStrong;
    });

    if (!mounted) return false;

    if (suggestStrong) {
      await _showOpenSettingsDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            SACAStrings.tr(
              context: context,
              english:
                  'Microphone is required to record. Tap Allow if asked, or open Settings to enable the mic for this app.',
              warlpiri:
                  'Microphone marda record-ku. Allow manu Settings-ku mic on.',
            ),
          ),
          action: SnackBarAction(
            label: SACAStrings.tr(
              context: context,
              english: 'Settings',
              warlpiri: 'Settings',
            ),
            onPressed: AppSettings.openAppSettings,
          ),
        ),
      );
    }
    return false;
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }

    final bool ok = await _ensureMicrophonePermission();
    if (!ok) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
        '${tempDir.path}/saca_${DateTime.now().millisecondsSinceEpoch}.wav';
    _audioPath = filePath;

    await _recorder.start(
      // Match backend STT expectations (16kHz mono WAV) to avoid low-signal
      // artifacts and improve transcription consistency.
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _audioPath!,
    );

    setState(() {
      _isRecording = true;
      _recordingStartedAt = DateTime.now();
    });
    _pulseController.repeat(reverse: true);
  }

  void _showZeroByteError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          SACAStrings.tr(
            context: context,
            english:
                'No audio was captured (0 bytes). Tap the mic, speak clearly, then tap again to stop.',
            warlpiri:
                'Wangka nyampu capture (0 bytes). Tap mic, speak, tap stop.',
          ),
        ),
      ),
    );
  }

  Future<void> _stopAndTranscribe() async {
    if (!_isRecording) return;

    setState(() => _isProcessing = true);
    _pulseController.stop();
    _pulseController.reset();

    final AppLanguage sttLanguage = SACAStateScope.of(context).selectedLanguage;
    final String sttLangCode = sttLanguage == AppLanguage.warlpiri ? 'wbp' : 'en';

    final Duration recordedFor = _recordingStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_recordingStartedAt!);
    await _recorder.stop();
    _recordingStartedAt = null;

    // Very short captures on emulator/desktop are often valid WAV files with
    // near-silence, which backend STT correctly rejects as 422.
    if (recordedFor < const Duration(milliseconds: 1200)) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SACAStrings.tr(
                context: context,
                english:
                    'Recording was too short. Hold the mic for at least 1-2 seconds, then tap again to stop.',
                warlpiri: 'Recording short. Hold mic 1-2 seconds, then stop.',
              ),
            ),
          ),
        );
      }
      return;
    }

    final String? path = _audioPath;
    if (path == null || path.trim().isEmpty) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SACAStrings.tr(
                context: context,
                english: 'Recording did not produce a file path. Please try again.',
                warlpiri: 'Recording path nyampu. Try again.',
              ),
            ),
          ),
        );
      }
      return;
    }

    final File recordedFile = File(path);
    final bool exists = await recordedFile.exists();
    if (!exists) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SACAStrings.tr(
                context: context,
                english: 'Recording file was not found. Please try again.',
                warlpiri: 'Recording file nyampu. Try again.',
              ),
            ),
          ),
        );
      }
      return;
    }

    final int fileSize = await recordedFile.length();
    if (fileSize <= 0) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      _showZeroByteError();
      return;
    }

    String transcript = '';
    try {
      transcript = await widget.triageService.transcribeAudio(
        recordedFile,
        languageCode: sttLangCode,
      );
    } catch (e) {
      transcript = '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SACAStrings.tr(
                context: context,
                english: 'Transcription failed: $e',
                warlpiri: 'Transcription fail: $e',
              ),
            ),
          ),
        );
      }
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

  String _permissionHintText() {
    if (_permissionSuggestSettings) {
      return SACAStrings.tr(
        context: context,
        english:
            'Microphone still blocked. Tap “Open app settings” below or enable the mic in Android Settings → Apps → SACA → Permissions.',
        warlpiri: 'Microphone block. Settings → Apps → SACA → Permissions.',
      );
    }
    if (_permissionDenied) {
      return SACAStrings.tr(
        context: context,
        english: 'Microphone permission was denied. Tap the mic again to retry.',
        warlpiri: 'Microphone deny. Tap mic again.',
      );
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool canConfirm =
        !_isProcessing && _transcriptController.text.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  SACAStrings.tr(
                    context: context,
                    english: 'Tap to Speak',
                    warlpiri: 'Nyangkura-pinyi',
                  ),
                  style: TextStyle(
                    fontSize: SACATriageTypography.voiceCta,
                    fontWeight: FontWeight.w900,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.questionText,
                  style: const TextStyle(
                    fontSize: SACATriageTypography.voiceQuestion,
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
                              color: Colors.black.withValues(alpha: _isRecording ? 0.22 : 0.12),
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
                            : _permissionHintText(),
                    style: const TextStyle(
                      color: SACAColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_permissionSuggestSettings && !_isRecording && !_isProcessing) ...<Widget>[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: AppSettings.openAppSettings,
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                        SACAStrings.tr(
                          context: context,
                          english: 'Open app settings',
                          warlpiri: 'Open app settings',
                        ),
                      ),
                    ),
                  ),
                ],
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
                      borderSide: BorderSide(color: widget.accentColor, width: 2),
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
            ),
          ),
        );
      },
    );
  }
}
