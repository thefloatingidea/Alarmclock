import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Flat grass background with soft patches and a dirt path to the door.
/// Drawn in code for the proof of concept; replaced by SVG ground art later.
class GroundComponent extends PositionComponent {
  GroundComponent({
    required Vector2 size,
    required this.pathX,
    required this.pathTop,
  }) : super(size: size);

  final double pathX;
  final double pathTop;

  final Paint _grass = Paint()..color = const Color(0xFF8FD16A);
  final Paint _dark = Paint()..color = const Color(0xFF7CC45A);
  final Paint _light = Paint()..color = const Color(0xFFA6DE7C);
  final Paint _path = Paint()..color = const Color(0xFFE3C48A);
  final Paint _pebble = Paint()..color = const Color(0xFFD4B176);

  final List<(Offset, double, double, bool)> _patches = [];

  @override
  Future<void> onLoad() async {
    final r = Random(5);
    for (var i = 0; i < 60; i++) {
      _patches.add((
        Offset(r.nextDouble() * size.x, r.nextDouble() * size.y),
        10 + r.nextDouble() * 18,
        6 + r.nextDouble() * 10,
        r.nextBool(),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & Size(size.x, size.y), _grass);
    for (final (c, rx, ry, dark) in _patches) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
        dark ? _dark : _light,
      );
    }
    canvas.drawRRect(
      RRect.fromLTRBR(pathX - 18, pathTop, pathX + 18, size.y + 8,
          const Radius.circular(14)),
      _path,
    );
    for (final dy in [30.0, 62.0, 94.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pathX + (dy % 2 == 0 ? -6 : 7), pathTop + dy), width: 8, height: 4),
        _pebble,
      );
    }
  }
}
