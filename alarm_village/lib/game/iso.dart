import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Isometric projection helpers. Grid (gx, gy) -> screen; z is height in px.
class Iso {
  static const double halfW = 32;
  static const double halfH = 16;
  static final double edge = math.sqrt(halfW * halfW + halfH * halfH);
  static final double _ax = halfW / edge;
  static final double _ay = halfH / edge;

  static Offset p(double gx, double gy, [double z = 0]) => Offset((gx - gy) * halfW, (gx + gy) * halfH - z);

  static Float64List _m(double a, double b, double c, double d, Offset o) =>
      Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, o.dx, o.dy, 0, 1]);

  static Float64List ground(Offset o) => _m(_ax, _ay, -_ax, _ay, o);
  static Float64List leftWall(Offset o) => _m(_ax, _ay, 0, 1, o);
  static Float64List rightWall(Offset o) => _m(_ax, -_ay, 0, 1, o);
}

final Paint _fill = Paint()..isAntiAlias = true;
final Paint _line = Paint()
  ..isAntiAlias = true
  ..style = PaintingStyle.stroke;

void poly(Canvas c, List<Offset> pts, Color color) {
  _fill
    ..color = color
    ..shader = null
    ..maskFilter = null;
  c.drawPath(Path()..addPolygon(pts, true), _fill);
}

void line(Canvas c, Offset a, Offset b, Color color, [double w = 1]) {
  _line
    ..color = color
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;
  c.drawLine(a, b, _line);
}

Color darken(Color c, double t) => Color.lerp(c, const Color(0xFF000000), t)!;
Color lighten(Color c, double t) => Color.lerp(c, const Color(0xFFFFFFFF), t)!;

double easeOutBack(double t) {
  const c1 = 1.70158, c3 = c1 + 1;
  final u = t - 1;
  return 1 + c3 * u * u * u + c1 * u * u;
}

void groundShadow(Canvas c, double gx, double gy, double w, double d, [double a = 0.22]) {
  _fill
    ..shader = null
    ..color = Color.fromRGBO(0, 0, 0, a)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  c.drawPath(
      Path()
        ..addPolygon([
          Iso.p(gx, gy + .15),
          Iso.p(gx + w + .25, gy + .15),
          Iso.p(gx + w + .25, gy + d + .2),
          Iso.p(gx, gy + d + .2),
        ], true),
      _fill);
  _fill.maskFilter = null;
}

void isoBox(Canvas c,
    {required double x,
    required double y,
    required double w,
    required double d,
    double z = 0,
    required double h,
    required Color color,
    Color? top,
    bool edges = true}) {
  final x1 = x + w, y1 = y + d, zt = z + h;
  poly(c, [Iso.p(x, y1, z), Iso.p(x1, y1, z), Iso.p(x1, y1, zt), Iso.p(x, y1, zt)], color);
  poly(c, [Iso.p(x1, y1, z), Iso.p(x1, y, z), Iso.p(x1, y, zt), Iso.p(x1, y1, zt)], darken(color, .22));
  poly(c, [Iso.p(x, y, zt), Iso.p(x1, y, zt), Iso.p(x1, y1, zt), Iso.p(x, y1, zt)], top ?? lighten(color, .15));
  if (edges && h > 3) {
    final hi = lighten(color, .35).withAlpha(160);
    line(c, Iso.p(x, y1, zt), Iso.p(x1, y1, zt), hi, .8);
    line(c, Iso.p(x1, y1, zt), Iso.p(x1, y, zt), hi, .8);
    line(c, Iso.p(x1, y1, z), Iso.p(x1, y1, zt), darken(color, .1).withAlpha(120), .8);
  }
}

void isoPyramid(Canvas c,
    {required double x,
    required double y,
    required double w,
    required double d,
    double z = 0,
    required double h,
    required Color color}) {
  final apex = Iso.p(x + w / 2, y + d / 2, z + h);
  poly(c, [Iso.p(x, y + d, z), Iso.p(x + w, y + d, z), apex], color);
  poly(c, [Iso.p(x + w, y + d, z), Iso.p(x + w, y, z), apex], darken(color, .25));
}

