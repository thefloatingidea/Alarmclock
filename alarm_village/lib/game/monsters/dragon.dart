import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../iso.dart';
import 'monster.dart';
import 'monster_spec.dart';

/// Ember Dragon: dark crimson scales, bone horns, glowing eyes, bat wings.
/// Local coordinates: origin at its feet, facing right.
class EmberDragon extends Monster {
  EmberDragon() : super(Monsters.dragon);

  static const body = Color(0xFF7A1C1C);
  static const dark = Color(0xFF3A0C0E);
  static const belly = Color(0xFFC98A4A);
  static const bone = Color(0xFFE8DCC0);
  static const membrane = Color(0xFF5A1416);

  final Paint _p = Paint()..isAntiAlias = true;
  final Puffs _nostril = Puffs();
  final List<_Ember> _embers = [];
  final math.Random _r = math.Random();

  @override
  Offset get mouthLocal => const Offset(58, -50);

  @override
  void update(double dt) {
    super.update(dt);
    final asleep = fly < .05 && !game.dragonAwake;
    // nostril smoke in local space
    _nostril.update(dt, asleep ? const Offset(36, -12) : const Offset(52, -56),
        rate: game.stirring ? .15 : (asleep ? .9 : .25), dark: !asleep || game.stirring);
    if (!asleep && _r.nextDouble() < dt * 25) {
      _embers.add(_Ember(Offset(_r.nextDouble() * 60 - 30, -_r.nextDouble() * 40), 0));
    }
    for (final e in _embers) {
      e.age += dt;
      e.pos = e.pos.translate(math.sin(e.age * 6) * .4, -30 * dt);
    }
    _embers.removeWhere((e) => e.age > 1.4);
  }

