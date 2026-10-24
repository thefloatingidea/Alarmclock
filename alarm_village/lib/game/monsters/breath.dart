import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../village_game.dart';

/// Breath attack from the active monster's mouth to its current target.
class Breath extends Component with HasGameReference<VillageGame> {
  Breath() : super(priority: 2100000);
  final Paint _p = Paint()..isAntiAlias = true;

  @override
  void render(Canvas c) {
    final target = game.breathTarget, m = game.monster;
    if (target == null || m == null || m.fly < .9) return;
    final cols = m.spec.breathColors;
    final from = m.mouth;
    final v = target - from;
    final len = v.distance;
    if (len < 1) return;
    final n = Offset(-v.dy / len, v.dx / len);
    final wob = math.sin(game.animTime * 30) * 3;
    _p.shader = ui.Gradient.linear(from, target, cols, const [0, .55, 1]);
    c.drawPath(Path()..addPolygon([from + n * 3, from - n * 3, target - n * (20 + wob), target + n * (20 + wob)], true), _p);
    _p.shader = null;
    for (var i = 0; i < 7; i++) {
      final k = (game.animTime * 2.5 + i / 7) % 1;
      _p.color = Color.lerp(cols[0], cols[1], k)!.withAlpha(((1 - k) * 230).round());
      c.drawCircle(from + v * k + n * math.sin(i * 3.0 + game.animTime * 12) * 6, 3 + k * 11, _p);
    }
    // impact glow
    _p
      ..color = cols[1].withAlpha(150)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    c.drawCircle(target, 22, _p);
    _p.maskFilter = null;
  }
}
