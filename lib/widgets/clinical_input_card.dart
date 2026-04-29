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
  bool _permissionError = false;

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

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }

    final bool hasPermission = await _recorder.hasPermission(request: true);
    if (!hasPermission) {
      setState(() => _permissionError = true);
      return;
    }
    setState(() => _permissionError = false);

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
        '${tempDir.path}/saca_${DateTime.now().millisecondsSinceEpoch}.wav';
    _audioPath = filePath;

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
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      return;
    }

    final File recordedFile = File(path);
    if (!await recordedFile.exists()) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      return;
    }

    final int fileSize = await recordedFile.length();
    if (fileSize <= 0) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      return;
    }

    String transcript = '';
    try {
      transcript = await widget.triageService.transcribeAudio(recordedFile);
    } catch (_) {
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
                    : (_permissionError ? 'Microphone permission denied.' : ''),
            style: const TextStyle(
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
              borderSide: BorderSide(color: widget.accentColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_transcriptController.text.trim().isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed:
                  canConfirm ? () => widget.onConfirmed(_transcriptController.text.trim()) : null,
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
