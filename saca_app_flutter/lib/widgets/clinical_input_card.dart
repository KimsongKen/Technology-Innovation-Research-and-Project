part of '../main.dart';

class ClinicalInputCard extends StatefulWidget {
  const ClinicalInputCard({
    super.key,
    required this.questionText,
    required this.triageService,
    required this.accentColor,
    required this.initialTranscript,
    required this.onConfirmed,
    this.onTranscriptChanged,
    this.voiceoverEnabled = false,
    this.voiceoverPreamble,
    this.language = AppLanguage.english,
    /// When false, hides the "Tap to Speak" label row (e.g. when it has been
    /// moved to the page-level header so it appears at the top of the screen).
    this.showTapToSpeakLabel = true,
    /// When true, the card returns its inner Column directly without the
    /// LayoutBuilder / SingleChildScrollView wrapper. Use this when the card
    /// is already inside an ancestor SingleChildScrollView (e.g. pain step).
    this.shrinkWrap = false,
  });

  final String questionText;
  final TriageService triageService;
  final Color accentColor;
  final String initialTranscript;
  final ValueChanged<String> onConfirmed;
  /// Optional callback fired whenever the transcript text changes — either
  /// after STT returns a result, or when the user manually edits the field.
  /// Use this to react to partial results in real-time (e.g. live pain slider).
  final ValueChanged<String>? onTranscriptChanged;
  /// When true the question is read aloud via TTS when the card appears
  /// and whenever the question text changes.
  final bool voiceoverEnabled;
  /// Optional heading spoken BEFORE [questionText] (e.g. pain intensity heading).
  final String? voiceoverPreamble;
  /// Current app language — used to pick the most natural TTS voice.
  final AppLanguage language;
  final bool showTapToSpeakLabel;
  final bool shrinkWrap;

  @override
  State<ClinicalInputCard> createState() => _ClinicalInputCardState();
}

