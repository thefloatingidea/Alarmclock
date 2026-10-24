import 'dart:math';

/// Visual states of a building. The enum name is used in the SVG file name:
/// building_<name>_<state>.svg
enum BuildingState { healthy, lit, damaged, ruined }

/// The progress values at which a building changes state.
class BuildingThresholds {
  const BuildingThresholds({required this.damageAt, required this.ruinAt})
      : assert(damageAt < ruinAt);

  /// Picks thresholds from a seed, so the same buildings fall first every time.
  factory BuildingThresholds.seeded(int seed) {
    final r = Random(seed);
    final damage = 0.20 + r.nextDouble() * 0.25; // 0.20 .. 0.45
    final ruin = min(0.98, damage + 0.20 + r.nextDouble() * 0.25);
    return BuildingThresholds(damageAt: damage, ruinAt: ruin);
  }

  final double damageAt;
  final double ruinAt;
}

/// Which state a building should show for the current progress and time of day.
BuildingState resolveBuildingState({
  required double progress,
  required double dusk,
  required BuildingThresholds thresholds,
}) {
  if (progress >= thresholds.ruinAt) return BuildingState.ruined;
  if (progress >= thresholds.damageAt) return BuildingState.damaged;
  return dusk >= 0.5 ? BuildingState.lit : BuildingState.healthy;
}
