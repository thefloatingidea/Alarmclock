import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import 'iso_object.dart';

class Mountain extends IsoObject {
  Mountain(super.item);

  @override
  void draw(Canvas c) {
    final h = item.h;
    final rock = Color.lerp(const Color(0xFF6E8B4E), const Color(0xFF3B3226), game.scorch * .5)!;
    isoPyramid(c, x: x, y: y, w: w, d: d, h: h, color: rock);
    final apex = Iso.p(x + w / 2, y + d / 2, h);
    final bl = Iso.p(x, y + d), bf = Iso.p(x + w, y + d), br = Iso.p(x + w, y);
    Offset at(Offset a, double t) => Offset.lerp(a, apex, t)!;
    poly(c, [at(bl, .45), at(bf, .45), at(bf, .7), at(bl, .7)], const Color(0xFF8F8A7E));
    poly(c, [at(bf, .45), at(br, .45), at(br, .7), at(bf, .7)], const Color(0xFF6F6A60));
    poly(c, [at(bl, .7), at(bf, .7), apex], const Color(0xFFF4F6F8));
    poly(c, [at(bf, .7), at(br, .7), apex], const Color(0xFFCBD3DC));
    final r = math.Random(item.day);
    for (var i = 0; i < 6; i++) {
      final t = .08 + r.nextDouble() * .3;
      final p = Offset.lerp(Offset.lerp(bl, bf, r.nextDouble())!, apex, t)!;
      poly(c, [p.translate(-4, 0), p.translate(4, 0), p.translate(0, -11)], const Color(0xFF2E6B45));
    }
    line(c, bf, apex, lighten(rock, .2).withAlpha(140), 1);
  }
}

class Tree extends IsoObject {
  Tree(super.item);

  @override
  void draw(Canvas c) {
    final b = Iso.p(x + .3, y + .3);
    final s = 0.9 + (item.variant % 30) / 100;
    final sway = math.sin(game.animTime * 1.3 + item.variant) * 1.2;
    final burnt = (game.scorch * 1.4 - (item.variant % 10) / 25).clamp(0.0, .9);
    c.drawOval(Rect.fromCenter(center: b.translate(3, 1), width: 22 * s, height: 9 * s),
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    poly(c, [b.translate(-2 * s, 0), b.translate(2 * s, 0), b.translate(1.6 * s, -9 * s), b.translate(-1.6 * s, -9 * s)],
        const Color(0xFF6B4226));
    if (item.kind == Kind.pine) {
      final g = Color.lerp(const Color(0xFF2E7D4F), const Color(0xFF2B2420), burnt)!;
      void tier(double base, double wd, double h, double l) {
        final top = b.translate(sway * (l + .3), base - h);
        poly(c, [b.translate(-wd / 2, base), b.translate(0, base + 2), top], lighten(g, l));
        poly(c, [b.translate(0, base + 2), b.translate(wd / 2, base), top], darken(g, .18 - l * .3));
      }

      tier(-7 * s, 24 * s, 18 * s, 0);
      tier(-15 * s, 19 * s, 16 * s, .07);
      tier(-23 * s, 13 * s, 13 * s, .14);
    } else {
      final g = Color.lerp(const Color(0xFF4CAF50), const Color(0xFF2B2420), burnt)!;
      final paint = Paint()..isAntiAlias = true;
      final cx = b.translate(sway, -18 * s);
      paint.color = darken(g, .2);
      c.drawCircle(cx.translate(3 * s, 2 * s), 11 * s, paint);
      paint.color = g;
      c.drawCircle(cx.translate(-4 * s, 0), 9 * s, paint);
      c.drawCircle(cx.translate(2 * s, -4 * s), 9 * s, paint);
      paint.color = lighten(g, .18);
      c.drawCircle(cx.translate(-3 * s, -6 * s), 5 * s, paint);
      if (item.variant % 3 == 0 && burnt < .3) {
        paint.color = const Color(0xFFE53935);
        for (var i = 0; i < 4; i++) {
          c.drawCircle(cx.translate((i * 5.0 - 7) * s, (i.isEven ? 2.0 : -3.0) * s), 1.6 * s, paint);
        }
      }
    }
    if (burnt > .5 && game.attacking) {
      drawFlames(c, b.translate(0, -14 * s), .45, game.animTime, item.variant);
    }
  }
}

class Decor extends IsoObject {
  Decor(super.item);
  final Paint _p = Paint()..isAntiAlias = true;

