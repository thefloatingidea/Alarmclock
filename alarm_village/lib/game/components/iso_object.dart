import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../iso.dart';
import '../layout.dart';
import '../village_game.dart';

/// Base for anything standing on the island: depth-sorted, pops in when
/// unlocked and falls with its tile when the island crumbles.
abstract class IsoObject extends Component with HasGameReference<VillageGame> {
  IsoObject(this.item) : super(priority: ((item.x + item.w + item.y + item.d) * 100).round());

  final Item item;
  double get x => item.x;
  double get y => item.y;
  double get w => item.w;
  double get d => item.d;

  double appear = 0;

  @override
  void update(double dt) {
    final want = game.itemReady(item);
    appear = want ? math.min(1.0, appear + dt * 2.2) : math.max(0.0, appear - dt * 4);
    if (appear > 0) tick(dt);
  }

  void tick(double dt) {}

  @override
  void render(Canvas canvas) {
    if (appear <= 0) return;
    final dr = game.dropAt(x + w / 2, y + d / 2);
    if (dr > 700) return;
    canvas.save();
    canvas.translate(0, dr);
    if (appear < 1) {
      final base = Iso.p(x + w / 2, y + d / 2);
      final s = math.max(0.0, easeOutBack(appear));
      canvas.translate(base.dx, base.dy);
      canvas.scale(s, s);
      canvas.translate(-base.dx, -base.dy);
    }
    draw(canvas);
    canvas.restore();
  }

  void draw(Canvas canvas);
}
