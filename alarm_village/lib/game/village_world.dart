import 'package:flame/components.dart';

import 'components/building.dart';
import 'components/ground.dart';
import 'components/island.dart';
import 'components/landmarks.dart';
import 'components/nature.dart';
import 'components/overlays.dart';
import 'components/tower.dart';
import 'components/villager.dart';
import 'destruction.dart';
import 'layout.dart';
import 'monsters/breath.dart';
import 'monsters/dragon.dart';
import 'monsters/monster.dart';
import 'monsters/monster_spec.dart';
import 'village_game.dart';

/// Builds every possible object once; each one shows itself when its unlock day is reached.
class VillageWorld extends World with HasGameReference<VillageGame> {
  /// Creates the monster for a spec. Register new monsters here.
  static Monster createMonster(MonsterSpec spec) => switch (spec.id) {
        _ => EmberDragon(),
      };

  @override
  Future<void> onLoad() async {
    add(Island());
    add(Ground());
    add(ClockTower());

    Lighthouse? lighthouse;
    for (var i = 0; i < layout.length; i++) {
      final it = layout[i];
      if (it.isBuilding) {
        add(buildingFor(it, i));
        continue;
      }
      switch (it.kind) {
        case Kind.pine || Kind.oak:
          add(Tree(it));
        case Kind.mountain:
          add(Mountain(it));
        case Kind.pen:
          add(Pen(it));
        case Kind.lighthouse:
          lighthouse = Lighthouse(it);
          add(lighthouse);
        case Kind.balloon:
          add(Balloon(it));
        case Kind.bush || Kind.flowers || Kind.rock || Kind.lamp || Kind.well || Kind.bench || Kind.sign:
          add(Decor(it));
        default:
          break;
      }
    }

    for (var i = 0; i < 10; i++) {
      add(Villager(i));
    }

    final monster = createMonster(Destruction.spec);
    game.monster = monster;
    add(monster);
    add(Breath());
    add(ShieldDome());
    add(LighthouseBeam(lighthouse));
    add(RainLayer());
    add(SpeechLayer());
  }
}
