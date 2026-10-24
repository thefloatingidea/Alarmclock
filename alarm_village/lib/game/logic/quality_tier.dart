/// Visual quality tiers from the art & tech brief.
///
/// High: all effects. Medium: fewer fires, no heat haze. Low: colour grade only.
enum QualityTier {
  high(label: 'High', maxFires: 60, heatHaze: true),
  medium(label: 'Medium', maxFires: 20, heatHaze: false),
  low(label: 'Low', maxFires: 0, heatHaze: false);

  const QualityTier({
    required this.label,
    required this.maxFires,
    required this.heatHaze,
  });

  final String label;
  final int maxFires;
  final bool heatHaze;
}
