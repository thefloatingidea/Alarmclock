import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

/// One SVG state of a building with an adjustable opacity.
///
/// Opacity is applied with a saved layer so the whole SVG fades as one image
/// (no see-through overlaps between its shapes).
class FadeLayer extends PositionComponent {
  FadeLayer({required Svg svg, required Vector2 size}) : super(size: size) {
    add(SvgComponent(svg: svg, size: size));
  }

  double opacity = 0;

  @override
  void renderTree(Canvas canvas) {
    if (opacity <= 0.001) return;
    if (opacity >= 0.999) {
      super.renderTree(canvas);
      return;
    }
    canvas.saveLayer(
      toRect().inflate(4),
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    super.renderTree(canvas);
    canvas.restore();
  }
}
