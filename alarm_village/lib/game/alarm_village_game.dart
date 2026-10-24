import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'constants.dart';
import 'logic/destruction_controller.dart';
import 'world/village_world.dart';

class AlarmVillageGame extends FlameGame {
  AlarmVillageGame({required this.controller})
      : super(
          world: VillageWorld(controller: controller),
          camera: CameraComponent.withFixedResolution(
            width: kVillageWidth,
            height: kVillageHeight,
          ),
        );

  final DestructionController controller;

  @override
  Color backgroundColor() => const Color(0xFF12141C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.world = world;
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
  }
}
