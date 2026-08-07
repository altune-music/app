import 'dart:async';

/// ponytail: minimal debounce utility.
///
/// Wraps a timer so repeated calls within [delay] collapse into one execution.
/// Call [cancel] to discard a pending call, or [dispose] when done.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  /// Schedule [action] after [delay]. Any previous pending action is cancelled.
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending action without executing it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
