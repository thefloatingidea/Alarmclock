import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';
import 'iso_object.dart';

/// Anything the monster can burn: charring, flames, collapse and ruins.
abstract class Building extends IsoObject {
  Building(super.item, this.id);

  final int id;
  final Puffs _smoke = Puffs();
  final Paint p = Paint()..isAntiAlias = true;

  double get topZ;
  Offset? get chimney => null;
  Offset get fireAnchor => Iso.p(x + w / 2, y + d / 2, topZ);

  @override
  void onMount() {
    super.onMount();
    game.buildings[id] = this;
  }

  @override
  void tick(double dt) {
    final s = game.buildingStatus(id);
    if (s.state == BuildState.ruin) {
      _smoke.update(dt, Iso.p(x + w / 2, y + d / 2, 6), rate: 1.6, dark: true);
    } else if (s.burning) {
      _smoke.update(dt, fireAnchor.translate(0, -10), rate: .12, dark: true);
    } else {
      _smoke.update(dt, chimney, rate: .7);
    }
  }

  @override
  void draw(Canvas c) {
    final s = game.buildingStatus(id);
    if (s.state == BuildState.ruin || s.collapse >= 1) {
      _rubble(c);
      if (s.burning) drawFlames(c, Iso.p(x + w / 2, y + d / 2, 4), .8, game.animTime, id);
      _smoke.render(c);
      return;
    }
    groundShadow(c, x, y, w, d);
    structure(c, s.burn * .65, 1 - s.collapse, s.burning);
    if (s.burning) {
      drawFlames(c, fireAnchor.translate(0, 6), 1.0 + s.burn * .4, game.animTime, id);
      if (s.burn > .35) drawFlames(c, Iso.p(x + w, y + d * .6, topZ * .4), .7, game.animTime, id + 3);
    }
    _smoke.render(c);
  }

  void structure(Canvas c, double char, double k, bool burning);

  bool get lit => game.nightness > .4;

  void window(Canvas c, Rect r, bool burning) {
    final glass = burning ? const Color(0xFFFF8A3D) : (lit ? const Color(0xFFFFD27A) : const Color(0xFF6E92B5));
    if (lit || burning) {
      p
        ..color = glass.withAlpha(120)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      c.drawRect(r.inflate(2), p);
      p.maskFilter = null;
    }
    p.color = const Color(0xFF5A3A22);
    c.drawRect(r.inflate(1.4), p);
    p.color = glass;
    c.drawRect(r, p);
    p.color = const Color(0xFF5A3A22);
    c.drawRect(Rect.fromLTWH(r.center.dx - .6, r.top, 1.2, r.height), p);
    c.drawRect(Rect.fromLTWH(r.left, r.center.dy - .6, r.width, 1.2), p);
    if (!lit && !burning) {
      p.color = const Color(0x66FFFFFF);
      c.drawRect(Rect.fromLTWH(r.left + 1, r.top + 1, r.width * .35, r.height * .35), p);
    }
  }

  void door(Canvas c, Rect r) {
    p.color = const Color(0xFF4A2E1C);
    c.drawRRect(RRect.fromRectAndCorners(r.inflate(1.2), topLeft: const Radius.circular(5), topRight: const Radius.circular(5)), p);
    p.color = const Color(0xFF7A4E2D);
    c.drawRRect(RRect.fromRectAndCorners(r, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), p);
    p.color = const Color(0xFF5E3A22);
    c.drawRect(Rect.fromLTWH(r.center.dx - .5, r.top + 2, 1, r.height - 2), p);
    p.color = const Color(0xFFE8C46A);
    c.drawCircle(Offset(r.right - 2.5, r.center.dy + 1), 1.1, p);
  }

  void _rubble(Canvas c) {
    final r = math.Random(id);
    for (var i = 0; i < 8; i++) {
      final bx = x + .1 + r.nextDouble() * (w - .45), by = y + .1 + r.nextDouble() * (d - .45);
      isoBox(c, x: bx, y: by, w: .35, d: .3, h: 4 + r.nextDouble() * 6,
          color: i.isEven ? const Color(0xFF5A524A) : const Color(0xFF3E2C22), edges: false);
    }
    line(c, Iso.p(x + .2, y + .5, 2), Iso.p(x + w * .8, y + .7, 16), const Color(0xFF2A1E18), 3);
    line(c, Iso.p(x + w * .65, y + .2, 2), Iso.p(x + .5, y + d * .85, 12), const Color(0xFF2A1E18), 3);
  }
}

class House extends Building {
  House(super.item, super.id);

  static const double wallH = 30, roofH = 22;
  static const _roofs = [
    Color(0xFFC8553D), Color(0xFF4F6D8F), Color(0xFFB5651D), Color(0xFF8E3B46), Color(0xFF5E8C4A), Color(0xFF6D5A8E),
  ];
  static const _walls = [Color(0xFFEBDDBE), Color(0xFFD6C3A0), Color(0xFFE3CFA8), Color(0xFFCFD6DE)];

