import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../anchors.dart';
import '../constants.dart';
import '../logic/destruction_controller.dart';
import '../logic/fire_math.dart';

/// Draws one procedural flame (shaders/fire.frag) per fire point, plus a soft
/// additive glow. How many fires burn depends on progress and quality tier.
class FireLayer extends Component {
  FireLayer({
    required this.controller,
    required this.origin,
    required this.fires,
    required this.ruinAt,
  });

  final DestructionController controller;

  /// World position of the building's top-left corner.
  final Vector2 origin;
  final List<FirePoint> fires;

  /// Progress at which the building turns to ruins (building fires vanish).
  final double ruinAt;

  late final FragmentProgram _program;
  late final List<FragmentShader> _shaders;
  late final List<Paint> _paints;
  final Paint _debug = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFF00FFFF)
    ..strokeWidth = 1;
  double _time = 0;

  @override
  Future<void> onLoad() async {
    _program = await FragmentProgram.fromAsset('shaders/fire.frag');
    // One shader instance per fire: uniforms are set per draw call.
    _shaders = List.generate(fires.length, (_) => _program.fragmentShader());
    _paints = _shaders.map((s) => Paint()..shader = s).toList();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final progress = controller.progress.value;
    final maxFires = controller.quality.value.maxFires;
    final count = min(fires.length, maxFires);

    for (var i = 0; i < count; i++) {
      final fire = fires[i];
      final k = fireIntensity(
        progress: progress,
        appearAt: fire.appearAt,
        vanishAt: fire.onBuilding ? ruinAt : null,
      );
      if (k < 0.02) continue;

      final w = fire.size;
      final h = fire.size * 1.45;
      final base = Offset(origin.x + fire.x, origin.y + fire.y);

      // Soft additive glow behind the flame.
      final glowCenter = base.translate(0, -h * 0.35);
      canvas.drawCircle(
        glowCenter,
        w * (0.9 + 0.6 * k),
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = Gradient.radial(
            glowCenter,
            w * (0.9 + 0.6 * k),
            [
              Color.fromRGBO(255, 138, 42, 0.42 * k),
              const Color.fromRGBO(255, 138, 42, 0),
            ],
          ),
      );

      // Uniform order matches shaders/fire.frag:
      // uSize.x, uSize.y, uTime, uSeed, uIntensity
      _shaders[i]
        ..setFloat(0, w)
        ..setFloat(1, h)
        ..setFloat(2, _time)
        ..setFloat(3, i * 7.31)
        ..setFloat(4, k);

      canvas.save();
      canvas.translate(base.dx - w / 2, base.dy - h);
      final quad = Rect.fromLTWH(0, 0, w, h);
      canvas.drawRect(quad, _paints[i]);
      if (kDebugShaderBounds) canvas.drawRect(quad, _debug);
      canvas.restore();
    }
  }
}
