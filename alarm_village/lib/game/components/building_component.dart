import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';

import '../logic/building_state.dart';
import '../logic/destruction_controller.dart';
import 'fade_layer.dart';

/// A building made of stacked SVG states that cross-fade as the destruction
/// progress crosses its thresholds.
///
/// Files are loaded as svg/<assetName>_<state>.svg (under assets/images/).
class BuildingComponent extends PositionComponent {
  BuildingComponent({
    required this.assetName,
    required this.controller,
    required this.thresholds,
    required Vector2 size,
    required Vector2 bottomCenter,
    this.fadeSeconds = 0.6,
  }) : super(size: size, position: bottomCenter, anchor: Anchor.bottomCenter);

  final String assetName;
  final DestructionController controller;
  final BuildingThresholds thresholds;
  final double fadeSeconds;

  final Map<BuildingState, FadeLayer> _layers = {};
  late BuildingState _target;
  int _topPriority = 0;

  BuildingState _resolve() => resolveBuildingState(
        progress: controller.progress.value,
        dusk: controller.dusk.value,
        thresholds: thresholds,
      );

  @override
  Future<void> onLoad() async {
    _target = _resolve();
    for (final state in BuildingState.values) {
      final svg = await Svg.load('svg/${assetName}_${state.name}.svg');
      final layer = FadeLayer(svg: svg, size: size)
        ..opacity = state == _target ? 1 : 0;
      _layers[state] = layer;
      await add(layer);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_layers.isEmpty) return;

    final next = _resolve();
    if (next != _target) {
      _target = next;
      // The incoming state is drawn on top while it fades in.
      _layers[next]!.priority = ++_topPriority;
    }

    final step = dt / fadeSeconds;
    final top = _layers[_target]!;
    top.opacity = min(1.0, top.opacity + step);

    // Older states only fade out once the new one is fully opaque, so the
    // building never goes see-through mid-transition.
    if (top.opacity >= 1) {
      for (final entry in _layers.entries) {
        if (entry.key != _target) {
          entry.value.opacity = max(0.0, entry.value.opacity - step);
        }
      }
    }
  }
}
