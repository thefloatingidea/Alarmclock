import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../village_game.dart';

/// Villagers stroll along the roads; they run when the monster attacks.
/// Index 0 is the clock-keeper who stands by the tower from day 0.
class Villager extends Component with HasGameReference<VillageGame> {
  Villager(this.index)
      : _r = math.Random(index * 13 + 5),
        super(priority: 0);

  final int index;
  final math.Random _r;
  late double _t = _r.nextDouble();
  late double _dir = _r.nextBool() ? 1.0 : -1.0;
  double _pause = 0;
  double _a = 0;
  double gx = 8, gy = 10.5;

  String? saying;
  double sayT = 0;

  static const _shirts = [
    Color(0xFF6D4C9F), Color(0xFF3F7BD9), Color(0xFFE85D3F), Color(0xFF5E8C4A), Color(0xFF8E5BC2), Color(0xFFE0A030),
  ];

  bool get keeper => index == 0;
  bool get visible => _a > .9;

  void say(String text) {
    saying = text;
    sayT = 3.5 + text.length * .03;
  }

  bool get _avenue => index % 3 == 2 && game.level >= 6;

  (double, double) get _range {
    final l = game.level;
    if (_avenue) return (9.7, l < 15 ? 12.8 : 15.6);
    if (l < 9) return (5.2, 10.8);
    if (l < 15) return (2.2, 13.8);
    return (0.3, 15.7);
  }

  @override
  void onMount() {
    super.onMount();
    game.villagers.add(this);
  }

  @override
  void update(double dt) {
    final want = index < game.villagerCount;
    _a = (want ? _a + dt * 2 : _a - dt * 2).clamp(0.0, 1.0);
    if (sayT > 0) {
      sayT -= dt;
      if (sayT <= 0 || !visible) saying = null;
    }
    if (_a <= 0) return;
    final panic = game.attacking;

    if (keeper) {
      // Paces a little in front of the tower; runs in circles when panicking.
      final t = game.animTime;
      final amp = panic ? .5 : .25;
      gx = 7.0 + math.sin(t * (panic ? 3 : .4)) * amp;
      gy = 9.95 + (panic ? math.cos(t * 3) * .1 : 0);
      _pause = panic ? 0 : (math.sin(t * .4).abs() > .9 ? 1 : 0);
    } else {
      final (lo, hi) = _range;
      final len = hi - lo;
      if (_pause > 0 && !panic) {
        _pause -= dt;
      } else {
        final speed = (panic ? 2.4 : 0.45 + (index % 4) * .08) / len;
        _t += _dir * speed * dt;
        if (_t > 1 || _t < 0) {
          _t = _t.clamp(0.0, 1.0);
          _dir = -_dir;
        } else if (!panic && _r.nextDouble() < dt * .08) {
          _pause = 1 + _r.nextDouble() * 3;
        }
      }
      final along = lo + _t * len;
      final lane = (index.isEven ? .38 : .62);
      if (_avenue) {
        gx = 7.7 + lane * .6;
        gy = along;
      } else {
        gx = along;
        gy = 10.2 + lane * .6;
      }
    }
    final pr = ((gx + gy) * 100).round() + 5;
    if (pr != priority) priority = pr;
  }

  Offset get screenPos => Iso.p(gx, gy).translate(0, game.dropAt(gx, gy));

  @override
  void render(Canvas c) {
    if (_a <= 0) return;
    final b = screenPos;
    final walking = _pause <= 0 || game.attacking;
    final step = walking ? math.sin(game.animTime * (game.attacking ? 22 : 9) + index) * 2 : 0.0;
    final p = Paint()..isAntiAlias = true;
    c.save();
    c.translate(b.dx, b.dy);
    c.scale(_a, _a);
    p.color = const Color(0x33000000);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 9, height: 3.5), p);
    line(c, Offset(-1.5, -6), Offset(-1.5 + step * .6, 0), const Color(0xFF3B3B4F), 1.8);
    line(c, Offset(1.5, -6), Offset(1.5 - step * .6, 0), const Color(0xFF3B3B4F), 1.8);
    p.color = _shirts[index % _shirts.length];
    if (keeper) {
      // long robe
      c.drawPath(Path()..addPolygon(const [Offset(-4, -13), Offset(4, -13), Offset(5.5, -2), Offset(-5.5, -2)], true), p);
    } else {
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -13, 7, 8), const Radius.circular(2.5)), p);
    }
    p.color = const Color(0xFFF1C9A5);
    c.drawCircle(const Offset(0, -16), 3, p);
    if (keeper) {
      // white beard + pointed hat + lantern
      p.color = const Color(0xFFF2F2F2);
      c.drawPath(Path()..addPolygon(const [Offset(-2.5, -15), Offset(2.5, -15), Offset(0, -10)], true), p);
      p.color = const Color(0xFF4B3A7A);
      c.drawPath(Path()..addPolygon(const [Offset(-4.5, -18), Offset(4.5, -18), Offset(1, -27)], true), p);
      p.color = const Color(0xFFFFD27A);
      c.drawCircle(const Offset(6, -7), 1.8, p);
      line(c, const Offset(4, -11), const Offset(6, -9), const Color(0xFF3B3B3B), .8);
    } else if (index.isEven) {
      p.color = const Color(0xFF8A5A33);
      c.drawRect(const Rect.fromLTWH(-4, -19, 8, 1.6), p);
      c.drawRect(const Rect.fromLTWH(-2.5, -21.5, 5, 2.6), p);
    } else {
      p.color = const Color(0xFF4A2E1C);
      c.drawArc(Rect.fromCircle(center: const Offset(0, -16), radius: 3.2), math.pi, math.pi, true, p);
    }
    c.restore();
  }
}
