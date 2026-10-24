import 'package:alarm_village/game/logic/fire_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no fire before it appears', () {
    expect(fireIntensity(progress: 0.1, appearAt: 0.2), 0);
  });

  test('fire ramps up after it appears', () {
    final early = fireIntensity(progress: 0.25, appearAt: 0.2);
    final full = fireIntensity(progress: 0.5, appearAt: 0.2);
    expect(early, greaterThan(0));
    expect(early, lessThan(full));
    expect(full, closeTo(1, 1e-9));
  });

  test('fire eases down to a smoulder at the end', () {
    expect(fireIntensity(progress: 1, appearAt: 0.2), closeTo(0.3, 1e-9));
  });

  test('intensity stays within 0..1', () {
    for (var p = 0.0; p <= 1.0; p += 0.01) {
      final v = fireIntensity(progress: p, appearAt: 0.34);
      expect(v, inInclusiveRange(0, 1));
    }
  });

  test('building fires vanish when the building turns to ruins', () {
    double at(double p) =>
        fireIntensity(progress: p, appearAt: 0.2, vanishAt: 0.6);
    expect(at(0.5), closeTo(1, 1e-9));
    expect(at(0.63), lessThan(at(0.5)));
    expect(at(0.66), closeTo(0, 1e-9));
    expect(at(1), 0);
  });

  test('ground fires without vanishAt keep smouldering in the ruins', () {
    expect(fireIntensity(progress: 0.7, appearAt: 0.5), greaterThan(0.9));
  });
}
