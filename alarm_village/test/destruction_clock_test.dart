import 'package:alarm_village/game/logic/destruction_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 1, 1, 7, 0, 0);
  final clock = DestructionClock(
    ringStart: start,
    grace: const Duration(seconds: 30),
    total: const Duration(minutes: 2),
  );

  test('nothing happens during the grace period', () {
    expect(clock.progressAt(start), 0);
    expect(clock.progressAt(start.add(const Duration(seconds: 29))), 0);
    expect(clock.progressAt(start.subtract(const Duration(seconds: 5))), 0);
  });

  test('progress is counted after the grace period', () {
    expect(clock.progressAt(start.add(const Duration(seconds: 90))), closeTo(0.5, 1e-9));
    expect(clock.progressAt(start.add(const Duration(seconds: 150))), 1);
  });

  test('progress is clamped to 1 after the total time', () {
    expect(clock.progressAt(start.add(const Duration(hours: 3))), 1);
  });

  test('opening the app late gives the right value with no timer needed', () {
    final later = start.add(const Duration(seconds: 30 + 30));
    expect(clock.progressAt(later), closeTo(0.25, 1e-9));
  });
}
