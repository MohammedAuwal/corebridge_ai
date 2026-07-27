import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps continuous dictation. The native speech engine ends its own
/// recognition session after a few seconds of silence — that's outside
/// our control. Rather than surface that as "recording stopped" (which
/// silently drops anything said after a natural pause), this service
/// detects an involuntary session end and immediately opens a new one,
/// carrying forward everything recognized so far. Recording only truly
/// stops when stopListening() is called deliberately (mic tap or send).
///
/// It's also possible for the native engine to deliver one last result
/// AFTER a manual stop has been requested (an in-flight callback that
/// was already queued). _manualStop guards against that straggler ever
/// reaching the caller — once a deliberate stop begins, no further
/// onResult calls fire, so a caller that already cleared its text field
/// (e.g. right after tapping send) won't see it silently repopulate.
class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _manualStop = true;
  String _committedText = '';
  void Function(String recognizedText, bool isFinal)? _onResult;

  bool get isListening => _speech.isListening;

  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return false;

    _isInitialized = await _speech.initialize(onStatus: _handleStatus);
    return _isInitialized;
  }

  void _handleStatus(String status) {
    final sessionEndedOnItsOwn = status == 'done' || status == 'notListening';
    if (sessionEndedOnItsOwn && !_manualStop) {
      _startSession();
    }
  }

  Future<void> _startSession() async {
    await _speech.listen(
      onResult: (result) {
        // A manual stop may already be in progress even though this
        // callback — queued moments earlier by the native engine — is
        // only firing now. Drop it rather than let stale speech
        // overwrite whatever the caller has already done (like clearing
        // the input after send).
        if (_manualStop) return;

        final combined = _committedText.isEmpty
            ? result.recognizedWords
            : '$_committedText ${result.recognizedWords}';

        _onResult?.call(combined, false);

        if (result.finalResult) {
          _committedText = combined.trim();
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 6),
      partialResults: true,
    );
  }

  /// Starts continuous dictation. onResult fires repeatedly with the
  /// FULL text spoken so far across the entire session — including
  /// across any pauses where the engine restarted itself internally.
  /// isFinal is always false here; call stopListening() to end
  /// dictation deliberately.
  Future<bool> startListening({
    required void Function(String recognizedText, bool isFinal) onResult,
  }) async {
    final ready = await _ensureInitialized();
    if (!ready) return false;

    _committedText = '';
    _manualStop = false;
    _onResult = onResult;

    await _startSession();
    return true;
  }

  /// Ends dictation deliberately. Sets the guard flag BEFORE awaiting
  /// the native stop call, so even a synchronous (non-awaited) call to
  /// this method from the caller immediately blocks any further result
  /// delivery — no race window for a stray callback to sneak through.
  Future<void> stopListening() async {
    _manualStop = true;
    await _speech.stop();
  }

  void dispose() {
    _manualStop = true;
    _speech.cancel();
  }
}