void isoGableRoof(Canvas c,
    {required double x,
    required double y,
    required double w,
    required double d,
    required double z,
    required double h,
    required Color roof,
    required Color wall,
    void Function()? between}) {
  const o = 0.12;
  final x0 = x - o, x1 = x + w + o, y0 = y - o, y1 = y + d + o, ym = y + d / 2;
  final r0 = Iso.p(x0, ym, z + h), r1 = Iso.p(x1, ym, z + h);
  poly(c, [Iso.p(x0, y0, z), Iso.p(x1, y0, z), r1, r0], darken(roof, .3));
  poly(c, [Iso.p(x + w, y, z), Iso.p(x + w, y + d, z), Iso.p(x + w, ym, z + h)], darken(wall, .22));
  line(c, Iso.p(x + w, y, z), Iso.p(x + w, ym, z + h), darken(wall, .45), 1);
  line(c, Iso.p(x + w, y + d, z), Iso.p(x + w, ym, z + h), darken(wall, .45), 1);
  between?.call();
  final e0 = Iso.p(x0, y1, z), e1 = Iso.p(x1, y1, z);
  poly(c, [e0, e1, r1, r0], roof);
  final sh = darken(roof, .22).withAlpha(170);
  for (var k = 1; k <= 4; k++) {
    final t = k / 5;
    line(c, Offset.lerp(e0, r0, t)!, Offset.lerp(e1, r1, t)!, sh, .9);
  }
  line(c, r0, r1, lighten(roof, .3), 1.6);
  line(c, e0, e1, darken(roof, .4), 1.2);
}

const _digitMask = [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F];
final Paint _seg = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

void drawDigit(Canvas c, int digit, Rect r, Color color, {double stroke = 6}) {
  final l = r.left, t = r.top, ri = r.right, b = r.bottom, m = (t + b) / 2;
  final segs = [
    [Offset(l, t), Offset(ri, t)],
    [Offset(ri, t), Offset(ri, m)],
    [Offset(ri, m), Offset(ri, b)],
    [Offset(l, b), Offset(ri, b)],
    [Offset(l, m), Offset(l, b)],
    [Offset(l, t), Offset(l, m)],
    [Offset(l, m), Offset(ri, m)],
  ];
  final mask = _digitMask[digit.clamp(0, 9)];
  _seg
    ..strokeWidth = stroke
    ..maskFilter = null
    ..color = const Color(0x22FFFFFF);
  for (final s in segs) {
    c.drawLine(s[0], s[1], _seg);
  }
  for (var i = 0; i < 7; i++) {
    if (mask & (1 << i) == 0) continue;
    final s = segs[i];
    _seg
      ..strokeWidth = stroke * 2.4
      ..color = color.withAlpha(130)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    c.drawLine(s[0], s[1], _seg);
    _seg
      ..strokeWidth = stroke
      ..color = color
      ..maskFilter = null;
    c.drawLine(s[0], s[1], _seg);
    _seg
      ..strokeWidth = stroke * 0.35
      ..color = lighten(color, .7);
    c.drawLine(s[0], s[1], _seg);
  }
}

final Paint _fire = Paint()..isAntiAlias = true;

void drawFlames(Canvas c, Offset base, double scale, double t, int seed) {
  _fire
    ..color = const Color(0x66FF7A00)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  c.drawCircle(base.translate(0, -8 * scale), 24 * scale, _fire);
  _fire.maskFilter = null;
  for (var i = 0; i < 3; i++) {
    final flick = math.sin(t * 14 + i * 2.1 + seed) * 0.18 + 0.85;
    final h = 24 * scale * flick, wd = 8 * scale;
    final bx = base.dx + (i - 1) * 8 * scale;
    Path flame(double k) => Path()
      ..moveTo(bx - wd * k, base.dy)
      ..quadraticBezierTo(bx - wd * k * .8, base.dy - h * k * .5, bx + math.sin(t * 9 + i) * 2, base.dy - h * k)
      ..quadraticBezierTo(bx + wd * k * .8, base.dy - h * k * .5, bx + wd * k, base.dy)
      ..close();
    _fire.color = const Color(0xFFFF5A1F);
    c.drawPath(flame(1), _fire);
    _fire.color = const Color(0xFFFFC23D);
    c.drawPath(flame(.55), _fire);
  }
}

class Puffs {
  final List<_Puff> _list = [];
  double _acc = 0;
  final math.Random _r = math.Random();

  void update(double dt, Offset? source, {double rate = 0.7, bool dark = false}) {
    if (source != null) {
      _acc += dt;
      while (_acc > rate) {
        _acc -= rate;
        _list.add(_Puff(source.translate(_r.nextDouble() * 4 - 2, 0), dark, 2 + _r.nextDouble() * 1.5));
      }
    }
    for (final p in _list) {
      p.age += dt;
      p.pos = p.pos.translate(5 * dt, -(dark ? 26 : 16) * dt);
    }
    _list.removeWhere((p) => p.age > p.life);
  }

  void render(Canvas c) {
    for (final p in _list) {
      final k = p.age / p.life;
      _fill
        ..shader = null
        ..maskFilter = null
        ..color = (p.dark ? const Color(0xFF3A3330) : const Color(0xFFEDEDED)).withAlpha(((1 - k) * 150).round());
      c.drawCircle(p.pos, 3 + k * (p.dark ? 12 : 7), _fill);
    }
  }
}

class _Puff {
  _Puff(this.pos, this.dark, this.life);
  Offset pos;
  final bool dark;
  final double life;
  double age = 0;
}
