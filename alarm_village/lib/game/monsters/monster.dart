import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';
import 'monster_spec.dart';

/// Template for every attacking character.
///
/// The base class handles everything shared: sleeping on its floating rock,
/// flying over the island when awake, hovering above the shield, and where the
/// breath comes from. Subclasses only draw the creature.
abstract class Monster extends Component with HasGameReference<VillageGame> {
  Monster(this.spec) : super(priority: 2000000);

  final MonsterSpec spec;

  /// 0 = on the rock, 1 = hovering over the island.
  double fly = 0;
  Offset pos = Offset.zero;
  bool facingLeft = false;

  /// Mouth position in the creature's local (unscaled) coordinates.
  Offset get mouthLocal;

  Offset get mouth {
    final m = mouthLocal * spec.scale;
    return pos + (facingLeft ? Offset(-m.dx, m.dy) : m);
  }

  bool get breathing => game.breathTarget != null;

  @override
  void update(double dt) {
    fly = (game.dragonAwake ? fly + dt * .6 : fly - dt * .8).clamp(0.0, 1.0);
    final t = game.animTime;
    final h = game.halfShown;
    final hz = game.shieldUp ? 240.0 : 160.0;
    final hover = Iso.p(center, center, hz) + Offset(math.cos(t * .5) * 26 * h, math.sin(t * .8) * 26);
    final e = fly * fly * (3 - 2 * fly);
    final prev = pos;
    pos = Offset.lerp(game.perch, hover, e)!.translate(0, -math.sin(e * math.pi) * 80);
    // Face the breath target, otherwise the flight direction.
    final target = game.breathTarget;
    if (target != null) {
      facingLeft = target.dx < pos.dx;
    } else if (fly > 0 && fly < 1 && (pos.dx - prev.dx).abs() > .3) {
      facingLeft = pos.dx < prev.dx;
    } else if (fly == 0) {
      facingLeft = false;
    }
  }

  @override
  void render(Canvas c) {
    drawPerch(c, game.perch);
    c.save();
    c.translate(pos.dx, pos.dy);
    c.scale(facingLeft ? -spec.scale : spec.scale, spec.scale);
    if (fly < .05 && !game.dragonAwake) {
      drawSleeping(c, game.animTime, stirring: game.stirring);
    } else {
      drawAwake(c, game.animTime, breathing: breathing);
    }
    c.restore();
  }

  void drawPerch(Canvas c, Offset p) {
    final paint = Paint()..isAntiAlias = true;
    final top = Rect.fromCenter(center: p.translate(0, 6), width: 110, height: 40);
    paint.color = const Color(0xFF5A3726);
    c.drawPath(
        Path()
          ..moveTo(top.left, top.center.dy)
          ..lineTo(p.dx - 22, p.dy + 70)
          ..lineTo(p.dx + 8, p.dy + 86)
          ..lineTo(top.right, top.center.dy)
          ..close(),
        paint);
    paint.color = const Color(0xFF6E4430);
    c.drawPath(
        Path()
          ..moveTo(top.left, top.center.dy)
          ..lineTo(p.dx - 22, p.dy + 70)
          ..lineTo(p.dx - 4, p.dy + 34)
          ..close(),
        paint);
    // scorched top + bones: this is a monster's nest
    paint.color = const Color(0xFF4E5A34);
    c.drawOval(top, paint);
    paint.color = const Color(0xFF3A3328);
    c.drawOval(top.deflate(6), paint);
    line(c, p.translate(-34, 10), p.translate(-22, 14), const Color(0xFFE8DCC0), 2.4);
    line(c, p.translate(30, 12), p.translate(40, 6), const Color(0xFFE8DCC0), 2.4);
    paint.color = const Color(0xFFE8DCC0);
    c.drawCircle(p.translate(-36, 9), 2, paint);
    c.drawCircle(p.translate(-20, 15), 2, paint);
  }

  void drawSleeping(Canvas c, double t, {required bool stirring});
  void drawAwake(Canvas c, double t, {required bool breathing});
}
