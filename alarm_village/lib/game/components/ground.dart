import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';

/// Flat features: roads, river + waterfall, pond, fields, bridge.
class Ground extends Component with HasGameReference<VillageGame> {
  Ground() : super(priority: -90000);

  late final List<Item> _items =
      layout.where((i) => i.kind == Kind.path || i.kind == Kind.field || i.kind == Kind.pond || i.kind == Kind.bridge).toList();
  late final List<double> _fade = List.filled(_items.length, 0);
  final Paint _p = Paint()..isAntiAlias = true;

  @override
  void update(double dt) {
    for (var i = 0; i < _items.length; i++) {
      final want = game.itemReady(_items[i]);
      _fade[i] = (want ? _fade[i] + dt * 2 : _fade[i] - dt * 4).clamp(0.0, 1.0);
    }
  }

  void _onGround(Canvas c, double gx, double gy, double cx, double cy, void Function() body) {
    final dr = game.dropAt(cx, cy);
    if (dr > 500) return;
    c.save();
    c.translate(0, dr);
    c.transform(Iso.ground(Iso.p(gx, gy)));
    body();
    c.restore();
  }

  Color _a(Color col, double f) => col.withAlpha((col.alpha * f).round());

  @override
  void render(Canvas c) {
    final e = Iso.edge;
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < _items.length; i++) {
        final it = _items[i];
        final f = _fade[i];
        if (f <= 0 || (it.kind == Kind.path) != (pass == 0)) continue;
        switch (it.kind) {
          case Kind.path:
            _onGround(c, it.x, it.y, it.x + it.w / 2, it.y + it.d / 2, () => _path(c, it, f, e));
          case Kind.field:
            _onGround(c, it.x, it.y, it.x + it.w / 2, it.y + it.d / 2, () => _field(c, it, f, e));
          case Kind.pond:
            _onGround(c, it.x, it.y, it.x + 1, it.y + 1, () => _pond(c, it, f, e));
          default:
            break;
        }
      }
      if (pass == 0) _river(c, e);
    }
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].kind == Kind.bridge && _fade[i] > 0) _bridge(c, _items[i], _fade[i]);
    }
  }

  void _path(Canvas c, Item it, double f, double e) {
    final r = Rect.fromLTWH(0, 0, it.w * e, it.d * e);
    _p.color = _a(const Color(0xFFB08A5A), f);
    c.drawRRect(RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(6)), _p);
    _p.color = _a(const Color(0xFFD9BC8C), f);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), _p);
    final rnd = math.Random(it.x.toInt() * 31 + it.y.toInt());
    _p.color = _a(const Color(0xFFC4A274), f);
    final count = (it.w * it.d * 14).round();
    for (var k = 0; k < count; k++) {
      c.drawOval(Rect.fromCenter(center: Offset(rnd.nextDouble() * r.width, rnd.nextDouble() * r.height), width: 6, height: 4), _p);
    }
  }

  void _field(Canvas c, Item it, double f, double e) {
    final r = Rect.fromLTWH(0, 0, it.w * e, it.d * e);
    _p.color = _a(const Color(0xFF6B4226), f);
    c.drawRect(r.inflate(2), _p);
    _p.color = _a(const Color(0xFF7E5232), f);
    c.drawRect(r, _p);
    final crop = Color.lerp(const Color(0xFF5DAE3B), const Color(0xFF4A3A28), game.scorch)!;
    final rows = (it.d * 4).round();
    for (var row = 0; row < rows; row++) {
      final yy = 6 + row * (r.height - 12) / math.max(1, rows - 1);
      _p.color = _a(const Color(0xFF5E3A22), f);
      c.drawRect(Rect.fromLTWH(2, yy - 2, r.width - 4, 4), _p);
      final cols = (it.w * 6).round();
      for (var col = 0; col < cols; col++) {
        final xx = 6 + col * (r.width - 12) / math.max(1, cols - 1);
        _p.color = _a(((row + col + it.variant) % 6 == 0) ? const Color(0xFFE0703A) : crop, f);
        c.drawCircle(Offset(xx, yy - 2), 3.4, _p);
        _p.color = _a(lighten(crop, .25), f);
        c.drawCircle(Offset(xx - 1, yy - 3), 1.4, _p);
      }
    }
  }

  void _pond(Canvas c, Item it, double f, double e) {
    final r = Rect.fromLTWH(0, 0, it.w * e, it.d * e);
    _p.color = _a(const Color(0xFFCDB98F), f);
    c.drawOval(r.inflate(3), _p);
    _p.color = _a(const Color(0xFF3F8FCF), f);
    c.drawOval(r, _p);
    _p.color = _a(const Color(0xFF63B0E6), f);
    c.drawOval(r.deflate(8), _p);
    final t = game.animTime;
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _a(const Color(0x99FFFFFF), f);
    final rr = (t * 6) % 14;
    c.drawOval(Rect.fromCenter(center: r.center.translate(-8, 4), width: 6 + rr * 2, height: 4 + rr), _p);
    _p.style = PaintingStyle.fill;
    _p.color = _a(const Color(0xFF4E9A3A), f);
    c.drawCircle(r.center.translate(14, -6), 5, _p);
    c.drawCircle(r.center.translate(-18, 8), 4, _p);
    _p.color = _a(const Color(0xFFFF9EC4), f);
    c.drawCircle(r.center.translate(15, -7), 1.8, _p);
  }

  void _river(Canvas c, double e) {
    if (game.level < riverDay) return;
    final t = game.animTime;
    for (var i = 0; i < riverCells.length; i++) {
      final (cx, cy) = riverCells[i];
      if (game.tileRise(cx, cy) < 1) continue;
      _onGround(c, cx.toDouble(), cy.toDouble(), cx + .5, cy + .5, () {
        _p.color = const Color(0xFF2F7DC4);
        c.drawRect(Rect.fromLTWH(-1, -1, e + 2, e + 2), _p);
        _p.color = const Color(0xFF3D95DE);
        c.drawRect(Rect.fromLTWH(4, 4, e - 8, e - 8), _p);
        _p.color = const Color(0x88D6F0FF);
        for (var k = 0; k < 4; k++) {
          final off = (t * 14 + k * 9 + cx * 7) % e;
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(off * .7 + 2, k * 8.5 + 3, 10, 2), const Radius.circular(1)), _p);
        }
      });
      final last = i == riverCells.length - 1;
      final next = last ? null : riverCells[i + 1];
      final exits = last || (next!.$1 == cx + 1 && game.tileRise(next.$1, next.$2) < 1);
      if (exits) _waterfall(c, cx, cy);
    }
  }

  void _waterfall(Canvas c, int cx, int cy) {
    final dr = game.dropAt(cx + .5, cy + .5);
    if (dr > 0) return;
    final a = Iso.p(cx + 1.0, cy + 1.0), b = Iso.p(cx + 1.0, cy.toDouble());
    const len = 150.0;
    final path = Path()..addPolygon([a.translate(0, -1), b.translate(0, -1), b.translate(0, len), a.translate(0, len)], true);
    _p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Color(0xEE5FB0EE), Color(0xAA9AD3FF), Color(0x00FFFFFF)],
    ).createShader(Rect.fromPoints(b, a.translate(0, len)));
    c.drawPath(path, _p);
    _p.shader = null;
    final t = game.animTime;
    for (var k = 0; k < 6; k++) {
      final u = (k + .5) / 6;
      final top = Offset.lerp(a, b, u)!;
      final off = (t * 80 + k * 23) % len;
      line(c, top.translate(0, off), top.translate(0, off + 14), Color.fromRGBO(255, 255, 255, .7 * (1 - off / len)), 1.4);
    }
  }

  void _bridge(Canvas c, Item it, double f) {
    final dr = game.dropAt(it.x + .5, it.y + .5);
    if (dr > 500) return;
    c.save();
    c.translate(0, dr);
    final wood = _a(const Color(0xFF9A6A3E), f);
    for (var k = 0; k < 7; k++) {
      final x0 = it.x - .1 + k * .175;
      poly(c, [Iso.p(x0, it.y + .1, 4), Iso.p(x0 + .15, it.y + .1, 4), Iso.p(x0 + .15, it.y + .95, 4), Iso.p(x0, it.y + .95, 4)],
          k.isEven ? wood : darken(wood, .1));
    }
    for (final yy in [it.y + .1, it.y + .95]) {
      line(c, Iso.p(it.x - .1, yy, 4), Iso.p(it.x - .1, yy, 14), _a(const Color(0xFF6B4226), f), 2);
      line(c, Iso.p(it.x + 1.1, yy, 4), Iso.p(it.x + 1.1, yy, 14), _a(const Color(0xFF6B4226), f), 2);
      line(c, Iso.p(it.x - .1, yy, 14), Iso.p(it.x + 1.1, yy, 14), _a(const Color(0xFF7A4E2D), f), 1.6);
    }
    c.restore();
  }
}
