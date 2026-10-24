import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';

/// Speech bubbles for villagers and the monster, drawn above everything.
class SpeechLayer extends Component with HasGameReference<VillageGame> {
  SpeechLayer() : super(priority: 4000000);

  final Map<String, TextPainter> _cache = {};
  final Paint _p = Paint()..isAntiAlias = true;

  TextPainter _tp(String s, Color col, double size, FontWeight w) => _cache.putIfAbsent(
      '$s|${col.value}',
      () => TextPainter(
            text: TextSpan(text: s, style: TextStyle(color: col, fontSize: size, fontWeight: w, height: 1.15)),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout(maxWidth: 120));

  void _bubble(Canvas c, Offset anchor, String text, double alpha, {bool monster = false}) {
    final tp = monster
        ? _tp(text, const Color(0xFFFFE0C0), 10, FontWeight.w900)
        : _tp(text, const Color(0xFF2C2A3A), 9, FontWeight.w600);
    final r = Rect.fromCenter(
        center: anchor.translate(0, -tp.height / 2 - 12), width: tp.width + 14, height: tp.height + 10);
    final bg = monster ? const Color(0xFF3A0C0E) : Colors.white;
    _p.color = bg.withAlpha((alpha * 235).round());
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), _p);
    c.drawPath(
        Path()..addPolygon([r.bottomCenter.translate(-4, -1), r.bottomCenter.translate(4, -1), anchor.translate(0, -4)], true),
        _p);
    if (monster) {
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFFF6A00).withAlpha((alpha * 255).round());
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), _p);
      _p.style = PaintingStyle.fill;
    }
    c.saveLayer(r.inflate(2), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    tp.paint(c, Offset(r.left + 7, r.top + 5));
    c.restore();
  }

  @override
  void update(double dt) {
    if (game.monsterLineT > 0) game.monsterLineT -= dt;
  }

  @override
  void render(Canvas c) {
    for (final v in game.villagers) {
      final s = v.saying;
      if (s == null || !v.visible) continue;
      final a = (v.sayT / .3).clamp(0.0, 1.0);
      _bubble(c, v.screenPos.translate(0, -26), s, a);
    }
    final m = game.monster;
    final line = game.monsterLine;
    if (m != null && line != null && game.monsterLineT > 0 && m.fly > .9) {
      _bubble(c, m.pos.translate(0, -95), line, (game.monsterLineT / .3).clamp(0.0, 1.0), monster: true);
    }
  }
}

/// Visible protective dome over the island while a shield is active.
class ShieldDome extends Component with HasGameReference<VillageGame> {
  ShieldDome() : super(priority: 1900000);
  double _a = 0;
  final Paint _p = Paint()..isAntiAlias = true;

  @override
  void update(double dt) {
    _a = (game.shieldUp ? _a + dt * 1.5 : _a - dt * 1.5).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas c) {
    if (_a <= 0) return;
    final ctr = game.domeCenter;
    final rx = game.domeRx * (0.85 + 0.15 * _a), h = game.domeH * _a, ry = rx / 2;
    final hit = game.shieldHit;
    final pulse = .5 + .5 * math.sin(game.animTime * 2);
    final dome = Path()
      ..addArc(Rect.fromCenter(center: ctr, width: rx * 2, height: h * 2), math.pi, math.pi)
      ..arcTo(Rect.fromCenter(center: ctr, width: rx * 2, height: ry * 2), 0, math.pi, false)
      ..close();
    final base = Color.lerp(const Color(0xFF6FD3FF), const Color(0xFFFFC46B), hit)!;
    _p.shader = RadialGradient(
      center: const Alignment(0, .3),
      radius: .9,
      colors: [base.withAlpha((_a * (18 + 30 * hit)).round()), base.withAlpha((_a * (70 + 90 * hit)).round())],
    ).createShader(Rect.fromCenter(center: ctr.translate(0, -h / 2), width: rx * 2, height: h * 1.4));
    c.drawPath(dome, _p);
    _p.shader = null;

    // hex-like latitude / longitude lines that shimmer
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var k = 1; k <= 4; k++) {
      final f = k / 5;
      final yy = ctr.dy - h * f;
      final w = rx * math.sqrt(1 - f * f);
      _p.color = base.withAlpha((_a * (50 + 60 * pulse * (k.isEven ? 1 : .5))).round());
      c.drawOval(Rect.fromCenter(center: Offset(ctr.dx, yy), width: w * 2, height: w), _p);
    }
    for (var k = -2; k <= 2; k++) {
      final f = k / 3;
      _p.color = base.withAlpha((_a * 45).round());
      c.drawArc(Rect.fromCenter(center: ctr, width: rx * 2 * (1 - f.abs()) + 1, height: h * 2), math.pi, math.pi, false, _p);
    }
    // bright rim
    _p
      ..strokeWidth = 2.5 + 3 * hit
      ..color = lighten(base, .4).withAlpha((_a * (160 + 90 * hit)).round());
    c.drawPath(dome, _p);
    _p.style = PaintingStyle.fill;
    // emitter crystal on the tower spire
    final tip = Iso.p(center, center, 300);
    _p
      ..color = base.withAlpha((_a * 200).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    c.drawCircle(tip, 8 + 4 * pulse, _p);
    _p.maskFilter = null;
  }
}

/// Rain that restores the city after a water-bucket restore.
class RainLayer extends Component with HasGameReference<VillageGame> {
  RainLayer() : super(priority: 3000000);

  final List<(double, double, double)> _drops =
      List.generate(240, (i) => (math.Random(i).nextDouble(), math.Random(i + 999).nextDouble(), .7 + math.Random(i * 3).nextDouble() * .6));
  final Paint _p = Paint()..isAntiAlias = true;

  @override
  void render(Canvas c) {
    final t = game.rainT;
    if (t <= 0) return;
    final a = math.min(1.0, t).clamp(0.0, 1.0) * math.min(1.0, (4.5 - t) * 3);
    final r = game.content;
    if (r == Rect.zero) return;
    final top = r.top - 40;
    // rain clouds
    for (var i = 0; i < 7; i++) {
      final x = r.left + (i + .5) * r.width / 7 + math.sin(game.animTime + i) * 8;
      _p.color = const Color(0xFF5E6E80).withAlpha((a * 230).round());
      c.drawCircle(Offset(x, top), 46, _p);
      _p.color = const Color(0xFF7D8DA0).withAlpha((a * 230).round());
      c.drawCircle(Offset(x - 14, top - 14), 30, _p);
    }
    // drops
    final h = r.height + 40;
    for (final d in _drops) {
      final x = r.left + d.$1 * r.width;
      final y = top + ((d.$2 * h + game.animTime * 520 * d.$3) % h);
      line(c, Offset(x, y), Offset(x - 2, y + 12 * d.$3), const Color(0xFFBFE6FF).withAlpha((a * 200).round()), 1.4);
    }
    // splashes on the ground
    for (var i = 0; i < 30; i++) {
      final rr = math.Random(i * 17 + (game.animTime * 4).floor());
      final gp = Iso.p(center + (rr.nextDouble() - .5) * game.halfShown * 2, center + (rr.nextDouble() - .5) * game.halfShown * 2);
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFDFF3FF).withAlpha((a * 160).round());
      c.drawOval(Rect.fromCenter(center: gp, width: 8, height: 3), _p);
      _p.style = PaintingStyle.fill;
    }
  }
}