  @override
  double get topZ => wallH + roofH;
  @override
  Offset get chimney => Iso.p(x + .36, y + .31, wallH + 26);

  @override
  void structure(Canvas c, double char, double k, bool burning) {
    final v = item.variant;
    final wall = darken(_walls[v % _walls.length], char);
    final roof = darken(_roofs[v % _roofs.length], char);
    final h = wallH * k;
    isoBox(c, x: x - .03, y: y - .03, w: w + .06, d: d + .06, h: 4, color: darken(const Color(0xFF9C968A), char), edges: false);
    isoBox(c, x: x, y: y, w: w, d: d, z: 4, h: h - 4, color: wall);
    if (h > 16) {
      final fw = w * Iso.edge, sw = d * Iso.edge;
      final timber = v.isOdd;
      c.save();
      c.transform(Iso.leftWall(Iso.p(x, y + d, h)));
      if (timber) {
        p.color = darken(const Color(0xFF6B4226), char);
        c.drawRect(Rect.fromLTWH(0, 0, fw, 2), p);
        c.drawRect(Rect.fromLTWH(0, h * .45, fw, 1.6), p);
        c.drawRect(Rect.fromLTWH(fw * .5 - 1, 0, 2, h - 4), p);
      }
      door(c, Rect.fromLTWH(fw * .5 - 5, h - 18, 10, 14));
      window(c, Rect.fromLTWH(6, 7, 8, 8), burning);
      window(c, Rect.fromLTWH(fw - 14, 7, 8, 8), burning);
      p.color = const Color(0xFF7A4E2D);
      c.drawRect(Rect.fromLTWH(5, 16.5, 10, 2.5), p);
      for (var i = 0; i < 4; i++) {
        p.color = i.isEven ? const Color(0xFFFF6B8B) : const Color(0xFFFFD84D);
        c.drawCircle(Offset(6.5 + i * 2.4, 16), 1.4, p);
      }
      c.restore();
      c.save();
      c.transform(Iso.rightWall(Iso.p(x + w, y + d, h)));
      window(c, Rect.fromLTWH(sw / 2 - 4, 8, 8, 8), burning);
      if (timber) {
        p.color = darken(const Color(0xFF6B4226), char);
        c.drawRect(Rect.fromLTWH(0, 0, sw, 2), p);
      }
      c.restore();
    }
    isoGableRoof(c, x: x, y: y, w: w, d: d, z: h, h: roofH * k, roof: roof, wall: wall, between: () {
      isoBox(c, x: x + .25, y: y + .2, w: .22, d: .22, z: h + 4, h: 22 * k, color: const Color(0xFF8C847A));
      isoBox(c, x: x + .22, y: y + .17, w: .28, d: .28, z: h + 4 + 22 * k, h: 3, color: const Color(0xFF6E675E));
    });
  }
}

class Barn extends Building {
  Barn(super.item, super.id);
  @override
  double get topZ => 58;

  @override
  void structure(Canvas c, double char, double k, bool burning) {
    final wall = darken(const Color(0xFFB03A2E), char);
    final h = 34 * k;
    isoBox(c, x: x, y: y, w: w, d: d, h: h, color: wall);
    if (h > 20) {
      final fw = w * Iso.edge;
      c.save();
      c.transform(Iso.leftWall(Iso.p(x, y + d, h)));
      p.color = const Color(0xFFF2EEE6);
      final dr = Rect.fromLTWH(fw / 2 - 10, h - 22, 20, 22);
      c.drawRect(dr.inflate(1.5), p);
      p.color = darken(wall, .25);
      c.drawRect(dr, p);
      line(c, dr.topLeft, dr.bottomRight, const Color(0xFFF2EEE6), 1.6);
      line(c, dr.topRight, dr.bottomLeft, const Color(0xFFF2EEE6), 1.6);
      window(c, Rect.fromLTWH(fw / 2 - 4, 3, 8, 6), burning);
      c.restore();
      isoBox(c, x: x + w + .05, y: y + d - .5, w: .35, d: .35, h: 7, color: const Color(0xFFE5C25A));
    }
    isoGableRoof(c, x: x, y: y, w: w, d: d, z: h, h: 24 * k, roof: darken(const Color(0xFF5B4636), char), wall: wall);
  }
}

class Church extends Building {
  Church(super.item, super.id);
  @override
  double get topZ => 100;

