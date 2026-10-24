import 'package:alarm_village/game/logic/building_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t = BuildingThresholds(damageAt: 0.25, ruinAt: 0.6);

  BuildingState at(double p, [double dusk = 0]) =>
      resolveBuildingState(progress: p, dusk: dusk, thresholds: t);

  test('healthy by day, lit by night', () {
    expect(at(0), BuildingState.healthy);
    expect(at(0, 1), BuildingState.lit);
    expect(at(0.1, 0.49), BuildingState.healthy);
    expect(at(0.1, 0.5), BuildingState.lit);
  });

  test('damaged then ruined at the thresholds', () {
    expect(at(0.249), BuildingState.healthy);
    expect(at(0.25), BuildingState.damaged);
    expect(at(0.599), BuildingState.damaged);
    expect(at(0.6), BuildingState.ruined);
    expect(at(1), BuildingState.ruined);
  });

  test('damage and ruin override night lighting', () {
    expect(at(0.3, 1), BuildingState.damaged);
    expect(at(0.8, 1), BuildingState.ruined);
  });

  test('seeded thresholds are stable and ordered', () {
    final a = BuildingThresholds.seeded(42);
    final b = BuildingThresholds.seeded(42);
    expect(a.damageAt, b.damageAt);
    expect(a.ruinAt, b.ruinAt);
    for (var seed = 0; seed < 200; seed++) {
      final s = BuildingThresholds.seeded(seed);
      expect(s.damageAt, inInclusiveRange(0.20, 0.45));
      expect(s.ruinAt, greaterThan(s.damageAt));
      expect(s.ruinAt, lessThanOrEqualTo(0.98));
    }
  });
}
