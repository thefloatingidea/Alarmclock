import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';
import 'iso_object.dart';
import 'tower.dart';

class Lighthouse extends IsoObject {
  Lighthouse(super.item);

  Offset get lamp => Iso.p(x + w / 2, y + d / 2, 119);

  @override
  void draw(Canvas c) {
    groundShadow(c, x, y, w, d, .25);
    isoBox(c, x: x - .15, y: y - .15, w: w + .3, d: d + .3, h: 6, color: const Color(0xFF8E887C));
    for (var i = 0; i < 6; i++) {
      isoBox(c, x: x, y: y, w: w, d: d, z: 6 + i * 17.0, h: 17,
          color: i.isEven ? const Color(0xFFF2EEE6) : const Color(0xFFC0392B), edges: i == 5);
    }
    isoBox(c, x: x - .12, y: y - .12, w: w + .24, d: d + .24, z: 108, h: 4, color: const Color(0xFF3B3B3B));
    final lampCol = game.ringing ? const Color(0xFFFF4A3A) : const Color(0xFFFFE08A);
    c.drawCircle(lamp, 16, Paint()
      ..color = lampCol.withAlpha(170)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    isoBox(c, x: x + .15, y: y + .15, w: .7, d: .7, z: 112, h: 14, color: lampCol);
    isoPyramid(c, x: x, y: y, w: w, d: d, z: 126, h: 16, color: const Color(0xFFB03A2E));
  }
}

class LighthouseBeam extends Component with HasGameReference<VillageGame> {
  LighthouseBeam(this.lighthouse) : super(priority: 1000000);
  final Lighthouse? lighthouse;
  final Paint _p = Paint()..blendMode = BlendMode.plus;

  @override
  void render(Canvas c) {
    if (game.village.destroyed) return;
    final lh = lighthouse;
    Offset lamp;
    if (lh != null && lh.appear >= 1) {
      lamp = lh.lamp.translate(0, game.dropAt(lh.x + .5, lh.y + .5));
    } else if (game.ringing) {
      lamp = Iso.p(center, center, ClockTower.spireTipZ - 6);
    } else {
      return;
    }
    final strength = game.ringing ? 1.0 : (0.2 + 0.8 * game.nightness);
    final col = game.ringing ? const Color(0xFFFF3B30) : const Color(0xFFFFE6A3);
    final speed = game.ringing ? 2.4 : 0.5;
    const len = 1300.0, spread = 0.07;
    for (var k = 0; k < 2; k++) {
      final ang = game.animTime * speed + k * math.pi;
      Offset dir(double a) => Offset(math.cos(a), math.sin(a) * .45);
      final end = lamp + dir(ang) * len;
      _p.shader = ui.Gradient.linear(lamp, end, [col.withAlpha((140 * strength).round()), col.withAlpha(0)]);
      c.drawPath(Path()..addPolygon([lamp, lamp + dir(ang - spread) * len, lamp + dir(ang + spread) * len], true), _p);
    }
    _p.shader = null;
  }
}

class Balloon extends Component with HasGameReference<VillageGame> {
  Balloon(this.item) : super(priority: 1500000);
  final Item item;
  double _a = 0;
  final Paint _p = Paint()..isAntiAlias = true;

  @override
  void update(double dt) {
    final want = game.itemReady(item) && !game.ringing && !game.village.destroyed;
    _a = (want ? _a + dt : _a - dt * 2).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas c) {
    if (_a <= 0) return;
    final t = game.animTime;
    final pos = Iso.p(item.x + math.sin(t * .05) * 3, item.y + math.cos(t * .04) * 3, 300 + math.sin(t * .7) * 8);
    c.save();
    c.translate(pos.dx, pos.dy);
    c.scale(_a, _a);
    line(c, const Offset(-10, 4), const Offset(-5, 26), const Color(0xFF5A3A22), 1);
    line(c, const Offset(10, 4), const Offset(5, 26), const Color(0xFF5A3A22), 1);
    _p.color = const Color(0xFF8A5A33);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, 26, 12, 9), const Radius.circular(2)), _p);
    const cols = [Color(0xFFE85D3F), Color(0xFFFFD54F), Color(0xFF4F8FD9), Color(0xFFFFD54F), Color(0xFFE85D3F)];
    final env = Rect.fromCenter(center: const Offset(0, -10), width: 40, height: 46);
    c.save();
    c.clipPath(Path()..addOval(env));
    for (var i = 0; i < cols.length; i++) {
      _p.color = cols[i];
      c.drawRect(Rect.fromLTWH(env.left + i * env.width / cols.length, env.top, env.width / cols.length + .5, env.height), _p);
    }
    _p.color = const Color(0x22000000);
    c.drawRect(Rect.fromLTWH(env.center.dx, env.top, env.width / 2, env.height), _p);
    c.restore();
    c.restore();
  }
}
