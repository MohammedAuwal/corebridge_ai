import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return false;

    _isInitialized = await _speech.initialize();
    return _isInitialized;
  }

  /// Starts listening. onResult fires repeatedly with partial text as the
  /// user speaks; isFinal is true on the last update for that utterance.
  Future<bool> startListening({
    required void Function(String recognizedText, bool isFinal) onResult,
  }) async {
    final ready = await _ensureInitialized();
    if (!ready) return false;

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
    return true;
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  void dispose() {
    _speech.cancel();
  }
}
