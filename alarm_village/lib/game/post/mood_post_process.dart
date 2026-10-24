import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/post_process.dart';

import '../logic/destruction_controller.dart';

/// Whole-scene colour grade driven by shaders/mood.frag.
///
/// Wrap the village in a PostProcessComponent with this post process. The
/// subtree is rasterised, then the shader grades it (dusk, burn, ruin, heat
/// haze, vignette) using the controller's progress and dusk values.
class MoodPostProcess extends PostProcess {
  MoodPostProcess({required this.controller});

  final DestructionController controller;

  late final FragmentProgram _program;
  late final FragmentShader _shader = _program.fragmentShader();
  late final Paint _paint = Paint()..shader = _shader;
  double _time = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _program = await FragmentProgram.fromAsset('shaders/mood.frag');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    final scene = rasterizeSubtree();
    // Uniform order matches shaders/mood.frag:
    // uSize (2), uProgress, uDusk, uTime, uHaze, then sampler 0.
    _shader.setFloatUniforms((value) {
      value
        ..setVector(size)
        ..setFloat(controller.progress.value)
        ..setFloat(controller.dusk.value)
        ..setFloat(_time)
        ..setFloat(controller.quality.value.heatHaze ? 1.0 : 0.0);
    });
    _shader.setImageSampler(0, scene);
    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}
