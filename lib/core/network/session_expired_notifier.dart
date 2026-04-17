import 'dart:async';

/// Fired by [AuthClient] when the session cannot be recovered
/// (refresh token missing or refresh call fails).
/// The UI layer listens to [stream] and shows the re-login dialog.
class SessionExpiredNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}
