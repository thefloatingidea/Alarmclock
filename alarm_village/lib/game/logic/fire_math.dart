/// Pure Dart helpers for how strongly a fire burns at a given progress.
double _smooth01(double t) {
  final x = t.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// 0 before [appearAt], ramps up over 0.15 of progress, then eases down to
/// about 0.3 near the end so the ruins keep smouldering instead of blazing.
///
/// Fires attached to a building (roof, windows) pass [vanishAt], the progress at
/// which that building turns to ruins. They fade out over 0.06 of progress so
/// no flame is left hanging in the air where the roof used to be.
double fireIntensity({
  required double progress,
  required double appearAt,
  double? vanishAt,
}) {
  final rise = _smooth01((progress - appearAt) / 0.15);
  final decay = 1 - 0.7 * _smooth01((progress - 0.85) / 0.15);
  final vanish =
      vanishAt == null ? 1.0 : 1 - _smooth01((progress - vanishAt) / 0.06);
  return rise * decay * vanish;
}
