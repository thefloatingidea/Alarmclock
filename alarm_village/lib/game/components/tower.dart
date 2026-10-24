import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import 'iso_object.dart';

/// The clock tower - the heart of the island and the only thing there on day 0.
/// Front-left wall: large analog clock. Front-right wall: digital HH:MM.
class ClockTower extends IsoObject {
  ClockTower() : super(const Item(Kind.tower, 0, 6.5, 6.5, w: 3, d: 3));

  static const double base = 12, bodyTop = 150, corniceH = 8, belfryH = 36, spireH = 64;
  static double get spireTipZ => bodyTop + corniceH + belfryH + spireH;

  final Paint _p = Paint()..isAntiAlias = true;
  late final List<TextPainter> _numerals = [
    for (final s in const ['12', '3', '6', '9'])
      TextPainter(
        text: TextSpan(text: s, style: const TextStyle(color: Color(0xFF3B2A1C), fontSize: 9, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];
  TextPainter? _ampm;
  String _ampmText = '';

  @override
  void draw(Canvas c) {
    final gold = game.gold;
    const stone = Color(0xFFB3AC9F);
    final trim = gold ? const Color(0xFFE2B33C) : const Color(0xFF8E887C);
    final roof = gold ? const Color(0xFFD9A72E) : const Color(0xFF3F5E86);
    final soot = game.scorch * .35;
    final st = darken(stone, soot);

    groundShadow(c, x, y, w, d, .3);
    isoBox(c, x: x - .18, y: y - .18, w: w + .36, d: d + .36, h: base, color: const Color(0xFF8E887C));
    isoBox(c, x: x + 1.15, y: y + d + .18, w: .7, d: .25, h: 4, color: const Color(0xFF8E887C));
    isoBox(c, x: x, y: y, w: w, d: d, z: base, h: bodyTop - base, color: st);
    for (var i = 0; i < 7; i++) {
      final z = base + 6 + i * 19.0;
      isoBox(c, x: x + w - .2, y: y + d - .2, w: .22, d: .22, z: z, h: 9, color: lighten(st, .12), edges: false);
    }

    final faceW = w * Iso.edge;
    const wallH = bodyTop - base;

    c.save();
    c.transform(Iso.leftWall(Iso.p(x, y + d, bodyTop)));
    _bricks(c, faceW, wallH);
    _door(c, faceW, wallH);
    _analog(c, Offset(faceW / 2, 50), 38, gold);
    c.restore();

    c.save();
    c.transform(Iso.rightWall(Iso.p(x + w, y + d, bodyTop)));
    _bricks(c, faceW, wallH);
    _digital(c, faceW);
    for (var i = 0; i < 2; i++) {
      _archWindow(c, Rect.fromLTWH(faceW * (.3 + i * .4) - 6, 92, 12, 20));
    }
    c.restore();

    isoBox(c, x: x - .14, y: y - .14, w: w + .28, d: d + .28, z: bodyTop, h: corniceH, color: trim);
    for (var i = 0; i < 6; i++) {
      final t = i * (w + .2) / 5 - .12;
      isoBox(c, x: x + t, y: y + d - .1, w: .22, d: .22, z: bodyTop + corniceH, h: 7, color: st, edges: false);
      isoBox(c, x: x + w - .1, y: y + t, w: .22, d: .22, z: bodyTop + corniceH, h: 7, color: st, edges: false);
    }
    const bz = bodyTop + corniceH;
    isoBox(c, x: x + .55, y: y + .55, w: w - 1.1, d: d - 1.1, z: bz, h: belfryH, color: st);
    final bw = (w - 1.1) * Iso.edge;
    for (final wallFn in [
      Iso.leftWall(Iso.p(x + .55, y + d - .55, bz + belfryH)),
      Iso.rightWall(Iso.p(x + w - .55, y + d - .55, bz + belfryH)),
    ]) {
      c.save();
      c.transform(wallFn);
      final arch = Rect.fromLTWH(bw / 2 - 11, 7, 22, 26);
      _p.color = const Color(0xFF2B2622);
      c.drawRRect(RRect.fromRectAndCorners(arch, topLeft: const Radius.circular(11), topRight: const Radius.circular(11)), _p);
      final swing = game.ringing ? math.sin(game.animTime * 9) * .35 : 0.0;
      c.save();
      c.translate(bw / 2, 11);
      c.rotate(swing);
      _p.color = const Color(0xFFD9A441);
      c.drawPath(
          Path()
            ..moveTo(-6, 14)
            ..quadraticBezierTo(-6, 0, 0, 0)
            ..quadraticBezierTo(6, 0, 6, 14)
            ..close(),
          _p);
      _p.color = const Color(0xFFF2CE73);
      c.drawRect(const Rect.fromLTWH(-3, 3, 1.5, 8), _p);
      c.restore();
      c.restore();
    }
    isoBox(c, x: x + .45, y: y + .45, w: w - .9, d: d - .9, z: bz + belfryH, h: 5, color: trim);
    isoPyramid(c, x: x + .5, y: y + .5, w: w - 1, d: d - 1, z: bz + belfryH + 5, h: spireH - 5, color: roof);
    final tip = Iso.p(x + w / 2, y + d / 2, spireTipZ);
    line(c, tip, tip.translate(0, -22), const Color(0xFF4A3B2E), 1.6);
    final wave = math.sin(game.animTime * 4) * 2;
    poly(c, [tip.translate(0, -22), tip.translate(16, -18 + wave), tip.translate(0, -13)],
        gold ? const Color(0xFFFFD54F) : const Color(0xFFE85D3F));
    if (game.ringing) {
      final pulse = .5 + .5 * math.sin(game.animTime * 10);
      _p
        ..color = Color.fromRGBO(255, 40, 30, .5 + .4 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      c.drawCircle(tip.translate(0, -6), 20 + 10 * pulse, _p);
      _p.maskFilter = null;
    }
    if (gold) {
      for (var i = 0; i < 8; i++) {
        final a = Iso.p(x + i * w / 8, y + d + .02, bodyTop - 2);
        final b = Iso.p(x + (i + 1) * w / 8, y + d + .02, bodyTop - 2);
        poly(c, [a, b, Offset.lerp(a, b, .5)!.translate(0, 7)], i.isEven ? const Color(0xFFFFD54F) : const Color(0xFFE85D3F));
      }
    }
  }

  void _bricks(Canvas c, double fw, double h) {
    _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = const Color(0x26000000);
    var row = 0;
    for (var yy = 9.0; yy < h; yy += 9, row++) {
      c.drawLine(Offset(0, yy), Offset(fw, yy), _p);
      for (var xx = row.isEven ? 0.0 : 9.0; xx < fw; xx += 18) {
        c.drawLine(Offset(xx, yy - 9), Offset(xx, yy), _p);
      }
    }
    _p.style = PaintingStyle.fill;
  }

  void _door(Canvas c, double fw, double h) {
    final r = Rect.fromLTWH(fw / 2 - 12, h - 34, 24, 34);
    _p.color = const Color(0xFF7D766A);
    c.drawRRect(RRect.fromRectAndCorners(r.inflate(3), topLeft: const Radius.circular(15), topRight: const Radius.circular(15)), _p);
    _p.color = const Color(0xFF6B4226);
    c.drawRRect(RRect.fromRectAndCorners(r, topLeft: const Radius.circular(12), topRight: const Radius.circular(12)), _p);
    for (var i = 1; i < 4; i++) {
      line(c, Offset(r.left + i * r.width / 4, r.top + 4), Offset(r.left + i * r.width / 4, r.bottom), const Color(0xFF4A2E1C), 1);
    }
    _p.color = const Color(0xFFE8C46A);
    c.drawCircle(Offset(r.right - 5, r.center.dy + 3), 1.6, _p);
    for (final lx in [r.left - 8, r.right + 8]) {
      _p.color = const Color(0xFF3B3B3B);
      c.drawRect(Rect.fromCenter(center: Offset(lx, r.top + 8), width: 5, height: 7), _p);
      if (game.nightness > .3) {
        _p
          ..color = const Color(0xAAFFD27A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        c.drawCircle(Offset(lx, r.top + 8), 7, _p);
        _p.maskFilter = null;
      }
      _p.color = const Color(0xFFFFD27A);
      c.drawRect(Rect.fromCenter(center: Offset(lx, r.top + 8), width: 3, height: 4), _p);
    }
  }

  void _analog(Canvas c, Offset ctr, double r, bool gold) {
    final night = game.nightness;
    if (night > .3 || game.ringing) {
      _p
        ..color = (game.ringing ? const Color(0xFFFF5A3D) : const Color(0xFFFFE3A0)).withAlpha(150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      c.drawCircle(ctr, r + 8, _p);
      _p.maskFilter = null;
    }
    _p.color = gold ? const Color(0xFFE2B33C) : const Color(0xFF6E675E);
    c.drawCircle(ctr, r + 6, _p);
    _p.color = gold ? const Color(0xFFFFE08A) : const Color(0xFF9C968A);
    c.drawCircle(ctr, r + 3, _p);
    _p.color = Color.lerp(const Color(0xFFF7F0DE), const Color(0xFFFFF1C2), night)!;
    c.drawCircle(ctr, r, _p);
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * 2 * math.pi;
      final dir = Offset(math.sin(a), -math.cos(a));
      final major = i % 5 == 0;
      line(c, ctr + dir * (r - (major ? 7 : 3.5)), ctr + dir * (r - 1.5), const Color(0xFF3B2A1C), major ? 2 : .8);
    }
    final pos = [Offset(0, -r + 13), Offset(r - 13, 0), Offset(0, r - 13), Offset(-r + 13, 0)];
    for (var i = 0; i < 4; i++) {
      final tp = _numerals[i];
      tp.paint(c, ctr + pos[i] - Offset(tp.width / 2, tp.height / 2));
    }
    final now = game.wallNow;
    final sec = now.second + now.millisecond / 1000;
    final mA = (now.minute + sec / 60) / 60 * 2 * math.pi;
    final hA = ((now.hour % 12) + now.minute / 60) / 12 * 2 * math.pi;
    final sA = sec / 60 * 2 * math.pi;
    Offset dir(double a) => Offset(math.sin(a), -math.cos(a));
    line(c, ctr + dir(hA) * -4, ctr + dir(hA) * (r * .5), const Color(0xFF2B1D12), 4);
    line(c, ctr + dir(mA) * -5, ctr + dir(mA) * (r * .8), const Color(0xFF2B1D12), 2.6);
    line(c, ctr + dir(sA) * -7, ctr + dir(sA) * (r * .86), const Color(0xFFD83A2A), 1.1);
    _p.color = const Color(0xFF2B1D12);
    c.drawCircle(ctr, 3.2, _p);
    _p.color = const Color(0xFFD83A2A);
    c.drawCircle(ctr, 1.5, _p);
  }

  void _digital(Canvas c, double fw) {
    final now = game.wallNow;
    final h12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final panel = Rect.fromLTWH(7, 16, fw - 14, 52);
    _p.color = const Color(0xFF6E675E);
    c.drawRRect(RRect.fromRectAndRadius(panel.inflate(3), const Radius.circular(8)), _p);
    _p.color = const Color(0xFF1E1A16);
    c.drawRRect(RRect.fromRectAndRadius(panel, const Radius.circular(6)), _p);
    const dw = 15.0, dh = 30.0, gap = 5.0, colon = 8.0;
    const total = dw * 4 + gap * 2 + colon * 2;
    var cx = panel.left + (panel.width - total) / 2;
    const top = 23.0;
    final col = game.digitColor;
    final digits = [h12 ~/ 10, h12 % 10, -1, now.minute ~/ 10, now.minute % 10];
    for (var i = 0; i < digits.length; i++) {
      final dg = digits[i];
      if (dg == -1) {
        final on = now.second.isEven || game.ringing;
        _p.color = on ? col : col.withAlpha(60);
        c.drawCircle(Offset(cx + colon, top + dh * .3), 2, _p);
        c.drawCircle(Offset(cx + colon, top + dh * .7), 2, _p);
        cx += colon * 2;
        continue;
      }
      if (!(i == 0 && dg == 0)) drawDigit(c, dg, Rect.fromLTWH(cx, top, dw, dh), col, stroke: 3.6);
      cx += dw + gap;
    }
    final txt = now.hour < 12 ? 'AM' : 'PM';
    if (_ampm == null || _ampmText != txt) {
      _ampmText = txt;
      _ampm = TextPainter(
        text: TextSpan(text: txt, style: const TextStyle(color: Color(0xFFFFC46B), fontSize: 8, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    _ampm!.paint(c, Offset(panel.right - _ampm!.width - 5, panel.bottom - _ampm!.height - 2));
  }

  void _archWindow(Canvas c, Rect r) {
    final lit = game.nightness > .4;
    _p.color = const Color(0xFF7D766A);
    c.drawRRect(RRect.fromRectAndCorners(r.inflate(2), topLeft: const Radius.circular(8), topRight: const Radius.circular(8)), _p);
    _p.color = lit ? const Color(0xFFFFD27A) : const Color(0xFF3E4A5A);
    c.drawRRect(RRect.fromRectAndCorners(r, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)), _p);
    line(c, Offset(r.center.dx, r.top + 2), Offset(r.center.dx, r.bottom), const Color(0xFF7D766A), 1);
  }
}