  @override
  void structure(Canvas c, double char, double k, bool burning) {
    final wall = darken(const Color(0xFFE6E0D4), char);
    final h = 36 * k;
    isoBox(c, x: x, y: y, w: w, d: d, h: h, color: wall);
    if (h > 20) {
      final fw = w * Iso.edge;
      c.save();
      c.transform(Iso.leftWall(Iso.p(x, y + d, h)));
      door(c, Rect.fromLTWH(fw / 2 - 6, h - 18, 12, 18));
      p.color = const Color(0xFF6B5B95);
      c.drawCircle(Offset(fw / 2, 10), 6, p);
      p.color = lit || burning ? const Color(0xFFFFD27A) : const Color(0xFFB39DDB);
      c.drawCircle(Offset(fw / 2, 10), 4.5, p);
      c.restore();
    }
    isoGableRoof(c, x: x, y: y, w: w, d: d, z: h, h: 24 * k, roof: darken(const Color(0xFF4F6D8F), char), wall: wall);
    final sx = x + w - .55, sy = y + d - .55;
    isoBox(c, x: sx, y: sy, w: .5, d: .5, z: h, h: 30 * k, color: wall);
    isoPyramid(c, x: sx - .05, y: sy - .05, w: .6, d: .6, z: h + 30 * k, h: 28 * k, color: darken(const Color(0xFF4F6D8F), char));
    final top = Iso.p(sx + .25, sy + .25, h + 58 * k);
    line(c, top, top.translate(0, -10), const Color(0xFFE8C46A), 1.6);
    line(c, top.translate(-3.5, -6.5), top.translate(3.5, -6.5), const Color(0xFFE8C46A), 1.6);
  }
}

class Market extends Building {
  Market(super.item, super.id);
  @override
  double get topZ => 30;

  @override
  void structure(Canvas c, double char, double k, bool burning) {
    const stripes = [Color(0xFFD94F4F), Color(0xFF4F8FD9)];
    for (var s = 0; s < 2; s++) {
      final sx = x + s * 1.05;
      isoBox(c, x: sx, y: y + .5, w: .9, d: .5, h: 10 * k, color: darken(const Color(0xFF9A6A3E), char));
      for (var g = 0; g < 3; g++) {
        p.color = [const Color(0xFFE53935), const Color(0xFFFFB300), const Color(0xFF7CB342)][(g + s) % 3];
        c.drawCircle(Iso.p(sx + .2 + g * .25, y + .75, 12 * k), 2.6, p);
      }
      for (final px in [sx + .05, sx + .85]) {
        line(c, Iso.p(px, y + 1.0), Iso.p(px, y + 1.0, 26 * k), const Color(0xFF6B4226), 1.6);
      }
      for (var i = 0; i < 6; i++) {
        final a0 = sx + i * .15, a1 = a0 + .15;
        poly(c, [Iso.p(a0, y + .2, 30 * k), Iso.p(a1, y + .2, 30 * k), Iso.p(a1, y + 1.1, 22 * k), Iso.p(a0, y + 1.1, 22 * k)],
            darken(stripes[(i + s) % 2], char + (i.isEven ? 0 : .05)));
      }
    }
  }
}

class Windmill extends Building {
  Windmill(super.item, super.id);
  @override
  double get topZ => 70;

  @override
  void structure(Canvas c, double char, double k, bool burning) {
    isoBox(c, x: x, y: y, w: w, d: d, h: 50 * k, color: darken(const Color(0xFFD8CFC0), char));
    if (k > .6) {
      final fw = w * Iso.edge;
      c.save();
      c.transform(Iso.leftWall(Iso.p(x, y + d, 50 * k)));
      door(c, Rect.fromLTWH(fw / 2 - 5, 50 * k - 16, 10, 16));
      window(c, Rect.fromLTWH(fw / 2 - 3, 10, 6, 7), burning);
      c.restore();
    }
    isoPyramid(c, x: x - .1, y: y - .1, w: w + .2, d: d + .2, z: 50 * k, h: 26 * k, color: darken(const Color(0xFF8A5A3B), char));
    final hub = Iso.p(x + w / 2, y + d + .05, 44 * k);
    final spin = burning ? 0.0 : game.animTime * (game.ringing ? 4 : 1);
    for (var i = 0; i < 4; i++) {
      c.save();
      c.translate(hub.dx, hub.dy);
      c.rotate(spin + i * math.pi / 2);
      p.color = const Color(0xFF6B4226);
      c.drawRect(const Rect.fromLTWH(-1.2, -44, 2.4, 44), p);
      p.color = darken(const Color(0xFFEDE3D0), char);
      c.drawRect(const Rect.fromLTWH(1.2, -42, 8, 30), p);
      for (var l = 0; l < 4; l++) {
        line(c, Offset(1.2, -40 + l * 8.0), Offset(9.2, -40 + l * 8.0), const Color(0x556B4226), .8);
      }
      c.restore();
    }
    p.color = const Color(0xFF4A3B2E);
    c.drawCircle(hub, 3.5, p);
  }
}

Building buildingFor(Item it, int id) => switch (it.kind) {
      Kind.barn => Barn(it, id),
      Kind.church => Church(it, id),
      Kind.market => Market(it, id),
      Kind.windmill => Windmill(it, id),
      _ => House(it, id),
    };
