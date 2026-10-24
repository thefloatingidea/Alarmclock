import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../iso.dart';
import '../village_game.dart';
import 'iso_object.dart';

class House extends IsoObject {
  House(this.id, double x, double y) : super(x, y, 1.4, 1.2);

  final int id;
  static const double wallH = 30, roofH = 20;
  static const _roofs = [Color(0xFFC8553D), Color(0xFF4F6D8F), Color(0xFFB5651D), Color(0xFF8E3B46)];
  static const _walls = [Color(0xFFE8D6B0), Color(0xFFCDBB9A), Color(0xFFD9C3A0)];

  final Puffs _smoke = Puffs();
  final Paint _p = Paint()..isAntiAlias = true;

  Offset get roofTop => Iso.p(x + w / 2, y + d / 2, wallH + roofH);
  Offset get _chimneyTop => Iso.p(x + .36, y + .31, wallH + 24);

  @override
  void update(double dt) {
    final s = game.houseStatus(id);
    switch (s.kind) {
      case HouseKind.normal:
        if (s.burning) {
          _smoke.update(dt, roofTop.translate(0, -10), rate: .12, dark: true);
        } else {
          _smoke.update(dt, _chimneyTop, rate: .7);
        }
      case HouseKind.ruin:
        _smoke.update(dt, Iso.p(x + w / 2, y + d / 2, 6), rate: 1.6, dark: true);
      default:
        _smoke.update(dt, null);
    }
  }

  @override
  void draw(Canvas c) {
    final s = game.houseStatus(id);
    switch (s.kind) {
      case HouseKind.hidden:
        return;
      case HouseKind.plot:
        _drawPlot(c);
        return;
      case HouseKind.ruin:
        _drawRubble(c);
        _smoke.render(c);
        return;
      case HouseKind.normal:
        break;
    }
    if (s.collapse >= 1) {
      _drawRubble(c);
      drawFlames(c, Iso.p(x + w / 2, y + d / 2, 4), .8, game.animTime, id);
      _smoke.render(c);
      return;
    }
    final char = s.burn * .65;
    final wall = darken(_walls[id % _walls.length], char);
    final roof = darken(_roofs[id % _roofs.length], char);
    final h = wallH * (1 - s.collapse);

    isoBox(c, x: x, y: y, w: w, d: d, h: h, color: wall);
    _drawOpenings(c, h, s.burning);

    isoGableRoof(c,
        x: x, y: y, w: w, d: d, z: h, h: roofH * (1 - s.collapse), roof: roof, wall: wall,
        between: () => isoBox(c, x: x + .25, y: y + .2, w: .22, d: .22, z: h + 4, h: 20, color: const Color(0xFF8C847A)));

    if (s.burning) {
      drawFlames(c, roofTop.translate(0, 6), 1.0 + s.burn * .4, game.animTime, id);
      if (s.burn > .35) drawFlames(c, Iso.p(x + w, y + d * .6, h * .5), .7, game.animTime, id + 3);
    }
    _smoke.render(c);
  }

  void _drawOpenings(Canvas c, double h, bool burning) {
    if (h < 14) return;
    final lit = burning || game.nightness > .4;
    final win = burning ? const Color(0xFFFF8A3D) : (lit ? const Color(0xFFFFD27A) : const Color(0xFF5B7A99));
    final fw = w * Iso.edge, sw = d * Iso.edge;
    c.save();
    c.transform(Iso.leftWall(Iso.p(x, y + d, h)));
    _p.color = const Color(0xFF6B4226);
    c.drawRect(Rect.fromLTWH(fw * .42, h - 16, 9, 16), _p);
    _p.color = win;
    c.drawRect(Rect.fromLTWH(7, 8, 8, 8), _p);
    c.drawRect(Rect.fromLTWH(fw - 15, 8, 8, 8), _p);
    c.restore();
    c.save();
    c.transform(Iso.rightWall(Iso.p(x + w, y + d, h)));
    c.drawRect(Rect.fromLTWH(sw / 2 - 4, 9, 8, 8), _p);
    c.restore();
  }

  void _drawRubble(Canvas c) {
    final r = math.Random(id);
    for (var i = 0; i < 7; i++) {
      final bx = x + .1 + r.nextDouble() * (w - .45), by = y + .1 + r.nextDouble() * (d - .45);
      isoBox(c, x: bx, y: by, w: .35, d: .3, h: 4 + r.nextDouble() * 6,
          color: i.isEven ? const Color(0xFF5A524A) : const Color(0xFF3E2C22));
    }
    _p
      ..color = const Color(0xFF2A1E18)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(Iso.p(x + .2, y + .5, 2), Iso.p(x + 1.1, y + .7, 16), _p);
    c.drawLine(Iso.p(x + .9, y + .2, 2), Iso.p(x + .5, y + 1, 12), _p);
  }

  /// Empty plot = "a new family moves in tomorrow if you wake on time".
  void _drawPlot(Canvas c) {
    final pulse = 0.5 + 0.5 * math.sin(game.animTime * 2);
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withAlpha((80 + 100 * pulse).round());
    c.drawPath(
        Path()..addPolygon([Iso.p(x, y), Iso.p(x + w, y), Iso.p(x + w, y + d), Iso.p(x, y + d)], true), _p);
    _p.style = PaintingStyle.fill;
    final post = Iso.p(x + w / 2, y + d / 2);
    _p.color = const Color(0xFF6B4226);
    c.drawRect(Rect.fromLTWH(post.dx - 1, post.dy - 16, 2, 16), _p);
    _p.color = const Color(0xFFE8D6B0);
    c.drawRect(Rect.fromLTWH(post.dx - 8, post.dy - 22, 16, 9), _p);
  }
}
