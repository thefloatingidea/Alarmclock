/// Pure Dart: turns "when did the alarm start ringing" into a 0..1 progress value.
///
/// Progress is computed from timestamps, not from a running timer, so opening
/// the app late shows the correct state straight away.
class DestructionClock {
  const DestructionClock({
    required this.ringStart,
    this.grace = const Duration(seconds: 30),
    this.total = const Duration(minutes: 2),
  });

  /// When the alarm began ringing.
  final DateTime ringStart;

  /// Nothing happens during this period after the alarm starts.
  final Duration grace;

  /// How long destruction takes to go from 0 to 1, counted after [grace].
  final Duration total;

  double progressAt(DateTime now) {
    final elapsed = now.difference(ringStart) - grace;
    if (elapsed.isNegative) return 0;
    final p = elapsed.inMicroseconds / total.inMicroseconds;
    return p.clamp(0.0, 1.0);
  }
}
