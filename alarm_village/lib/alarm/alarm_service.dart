import 'dart:async';

/// Boundary between the game and the real alarm. The game only needs to know:
/// "the alarm started ringing at T" and "the user stopped it".
///
/// A production implementation wraps a native alarm plugin (reliable ringing with the app closed
/// and the screen locked is the biggest technical risk, so evaluate it on real devices first).
abstract class AlarmService {
  /// Emits the moment the alarm starts ringing.
  Stream<DateTime> get onRing;

  Future<void> schedule(DateTime at);
  Future<void> stop();
}

/// Timer-based stand-in so the rest of the app can be built and tested without a plugin.
/// It only works while the app is running.
class FakeAlarmService implements AlarmService {
  final StreamController<DateTime> _ring = StreamController<DateTime>.broadcast();
  Timer? _timer;

  @override
  Stream<DateTime> get onRing => _ring.stream;

  @override
  Future<void> schedule(DateTime at) async {
    _timer?.cancel();
    final delay = at.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () => _ring.add(DateTime.now()));
  }

  @override
  Future<void> stop() async => _timer?.cancel();
}
