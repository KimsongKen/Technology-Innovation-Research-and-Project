import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechInputService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String _lastError = '';

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;
  String get lastError => _lastError;

  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    _isInitialized = await _speechToText.initialize(
      onError: _handleError,
      onStatus: _handleStatus,
    );
    return _isInitialized;
  }

  Future<bool> startListening({
    required void Function(String words, bool isFinal) onResult,
    String localeId = 'en_AU',
  }) async {
    final bool available = await initialize();
    if (!available) {
      _lastError = 'Speech recognition is unavailable on this device.';
      return false;
    }

    _lastError = '';
    _lastWords = '';
    _isListening = true;

    await _speechToText.listen(
      localeId: localeId,
      listenMode: ListenMode.confirmation,
      partialResults: true,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 20),
      onResult: (SpeechRecognitionResult result) {
        _lastWords = result.recognizedWords.trim();
        onResult(_lastWords, result.finalResult);
      },
    );
    return true;
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _isListening = false;
  }

  Future<void> cancelListening() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
    _isListening = false;
  }

  void _handleError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;
    _isListening = false;
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }
}