  @override
  void draw(Canvas c) {
    final b = Iso.p(x + w / 2, y + d / 2);
    final burnt = game.scorch * .8;
    switch (item.kind) {
      case Kind.bush:
        final g = Color.lerp(const Color(0xFF3F9A48), const Color(0xFF2B2420), burnt)!;
        _p.color = darken(g, .2);
        c.drawCircle(b.translate(3, -4), 6, _p);
        _p.color = g;
        c.drawCircle(b.translate(-3, -4), 6, _p);
        c.drawCircle(b.translate(1, -8), 5.5, _p);
        _p.color = lighten(g, .2);
        c.drawCircle(b.translate(-2, -9), 2.5, _p);
        if (item.variant.isEven) {
          _p.color = const Color(0xFFFF8FB1);
          c.drawCircle(b.translate(2, -6), 1.4, _p);
          c.drawCircle(b.translate(-4, -3), 1.4, _p);
        }
      case Kind.flowers:
        const cols = [Color(0xFFFFE066), Color(0xFFFF6B8B), Color(0xFFB39DFF), Color(0xFFFFFFFF), Color(0xFFFF9F43)];
        final r = math.Random(item.variant);
        for (var i = 0; i < 7; i++) {
          final p = b.translate(r.nextDouble() * 14 - 7, r.nextDouble() * 6 - 3);
          line(c, p, p.translate(0, -5), const Color(0xFF3E7A2C), 1);
          _p.color = Color.lerp(cols[(item.variant + i) % cols.length], const Color(0xFF3A3330), burnt)!;
          c.drawCircle(p.translate(0, -6), 2, _p);
        }
      case Kind.rock:
        isoBox(c, x: x + .05, y: y + .05, w: w * .7, d: d * .6, h: 6, color: const Color(0xFF9A958B));
        isoBox(c, x: x + w * .5, y: y + d * .45, w: w * .4, d: d * .4, h: 4, color: const Color(0xFF8A857B));
      case Kind.lamp:
        line(c, b, b.translate(0, -26), const Color(0xFF3B3B3B), 2);
        _p.color = const Color(0xFF3B3B3B);
        c.drawRect(Rect.fromCenter(center: b.translate(0, -29), width: 7, height: 8), _p);
        final on = game.nightness > .35 || game.ringing;
        if (on) {
          _p
            ..color = (game.ringing ? const Color(0xFFFF6A4A) : const Color(0xFFFFD27A)).withAlpha(140)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          c.drawCircle(b.translate(0, -29), 12, _p);
          _p.maskFilter = null;
        }
        _p.color = on ? const Color(0xFFFFE6A3) : const Color(0xFFBFC7CF);
        c.drawRect(Rect.fromCenter(center: b.translate(0, -29), width: 4.5, height: 5), _p);
      case Kind.well:
        isoBox(c, x: x, y: y, w: w, d: d, h: 9, color: const Color(0xFF9C968A));
        poly(c, [Iso.p(x + .1, y + .1, 9), Iso.p(x + w - .1, y + .1, 9), Iso.p(x + w - .1, y + d - .1, 9), Iso.p(x + .1, y + d - .1, 9)],
            const Color(0xFF2F6FA8));
        line(c, Iso.p(x + .05, y + d / 2, 9), Iso.p(x + .05, y + d / 2, 26), const Color(0xFF6B4226), 1.6);
        line(c, Iso.p(x + w - .05, y + d / 2, 9), Iso.p(x + w - .05, y + d / 2, 26), const Color(0xFF6B4226), 1.6);
        isoGableRoof(c, x: x - .05, y: y, w: w + .1, d: d, z: 24, h: 8, roof: const Color(0xFFB5651D), wall: const Color(0xFF6B4226));
      case Kind.bench:
        isoBox(c, x: x, y: y, w: w, d: d * .6, z: 4, h: 2, color: const Color(0xFF9A6A3E), edges: false);
        isoBox(c, x: x, y: y, w: w, d: .06, z: 4, h: 7, color: const Color(0xFF8A5A33), edges: false);
        line(c, Iso.p(x + .05, y + d * .5), Iso.p(x + .05, y + d * .5, 4), const Color(0xFF4A2E1C), 1.4);
        line(c, Iso.p(x + w - .05, y + d * .5), Iso.p(x + w - .05, y + d * .5, 4), const Color(0xFF4A2E1C), 1.4);
      case Kind.sign:
        line(c, b, b.translate(0, -20), const Color(0xFF6B4226), 2);
        poly(c, [b.translate(-2, -20), b.translate(12, -17), b.translate(12, -12), b.translate(-2, -15)], const Color(0xFFC49A6C));
        poly(c, [b.translate(2, -11), b.translate(-11, -9), b.translate(-11, -5), b.translate(2, -7)], const Color(0xFFB08A5A));
      default:
        break;
    }
  }
}

class Pen extends IsoObject {
  Pen(super.item);
  final Paint _p = Paint()..isAntiAlias = true;

