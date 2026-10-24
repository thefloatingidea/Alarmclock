import 'dart:ui' show Color;

/// Data describing an attacking monster. Add a new spec + a [Monster]
/// subclass (see monster.dart) to introduce a new, more ferocious character.
class MonsterSpec {
  const MonsterSpec({
    required this.id,
    required this.name,
    required this.wakeAfter,
    required this.burnFor,
    required this.breathColors,
    this.scale = 1.7,
    this.unlockDay = 0,
    this.taunts = const [],
  });

  final String id;
  final String name;

  /// Seconds after the alarm starts before the monster wakes up.
  final double wakeAfter;

  /// Seconds the monster needs to destroy the whole city once awake.
  final double burnFor;

  /// Breath gradient: core -> mid -> fade.
  final List<Color> breathColors;
  final double scale;

  /// Streak day from which this monster can appear (for future monsters).
  final int unlockDay;

  /// Lines the monster growls (shown in its speech bubble).
  final List<String> taunts;
}

class Monsters {
  static const dragon = MonsterSpec(
    id: 'ember_dragon',
    name: 'Dragon',
    wakeAfter: 15,
    burnFor: 60,
    breathColors: [Color(0xFFFFF3A0), Color(0xFFFF6A00), Color(0x00B01000)],
    taunts: [
      'I SMELL A SLEEPYHEAD...',
      'YOUR VILLAGE LOOKS... FLAMMABLE.',
      'SNOOZE. I DARE YOU.',
      'MORE FIRE!',
    ],
  );

  // Future ideas - add a Monster subclass for each and list it here:
  //  - Storm Wyvern: wakes after 10 s, burns in 45 s (lightning breath)
  //  - Frost Drake:  freezes buildings instead of burning them
  static const all = <MonsterSpec>[dragon];
}
