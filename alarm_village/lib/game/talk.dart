import 'dart:math' as math;

import 'village_game.dart';

/// Generic lines the villagers say, chosen from what is happening right now.
class Talk {
  static String pick(VillageGame g, math.Random r, {required bool keeper}) {
    final v = g.village;
    final s = v.streak;
    String any(List<String> l) => l[r.nextInt(l.length)];

    // --- during an alarm ---
    if (g.ringing) {
      if (g.engine.finishing) return any(['It\'s over... run to the boats!', 'We tried to wake you...', 'Save the cat!']);
      if (g.dragonAwake && g.shieldUp) {
        return any(['Ha! It bounced right off!', 'Hold, shield, hold!', 'Worth every coin, that shield.', 'Now please wake up!']);
      }
      if (g.dragonAwake) {
        return any([
          'DRAGON! RUN!',
          'My house! Not my house!',
          'Somebody wake the Timekeeper!',
          'Water! Bring water!',
          'Stop the alarm before half the city burns!',
          'Hold the big button!',
        ]);
      }
      if (g.stirring) return any(['It\'s moving... IT\'S MOVING!', 'Did the dragon just open an eye?', 'Hurry, hurry, hurry!']);
      return any([
        'Psst! The alarm! Wake up!',
        'Hurry, before the dragon hears it!',
        'Rise and shine, Timekeeper!',
        'Quick - hold the button!',
      ]);
    }

    // --- aftermath ---
    if (v.damagePct > 0) {
      return any(['Half my roof is gone...', 'We can rebuild - just say the word!', 'Smells like burnt bread around here.']);
    }

    // --- the clock-keeper on an empty island ---
    if (keeper && v.level == 0) {
      return any([
        'Welcome, Timekeeper! Wake on time and this rock becomes a village.',
        'Just you, me and the tower for now.',
        'See that nest? The dragon sleeps there. Let\'s keep it that way.',
        'Wake within 15 seconds and settlers will come.',
      ]);
    }

    final h = g.hourOfDay;
    final pool = <String>[];
    if (s >= 3) {
      pool.addAll([
        '$s-day streak! They\'re writing songs about you.',
        '$s days in a row. The dragon looks... bored.',
        'The baker named a loaf after your $s-day streak.',
      ]);
    } else if (s == 0 && v.level > 0) {
      pool.addAll(['New streak starts tomorrow, right?', 'Everyone oversleeps sometimes. Not tomorrow though!']);
    }
    if (g.shieldUp) pool.addAll(['That shield hums like a happy bee.', 'Shield\'s up. I can finally nap.']);
    if (v.shields == 0 && !g.shieldUp) pool.add('A shield would let us sleep easier...');
    if (h >= 5 && h < 11) {
      pool.addAll(['Good morning! Up already? Impressive.', 'Fresh bread, thanks to you waking on time.', 'What a sunrise!']);
    } else if (h >= 11 && h < 17) {
      pool.addAll(['Busy day today!', 'Have you set tomorrow\'s alarm?', 'My cousin wants to move here. Keep that streak going!']);
    } else if (h >= 17 && h < 21) {
      pool.addAll(['Lovely evening.', 'Early night? The tower will wake you.', 'Supper\'s almost ready!']);
    } else {
      pool.addAll(['Shouldn\'t you be asleep?', 'Sweet dreams - the dragon\'s dreaming too.', 'Shh... the dragon is snoring.']);
    }
    if (v.level >= 10) pool.addAll(['The windmill has never been busier.', 'Did you see the waterfall?']);
    if (v.level >= 30) pool.add('A golden tower! We\'re famous now.');
    return any(pool);
  }
}