  // ---------------------------------------------------------------- sleeping
  @override
  void drawSleeping(Canvas c, double t, {required bool stirring}) {
    final shake = stirring ? math.sin(t * 40) * 1.2 : 0.0;
    final breathe = 1 + math.sin(t * 1.4) * .035;
    c.translate(shake, 0);

    _p.color = const Color(0x44000000);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 76, height: 18), _p);

    // tail curled around the front
    _tail(c, const [Offset(-26, -8), Offset(-48, 4), Offset(-20, 8), Offset(16, 6)], 9);

    // folded wing
    poly(c, [const Offset(-22, -14), const Offset(-8, -38), const Offset(4, -30), const Offset(14, -16)], membrane);
    line(c, const Offset(-8, -38), const Offset(-18, -14), dark, 1.6);
    line(c, const Offset(-8, -38), const Offset(4, -16), dark, 1.6);
    poly(c, [const Offset(-8, -38), const Offset(-11, -45), const Offset(-4, -39)], bone);

    // body
    c.save();
    c.translate(0, -12);
    c.scale(breathe, breathe);
    _p.color = body;
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 58, height: 26), _p);
    _scales(c, const Rect.fromLTWH(-24, -10, 46, 14));
    c.restore();
    _spikes(c, -24, 14, -24, 7);

    // front paw + claws
    _p.color = dark;
    c.drawOval(Rect.fromCenter(center: const Offset(22, -2), width: 18, height: 8), _p);
    for (var i = 0; i < 3; i++) {
      line(c, Offset(28 + i * 2.5, -1), Offset(31 + i * 2.5, 2), bone, 1.2);
    }

    // head resting on paws
    _headSleeping(c, t, stirring);

    _nostril.render(c);
  }

  void _headSleeping(Canvas c, double t, bool stirring) {
    const h = Offset(30, -10);
    // horns sweep back
    _horn(c, h.translate(-6, -6), h.translate(-22, -16), h.translate(-14, -6));
    _horn(c, h.translate(-2, -7), h.translate(-14, -20), h.translate(-8, -8));
    // skull + snout
    poly(c, [h.translate(-10, -6), h.translate(4, -9), h.translate(16, -5), h.translate(18, 0), h.translate(-8, 2)], body);
    poly(c, [h.translate(-8, 2), h.translate(18, 0), h.translate(16, 3), h.translate(-4, 4)], dark);
    // brow ridge + spikes on the cheek
    line(c, h.translate(-4, -8), h.translate(6, -7), dark, 2);
    poly(c, [h.translate(-10, -2), h.translate(-16, 0), h.translate(-9, 1)], bone);
    // a tooth poking out
    poly(c, [h.translate(10, 1), h.translate(12, 1), h.translate(11, 4)], bone);
    // eye: closed, but every few seconds it opens a glowing slit
    final peek = (t % 7) > 6.0;
    if (stirring || peek) {
      _glowEye(c, h.translate(2, -5), 3.2);
    } else {
      line(c, h.translate(-1, -5), h.translate(5, -4.5), const Color(0xFF1A0505), 1.4);
    }
    // nostril
    _p.color = const Color(0xFF1A0505);
    c.drawCircle(h.translate(16, -3), 1.1, _p);
  }

  // ---------------------------------------------------------------- awake
  @override
  void drawAwake(Canvas c, double t, {required bool breathing}) {
    final flap = math.sin(t * 8);
    final bob = math.sin(t * 8 + 1) * 3;
    c.translate(0, bob);

    // embers drifting around it
    for (final e in _embers) {
      _p.color = Color.lerp(const Color(0xFFFFD23D), const Color(0xFFFF3000), e.age / 1.4)!
          .withAlpha(((1 - e.age / 1.4) * 255).round());
      c.drawCircle(e.pos, 1.4, _p);
    }

    _wing(c, const Offset(-6, -34), flap, back: true);
    _tail(c, [const Offset(-20, -18), Offset(-50, -10 + flap * 6), Offset(-70, 4 - flap * 8), Offset(-86, -4 + flap * 4)], 11);
    // spade tail tip
    final tip = Offset(-86, -4 + flap * 4);
    poly(c, [tip.translate(4, 0), tip.translate(-6, -8), tip.translate(-12, 2), tip.translate(-4, 8)], dark);

    // hind leg
    _p.color = darken(body, .15);
    c.drawOval(Rect.fromCenter(center: const Offset(-10, -10), width: 20, height: 22), _p);
    line(c, const Offset(-10, 0), const Offset(-14, 10), dark, 5);
    for (var i = 0; i < 3; i++) {
      line(c, Offset(-16 + i * 3.0, 10), Offset(-18 + i * 3.0, 15), bone, 1.4);
    }

    // body
    _p.color = body;
    c.drawOval(Rect.fromCenter(center: const Offset(0, -22), width: 56, height: 30), _p);
    _scales(c, const Rect.fromLTWH(-24, -34, 48, 16));
    // belly plates
    for (var i = 0; i < 6; i++) {
      _p.color = i.isEven ? belly : darken(belly, .12);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-14 + i * 6.0, -14 + (i - 3).abs() * .6, 5.5, 7), const Radius.circular(2)), _p);
    }
    _spikes(c, -26, 12, -36, 8);

    // neck: thick S curve up to the head
    final neck = Path()
      ..moveTo(10, -30)
      ..cubicTo(26, -26, 18, -48, 34, -52)
      ..lineTo(38, -42)
      ..cubicTo(26, -40, 32, -22, 18, -16)
      ..close();
    _p.color = body;
    c.drawPath(neck, _p);
    for (var i = 0; i < 4; i++) {
      poly(c, [Offset(16 + i * 5.0, -34 - i * 4.0), Offset(14 + i * 5.0, -42 - i * 4.0), Offset(20 + i * 5.0, -36 - i * 4.0)], dark);
    }

    // front arm with claws
    line(c, const Offset(16, -20), const Offset(24, -6), darken(body, .1), 6);
    for (var i = 0; i < 3; i++) {
      line(c, Offset(22 + i * 2.5, -6), Offset(26 + i * 2.5, -1), bone, 1.4);
    }

    _wing(c, const Offset(2, -36), flap, back: false);
    _headAwake(c, t, breathing);
    _nostril.render(c);
  }

  void _headAwake(Canvas c, double t, bool breathing) {
    const h = Offset(40, -54);
    final open = breathing ? 7.0 + math.sin(t * 20) : 2.0 + math.sin(t * 3);
    // horns
    _horn(c, h.translate(-8, -6), h.translate(-30, -22), h.translate(-18, -4));
    _horn(c, h.translate(-4, -8), h.translate(-20, -28), h.translate(-10, -6));
    // frill spikes behind jaw
    for (var i = 0; i < 3; i++) {
      poly(c, [h.translate(-10, -2.0 + i * 4), h.translate(-20, 0.0 + i * 6), h.translate(-9, 2.0 + i * 4)], dark);
    }
    // lower jaw (opens)
    poly(c, [h.translate(-8, 4), h.translate(18, 3 + open), h.translate(16, 7 + open), h.translate(-4, 9)], darken(body, .2));
    // mouth interior glow
    if (open > 3) {
      _p
        ..color = const Color(0xCCFF6A00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      c.drawPath(Path()..addPolygon([h.translate(-4, 3), h.translate(18, 2), h.translate(16, 3 + open)], true), _p);
      _p.maskFilter = null;
    }
    // lower teeth
    for (var i = 0; i < 4; i++) {
      final x = -2.0 + i * 5;
      final y = 3 + open * (x + 8) / 26;
      poly(c, [h.translate(x, y), h.translate(x + 2, y), h.translate(x + 1, y - 3)], bone);
    }
    // upper jaw / skull
    poly(c, [
      h.translate(-10, -8),
      h.translate(2, -11),
      h.translate(14, -7),
      h.translate(20, -2),
      h.translate(20, 2),
      h.translate(-8, 4),
    ], body);
    poly(c, [h.translate(-8, 4), h.translate(20, 2), h.translate(20, -1), h.translate(-6, 0)], darken(body, .12));
    // upper teeth / fangs
    for (var i = 0; i < 5; i++) {
      final x = -2.0 + i * 4.5;
      final len = i == 1 || i == 3 ? 5.0 : 3.0;
      poly(c, [h.translate(x, 2.5), h.translate(x + 2, 2.5), h.translate(x + 1, 2.5 + len)], bone);
    }
    // brow ridge + scars
    poly(c, [h.translate(-4, -9), h.translate(8, -10), h.translate(6, -6)], dark);
    line(c, h.translate(10, -6), h.translate(14, -3), const Color(0xFF2A0606), 1);
    // eye
    _glowEye(c, h.translate(3, -5), 3.6);
    // nostril
    _p.color = const Color(0xFF1A0505);
    c.drawCircle(h.translate(18, -3), 1.2, _p);
  }

  // ---------------------------------------------------------------- parts
  void _glowEye(Canvas c, Offset e, double r) {
    _p
      ..color = const Color(0xCCFF5A00)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    c.drawCircle(e, r * 2.4, _p);
    _p
      ..maskFilter = null
      ..color = const Color(0xFFFFD23D);
    c.drawOval(Rect.fromCenter(center: e, width: r * 2, height: r * 1.4), _p);
    _p.color = const Color(0xFF1A0505);
    c.drawOval(Rect.fromCenter(center: e, width: r * .5, height: r * 1.3), _p);
  }

  void _horn(Canvas c, Offset base, Offset tip, Offset base2) {
    _p.color = bone;
    c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo((base.dx + tip.dx) / 2, base.dy - 2, tip.dx, tip.dy)
          ..quadraticBezierTo((base2.dx + tip.dx) / 2 + 2, (base2.dy + tip.dy) / 2 + 3, base2.dx, base2.dy)
          ..close(),
        _p);
    line(c, Offset.lerp(base, tip, .3)!, Offset.lerp(base2, tip, .3)!, darken(bone, .3), .8);
    line(c, Offset.lerp(base, tip, .55)!, Offset.lerp(base2, tip, .55)!, darken(bone, .3), .8);
  }

  void _wing(Canvas c, Offset shoulder, double flap, {required bool back}) {
    final dy = flap * 18;
    final wrist = shoulder.translate(-18, -34 - dy);
    final f1 = wrist.translate(-34, 6 + dy * .6);
    final f2 = wrist.translate(-22, 28 + dy * .3);
    final f3 = wrist.translate(-4, 36);
    final root = shoulder.translate(14, 10);
    final col = back ? darken(membrane, .3) : membrane;
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..lineTo(wrist.dx, wrist.dy)
      ..lineTo(f1.dx, f1.dy)
      ..quadraticBezierTo(f1.dx + 8, f1.dy + 14, f2.dx, f2.dy)
      ..quadraticBezierTo(f2.dx + 10, f2.dy + 4, f3.dx, f3.dy)
      ..quadraticBezierTo(f3.dx + 10, f3.dy - 6, root.dx, root.dy)
      ..close();
    _p.color = col;
    c.drawPath(path, _p);
    // membrane veins and finger bones
    final b = back ? darken(dark, .2) : dark;
    line(c, shoulder, wrist, b, 3);
    line(c, wrist, f1, b, 1.8);
    line(c, wrist, f2, b, 1.6);
    line(c, wrist, f3, b, 1.4);
    poly(c, [wrist, wrist.translate(-3, -8), wrist.translate(3, -2)], bone); // wing claw
  }

  void _tail(Canvas c, List<Offset> pts, double width) {
    _p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    path.cubicTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy, pts[3].dx, pts[3].dy);
    _p
      ..strokeWidth = width
      ..color = body;
    c.drawPath(path, _p);
    _p
      ..strokeWidth = width * .35
      ..color = dark;
    c.drawPath(path, _p);
    _p.style = PaintingStyle.fill;
  }

  void _spikes(Canvas c, double x0, double x1, double y, double h) {
    for (var x = x0; x < x1; x += 6) {
      final s = h * (1 - ((x - (x0 + x1) / 2).abs() / ((x1 - x0) / 2)) * .4);
      poly(c, [Offset(x, y + 2), Offset(x + 2, y - s), Offset(x + 5, y + 2)], dark);
      line(c, Offset(x + 2, y - s), Offset(x + 2.5, y - s + 2), bone, .8);
    }
  }

  void _scales(Canvas c, Rect r) {
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = const Color(0x55000000);
    for (var row = 0; row < 3; row++) {
      for (var x = r.left + (row.isOdd ? 3 : 0); x < r.right; x += 6) {
        c.drawArc(Rect.fromLTWH(x, r.top + row * 5, 6, 6), 0, math.pi, false, _p);
      }
    }
    _p.style = PaintingStyle.fill;
  }
}

class _Ember {
  _Ember(this.pos, this.age);
  Offset pos;
  double age;
}
