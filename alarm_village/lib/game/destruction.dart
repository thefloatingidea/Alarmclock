import 'monsters/monster_spec.dart';

/// Attack timeline, driven by the active monster's spec.
///   0 .. wake           monster asleep - stop now and the island grows
///   wake .. wake+burnFor monster burns the city; at 100% the city is gone
class Destruction {
  static MonsterSpec spec = Monsters.dragon;

  static double get wake => spec.wakeAfter; // 15 s
  static double get burnFor => spec.burnFor; // 60 s
  static double get total => wake + burnFor;
  static const double stirWindow = 5; // seconds of "stirring" before waking
  static const double buildingBurn = 8;
  static const double collapseDuration = 1.5;
  static const double freeRestoreLimit = 0.5; // below 50% burned = free rebuild

  /// 0..1 share of the city burned at elapsed [e].
  static double fraction(double e) => ((e - wake) / burnFor).clamp(0.0, 1.0);

  /// When the building at [order] (of [n]) catches fire. All buildings are
  /// burned down by 85%, the last 15% the island itself breaks apart.
  static double igniteAt(int order, int n) {
    if (n <= 1) return wake + 1;
    final span = burnFor * 0.85 - buildingBurn - collapseDuration - 1;
    return wake + 1 + order * span / (n - 1);
  }

  static List<int> collapsed(double e, List<int> active) => [
        for (var i = 0; i < active.length; i++)
          if (e - igniteAt(i, active.length) >= buildingBurn + collapseDuration) active[i],
      ];

  static double crumble(double e) => ((fraction(e) - 0.85) / 0.15).clamp(0.0, 1.0);

  static String stageLabel(double e, {bool shield = false}) {
    if (e < wake - stirWindow) return 'The ${spec.name.toLowerCase()} is asleep. Stop now to grow your island!';
    if (e < wake) return 'The ${spec.name.toLowerCase()} is stirring...';
    if (shield) return 'Your shield is holding the ${spec.name.toLowerCase()} back!';
    if (fraction(e) < freeRestoreLimit) return 'Stop before 50% and the villagers rebuild for free!';
    return 'Too late for a free rebuild - the city is burning down!';
  }
}