class _ClinicalInputCardState extends State<ClinicalInputCard>
    with SingleTickerProviderStateMixin {
  /// Called from the page-level "Tap to Speak" header pill.
  void toggleRecording() {
    _toggleRecording();
  }

  /// Replays the current question when voiceover is enabled.
  void replayQuestion() {
    _speak(widget.questionText);
  }

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

  // ── Streaming / interim transcription ──────────────────────────────────────
  // Every [_kChunkInterval] seconds while recording, the current audio is
  // flushed to the backend and a partial transcript is shown immediately.
  // This gives the user live feedback without waiting for a full recording.
  static const Duration _kChunkInterval = Duration(seconds: 4);
  Timer? _chunkTimer;
  String _partialAccumulated = ''; // running transcript across all chunks
  bool _isChunkProcessing  = false; // guards against overlapping chunk calls

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

    if (widget.voiceoverEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak(widget.questionText);
      });
    }
  }

  /// Speak [questionText] via KokoroTtsService (Edge TTS → flutter_tts fallback).
  ///
  /// [voiceoverPreamble] is passed separately so that bilingual strings
  /// (format: "English / Warlpiri") are never incorrectly concatenated before
  /// the service splits them per language.
  void _speak(String questionText) {
    if (!widget.voiceoverEnabled || questionText.isEmpty) return;
    KokoroTtsService.speak(
      questionText,
      preamble: widget.voiceoverPreamble,
      language: widget.language,
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
    // Re-speak if voiceover toggled on or question text changes.
    if (widget.voiceoverEnabled) {
      if (!oldWidget.voiceoverEnabled ||
          widget.questionText != oldWidget.questionText ||
          widget.voiceoverPreamble != oldWidget.voiceoverPreamble) {
        _speak(widget.questionText);
      }
    } else if (oldWidget.voiceoverEnabled) {
      KokoroTtsService.stop();
    }
  }

  @override
  void dispose() {
    _chunkTimer?.cancel();
    KokoroTtsService.stop();
    _pulseController.dispose();
    _recorder.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  // ── Chunk-based interim transcription ──────────────────────────────────────
  // Fires every [_kChunkInterval] while the user is recording. It stops the
  // current WAV, transcribes it, restarts recording into a fresh file, and
  // appends the new words to the displayed transcript — giving live feedback
  // and dramatically reducing the wait after the user taps Stop.
  Future<void> _processChunk() async {
    if (!_isRecording || _isChunkProcessing || !mounted) return;
    _isChunkProcessing = true;

    try {
      // Pause the recorder and grab the current file.
      await _recorder.stop();
      final String? chunkPath = _audioPath;

      // Immediately restart recording into a new file so audio is never lost.
      final io.Directory tempDir = await getTemporaryDirectory();
      final String newPath =
          '${tempDir.path}/saca_chunk_${DateTime.now().millisecondsSinceEpoch}.wav';
      _audioPath = newPath;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: newPath,
      );

      if (chunkPath == null) { _isChunkProcessing = false; return; }
      final io.File chunkFile = io.File(chunkPath);
      if (!await chunkFile.exists() || await chunkFile.length() < 2000) {
        _isChunkProcessing = false;
        return; // too short — skip
      }

      final AppLanguage lang = SACAStateScope.of(context).selectedLanguage;
      final String langCode = lang == AppLanguage.warlpiri ? 'wbp' : 'en';
      final String partial = await widget.triageService
          .transcribeAudio(chunkFile, languageCode: langCode);

      if (partial.trim().isNotEmpty && mounted) {
        final String sep = _partialAccumulated.isEmpty ? '' : ' ';
        _partialAccumulated += '$sep${partial.trim()}';
        setState(() {
          _transcriptController.text = _partialAccumulated;
          _transcriptController.selection = TextSelection.collapsed(
              offset: _transcriptController.text.length);
        });
        widget.onTranscriptChanged?.call(_partialAccumulated);
      }
    } catch (_) {
      // Chunk failed — silently continue; full transcription on Stop covers it.
    } finally {
      _isChunkProcessing = false;
    }
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

    final io.Directory tempDir = await getTemporaryDirectory();
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

    // Reset interim accumulator for this new recording session.
    _partialAccumulated = '';

    setState(() {
      _isRecording = true;
      _recordingStartedAt = DateTime.now();
    });
    _pulseController.repeat(reverse: true);

    // Start the chunk timer — fires every [_kChunkInterval] to send partial
    // audio to the backend and update the transcript live.
    _chunkTimer?.cancel();
    _chunkTimer = Timer.periodic(_kChunkInterval, (_) => _processChunk());
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

    // Cancel chunk timer before stopping so no chunk fires during final upload.
    _chunkTimer?.cancel();
    _chunkTimer = null;

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

    final io.File recordedFile = io.File(path);
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
    // Notify parent of the new transcript so it can react immediately
    // (e.g. move the pain slider before the user taps Confirm).
    if (mounted) {
      widget.onTranscriptChanged?.call(_transcriptController.text);
    }
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

    final Widget innerColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // "Tap to Speak" label row — hidden when moved to the page-level header
        if (widget.showTapToSpeakLabel) ...<Widget>[
          Row(
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
              if (widget.voiceoverEnabled) ...<Widget>[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Replay question',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _speak(widget.questionText),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 20,
                        color: widget.accentColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        Text(
          widget.questionText,
          style: TextStyle(
            fontSize: SACATriageTypography.voiceQuestion,
            fontWeight: FontWeight.w900,
            height: 1.2,
            color: SACAColorScheme.of(context).charcoal,
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
            style: TextStyle(
              color: SACAColorScheme.of(context).secondaryText,
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
          onChanged: (String v) {
            setState(() {});
            widget.onTranscriptChanged?.call(v);
          },
          decoration: InputDecoration(
            hintText: SACAStrings.tr(
              context: context,
              english: 'Transcript will appear here...',
              warlpiri: 'Transcript nyampu kuja...',
            ),
            filled: true,
            fillColor: SACAColorScheme.of(context).inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                  color: SACAColorScheme.of(context).subtleBorder),
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
                  warlpiri: 'Yuwayi, karlipa-jarri',
                ),
              ),
            ),
          ),
      ],
    );

    // shrinkWrap=true: caller owns the scroll context (e.g. inside a pain-step
    // SingleChildScrollView). Return the bare column so Flutter can measure it.
    if (widget.shrinkWrap) return innerColumn;

    // Default: own scrollable container that fills available height.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: innerColumn,
          ),
        );
      },
    );
  }
}
