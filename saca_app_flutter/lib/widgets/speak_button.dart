import 'package:flutter/material.dart';

import '../services/speech_output_service.dart';

class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    required this.speechOutputService,
    this.tooltip = 'Read aloud',
  });

  final String text;
  final SpeechOutputService speechOutputService;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => speechOutputService.speak(text),
      icon: const Icon(Icons.volume_up_rounded),
    );
  }
}
