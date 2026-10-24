import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';

/// Floating island: grass tiles with tufts and flowers, layered cliffs, hanging roots.
class Island extends Component with HasGameReference<VillageGame> {
  Island() : super(priority: -100000);

  static const double depth = 80;
  static const _grassA = Color(0xFF6DB046);
  static const _grassB = Color(0xFF85C455);
  static const _burnt = Color(0xFF4A3A28);
  static const _bands = [Color(0xFF9A6440), Color(0xFF85543A), Color(0xFF6E4430)];
  static const _flowerCols = [Color(0xFFFFE066), Color(0xFFFF8FB1), Color(0xFFFFFFFF), Color(0xFFB39DFF)];

  late final List<double> _n1, _n2, _n3;

  @override
  Future<void> onLoad() async {
    final r = math.Random(3);
    _n1 = List.generate(gridN * gridN, (_) => r.nextDouble());
    _n2 = List.generate(gridN * gridN, (_) => r.nextDouble());
    _n3 = List.generate(gridN * gridN, (_) => r.nextDouble());
  }

  @override
  void render(Canvas c) {
    const n = gridN;
    final scorchAll = game.scorch;
    for (var s = 0; s <= 2 * (n - 1); s++) {
      for (var gx = 0; gx < n; gx++) {
        final gy = s - gx;
        if (gy < 0 || gy >= n) continue;
        final rise = game.tileRise(gx, gy);
        if (rise <= 0) continue;
        final fall = game.tileDrop(gx, gy);
        if (fall > 500) continue;
        final dr = fall + (1 - rise) * 90;
        final a = rise * (1 - fall / 500);
        Offset q(double x, double y, double z) => Iso.p(x, y, z).translate(0, dr);
        Color al(Color col) => col.withAlpha((a * 255).round());
        final x = gx.toDouble(), y = gy.toDouble();
        final k = gx * n + gy;
        // scorch spreads tile by tile
        final scorch = ((scorchAll * 1.6 - _n2[k] * .6)).clamp(0.0, .8);

        final frontOpen = game.tileRise(gx, gy + 1) < 1 || game.tileDrop(gx, gy + 1) > fall;
        final rightOpen = game.tileRise(gx + 1, gy) < 1 || game.tileDrop(gx + 1, gy) > fall;
        if (frontOpen) _cliff(c, q(x, y + 1, 0), q(x + 1, y + 1, 0), 0, k, al);
        if (rightOpen) _cliff(c, q(x + 1, y + 1, 0), q(x + 1, y, 0), .22, k + 7, al);

        final grass = Color.lerp(Color.lerp(_grassA, _grassB, _n1[k])!, _burnt, scorch)!;
        poly(c, [q(x, y, 0), q(x + 1, y, 0), q(x + 1, y + 1, 0), q(x, y + 1, 0)], al(grass));
        if ((gx + gy).isEven) {
          poly(c, [q(x, y, 0), q(x + 1, y, 0), q(x + 1, y + 1, 0), q(x, y + 1, 0)], al(const Color(0x0A000000)));
        }
        if (a < .5) continue;
        if (scorch > .5 && _n3[k] > .6) {
          // embers on burnt ground
          final p = q(x + .5, y + .5, 0);
          final e = Paint()..color = al(Color.fromRGBO(255, 120, 30, .5 + .5 * math.sin(game.animTime * 5 + k)));
          c.drawCircle(p, 1.6, e);
          continue;
        }
        final tuft = al(darken(grass, .25));
        for (var t = 0; t < 2; t++) {
          final p = q(x + .2 + _n2[k] * .6 * (t == 0 ? 1 : .4), y + .2 + _n3[k] * .6 * (t == 0 ? .5 : 1), 0);
          line(c, p, p.translate(-1.5, -4), tuft, 1);
          line(c, p, p.translate(1.5, -4.5), tuft, 1);
          line(c, p, p.translate(0, -5), tuft, 1);
        }
        if (scorch < .2 && game.level >= 2 + (_n1[k] * 40).floor()) {
          final col = _flowerCols[(k * 7) % _flowerCols.length];
          for (var f = 0; f < 3; f++) {
            final p = q(x + .25 + ((_n2[k] + f * .31) % 1) * .5, y + .25 + ((_n3[k] + f * .43) % 1) * .5, 0);
            line(c, p, p.translate(0, -3), al(const Color(0xFF3E7A2C)), 1);
            c.drawCircle(p.translate(0, -3.5), 1.6, Paint()..color = al(col));
          }
        }
      }
    }
  }

  void _cliff(Canvas c, Offset a, Offset b, double shade, int seed, Color Function(Color) al) {
    Offset dn(Offset p, double z) => p.translate(0, z);
    poly(c, [a, b, dn(b, 7), dn(a, 7)], al(darken(_grassA, .2 + shade)));
    final cuts = [7.0, 28.0, 52.0, depth];
    for (var i = 0; i < 3; i++) {
      poly(c, [dn(a, cuts[i]), dn(b, cuts[i]), dn(b, cuts[i + 1]), dn(a, cuts[i + 1])], al(darken(_bands[i], shade)));
    }
    final r = math.Random(seed);
    for (var i = 0; i < 3; i++) {
      final p = Offset.lerp(a, b, .15 + r.nextDouble() * .7)!.translate(0, 12 + r.nextDouble() * (depth - 20));
      c.drawOval(Rect.fromCenter(center: p, width: 5 + r.nextDouble() * 4, height: 3 + r.nextDouble() * 2),
          Paint()..color = al(darken(const Color(0xFFB8A48C), shade + r.nextDouble() * .2)));
    }
    final root = al(const Color(0xFF4A2E1E));
    for (var i = 0; i < 2; i++) {
      final p = dn(Offset.lerp(a, b, .2 + r.nextDouble() * .6)!, depth);
      line(c, p, p.translate(r.nextDouble() * 4 - 2, 6 + r.nextDouble() * 14), root, 1.2);
    }
  }
}