  void _fence(Canvas c, double x0, double y0, double x1, double y1) {
    const post = Color(0xFF7A4E2D), rail = Color(0xFF9A6A3E);
    final n = (((x1 - x0).abs() + (y1 - y0).abs()) / .4).floor();
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final px = x0 + (x1 - x0) * t, py = y0 + (y1 - y0) * t;
      line(c, Iso.p(px, py), Iso.p(px, py, 11), post, 1.8);
    }
    line(c, Iso.p(x0, y0, 9), Iso.p(x1, y1, 9), rail, 1.4);
    line(c, Iso.p(x0, y0, 5), Iso.p(x1, y1, 5), rail, 1.4);
  }

  @override
  void draw(Canvas c) {
    _fence(c, x, y, x + w, y);
    _fence(c, x, y, x, y + d);
    final t = game.animTime;
    final flee = game.attacking ? 3.0 : 1.0;
    final sheep = <Offset>[];
    for (var i = 0; i < 4; i++) {
      sheep.add(Offset(x + w / 2 + math.sin(t * .25 * flee + i * 1.7) * (w / 2 - .3),
          y + d / 2 + math.cos(t * .19 * flee + i * 2.3) * (d / 2 - .3)));
    }
    sheep.sort((a, b) => (a.dx + a.dy).compareTo(b.dx + b.dy));
    for (final s in sheep) {
      final p = Iso.p(s.dx, s.dy);
      _p.color = const Color(0x33000000);
      c.drawOval(Rect.fromCenter(center: p, width: 14, height: 5), _p);
      line(c, p.translate(-3, 0), p.translate(-3, -4), const Color(0xFF333333), 1.4);
      line(c, p.translate(3, 0), p.translate(3, -4), const Color(0xFF333333), 1.4);
      _p.color = const Color(0xFFF4F1EA);
      c.drawCircle(p.translate(-3, -7), 4.2, _p);
      c.drawCircle(p.translate(2, -7.5), 4.6, _p);
      c.drawCircle(p.translate(0, -10), 3.6, _p);
      _p.color = const Color(0xFF3A3330);
      c.drawOval(Rect.fromCenter(center: p.translate(7, -9), width: 5, height: 4), _p);
    }
    _fence(c, x, y + d, x + w, y + d);
    _fence(c, x + w, y, x + w, y + d);
  }
}
