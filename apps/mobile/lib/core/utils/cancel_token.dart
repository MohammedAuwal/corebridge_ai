/// A simple cooperative cancellation token. Call cancel() to signal that
/// an in-flight operation should stop; the operation itself checks
/// isCancelled (or registers via onCancel) and exits cleanly rather than
/// throwing, so any partial result gathered so far can still be saved.
class CancelToken {
  bool _isCancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in _listeners) {
      listener();
    }
  }

  void onCancel(void Function() listener) {
    _listeners.add(listener);
  }
}
