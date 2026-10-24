import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';

/// The dragon sleeps on its own floating rock. When the alarm rings too long it
/// wakes up, flies over the island and breathes fire.
class Dragon extends Component with HasGameReference<VillageGame> {
  Dragon() : super(priority: 2000000);

  static const double scale = 1.5;
  double _fly = 0; // 0 = on the rock, 1 = hovering over the island
  Offset _pos = Offset.zero;

  final Paint _p = Paint()..isAntiAlias = true;
  late final TextPainter _zzz = _label('Zzz', const Color(0xFF2C3E66));
  late final TextPainter _bang = _label('!', const Color(0xFFD83A2A));

  static TextPainter _label(String s, Color col) => TextPainter(
        text: TextSpan(text: s, style: TextStyle(color: col, fontSize: 13, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();

  Offset get mouth => _pos + const Offset(35, -40) * scale;

  @override
  void update(double dt) {
    _fly = (game.dragonAwake ? _fly + dt * .6 : _fly - dt * .8).clamp(0.0, 1.0);
    final perch = game.perch;
    final t = game.animTime;
    final h = game.halfShown;
    final hover = Iso.p(center, center, 150) + Offset(math.cos(t * .5) * 28 * h, math.sin(t * .8) * 30);
    final e = _fly * _fly * (3 - 2 * _fly);
    _pos = Offset.lerp(perch, hover, e)!.translate(0, -math.sin(e * math.pi) * 80);
  }

  @override
  void render(Canvas c) {
    _rock(c, game.perch);
    c.save();
    c.translate(_pos.dx, _pos.dy);
    c.scale(scale, scale);
    _dragon(c);
    c.restore();
  }

  void _rock(Canvas c, Offset p) {
    final top = Rect.fromCenter(center: p.translate(0, 6), width: 92, height: 34);
    _p.color = const Color(0xFF6E4430);
    c.drawPath(
        Path()
          ..moveTo(top.left, top.center.dy)
          ..lineTo(p.dx - 18, p.dy + 60)
          ..lineTo(p.dx + 6, p.dy + 72)
          ..lineTo(top.right, top.center.dy)
          ..close(),
        _p);
    _p.color = const Color(0xFF85543A);
    c.drawPath(
        Path()
          ..moveTo(top.left, top.center.dy)
          ..lineTo(p.dx - 18, p.dy + 60)
          ..lineTo(p.dx - 4, p.dy + 30)
          ..close(),
        _p);
    _p.color = const Color(0xFF5E8F3C);
    c.drawOval(top, _p);
    _p.color = const Color(0xFF6FAE45);
    c.drawOval(top.deflate(4), _p);
  }

  void _dragon(Canvas c) {
    final t = game.animTime;
    final flying = _fly > .05;
    final stirring = game.stirring;
    final shake = stirring ? math.sin(t * 40) * 1.5 : 0.0;
    final breathe = 1 + math.sin(t * (flying ? 4 : 1.6)) * .04;
    final b = Offset(shake, 0);
    const body = Color(0xFFD9822B);
    final dark = darken(body, .25);

    if (!flying) {
      _p.color = const Color(0x33000000);
      c.drawOval(Rect.fromCenter(center: b, width: 58, height: 16), _p);
    }
    // tail
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = dark;
    final tailSwing = flying ? math.sin(t * 5) * 6 : 0.0;
    c.drawPath(
        Path()
          ..moveTo(b.dx - 18, b.dy - 6)
          ..quadraticBezierTo(b.dx - 36, b.dy + 6 + tailSwing, b.dx - 8, b.dy + 6)
          ..quadraticBezierTo(b.dx + 8, b.dy + 6, b.dx + 12, b.dy + 2),
        _p);
    _p.style = PaintingStyle.fill;
    poly(c, [b.translate(-30, 4 + tailSwing), b.translate(-38, 0 + tailSwing), b.translate(-34, 10 + tailSwing)], dark);

    // wings
    if (flying) {
      final flap = math.sin(t * 9) * 16;
      for (final side in [-1.0, 1.0]) {
        final root = b.translate(side * 4, -18);
        final tip = b.translate(side * 34, -46 + flap);
        poly(c, [root, tip, b.translate(side * 26, -22 + flap * .4), b.translate(side * 12, -14)],
            darken(body, side < 0 ? .45 : .32));
        line(c, root, tip, darken(body, .55), 1.4);
      }
    } else {
      poly(c, [b.translate(-10, -18), b.translate(-4, -30), b.translate(10, -18)], darken(body, .35));
    }

    // body + belly + spikes
    _p.color = body;
    c.drawOval(Rect.fromCenter(center: b.translate(0, -10), width: 48 * breathe, height: 24 * breathe), _p);
    _p.color = const Color(0xFFF2C27B);
    c.drawOval(Rect.fromCenter(center: b.translate(3, -5), width: 28, height: 10), _p);
    for (var i = 0; i < 4; i++) {
      poly(c, [b.translate(-14.0 + i * 8, -20), b.translate(-10.0 + i * 8, -27), b.translate(-6.0 + i * 8, -20)], dark);
    }
    // legs
    for (final lx in [-10.0, 8.0]) {
      line(c, b.translate(lx, -4), b.translate(lx + (flying ? -3 : 0), flying ? 4 : 1), dark, 4);
    }

    if (game.dragonAwake || flying) {
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = body;
      c.drawLine(b.translate(12, -16), b.translate(24, -36), _p);
      _p.style = PaintingStyle.fill;
      final head = b.translate(27, -39);
      c.drawOval(Rect.fromCenter(center: head, width: 22, height: 15), _p);
      c.drawOval(Rect.fromCenter(center: head.translate(8, 2), width: 12, height: 9), _p);
      poly(c, [head.translate(-6, -6), head.translate(-11, -16), head.translate(-2, -7)], dark);
      poly(c, [head.translate(-1, -7), head.translate(-3, -16), head.translate(3, -7)], dark);
      _p
        ..color = const Color(0xAAFF2A00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      c.drawCircle(head.translate(1, -2), 5, _p);
      _p
        ..maskFilter = null
        ..color = const Color(0xFFFFE14D);
      c.drawCircle(head.translate(1, -2), 2.2, _p);
      _p.color = const Color(0xFF3B2412);
      c.drawCircle(head.translate(12, 0), 1, _p);
    } else {
      final head = b.translate(24, -11);
      _p.color = body;
      c.drawOval(Rect.fromCenter(center: head, width: 19, height: 13), _p);
      c.drawOval(Rect.fromCenter(center: head.translate(7, 2), width: 10, height: 8), _p);
      poly(c, [head.translate(-5, -5), head.translate(-9, -12), head.translate(-1, -6)], dark);
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF3B2412);
      c.drawArc(Rect.fromCenter(center: head.translate(1, -1), width: 6, height: 4), 0, math.pi, false, _p);
      _p.style = PaintingStyle.fill;
      final bob = math.sin(t * 2) * 3;
      final bubble = Rect.fromCenter(center: b.translate(-16, -50 + bob), width: 34, height: 24);
      _p.color = const Color(0xEEFFFFFF);
      c.drawRRect(RRect.fromRectAndRadius(bubble, const Radius.circular(7)), _p);
      poly(c, [bubble.bottomCenter.translate(-4, 0), bubble.bottomCenter.translate(4, 0), bubble.bottomCenter.translate(2, 7)],
          const Color(0xEEFFFFFF));
      final tp = stirring ? _bang : _zzz;
      tp.paint(c, bubble.center - Offset(tp.width / 2, tp.height / 2));
    }
  }
}

/// Fire breath from the dragon's mouth to its current target.
class FireBreath extends Component with HasGameReference<VillageGame> {
  FireBreath() : super(priority: 1999999);
  final Paint _p = Paint()..isAntiAlias = true;

  @override
  void render(Canvas c) {
    final target = game.breathTarget, dragon = game.dragon;
    if (target == null || dragon == null) return;
    final from = dragon.mouth;
    final v = target - from;
    final len = v.distance;
    if (len < 1) return;
    final n = Offset(-v.dy / len, v.dx / len);
    final wob = math.sin(game.animTime * 30) * 3;
    _p.shader = ui.Gradient.linear(
        from, target, const [Color(0xFFFFE066), Color(0xFFFF6A00), Color(0x00FF3000)], const [0, .6, 1]);
    c.drawPath(
        Path()..addPolygon([from + n * 3, from - n * 3, target - n * (18 + wob), target + n * (18 + wob)], true), _p);
    _p.shader = null;
    for (var i = 0; i < 6; i++) {
      final k = (game.animTime * 2.5 + i / 6) % 1;
      _p.color = Color.lerp(const Color(0xFFFFD23D), const Color(0xFFFF4A1A), k)!.withAlpha(((1 - k) * 230).round());
      c.drawCircle(from + v * k, 3 + k * 10, _p);
    }
  }
}
