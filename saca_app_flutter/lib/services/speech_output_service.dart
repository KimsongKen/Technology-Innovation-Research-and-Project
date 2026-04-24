import 'package:flutter_tts/flutter_tts.dart';

class SpeechOutputService {
  final FlutterTts _flutterTts = FlutterTts();
  String _lastSpokenText = '';
  bool _isInitialized = false;

  String get lastSpokenText => _lastSpokenText;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage('en-AU');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    final String trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    await initialize();
    _lastSpokenText = trimmedText;
    await _flutterTts.stop();
    await _flutterTts.speak(trimmedText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
