import 'package:flame/components.dart';
import 'package:flame/post_process.dart';

import '../anchors.dart';
import '../components/building_component.dart';
import '../components/fire_layer.dart';
import '../components/ground_component.dart';
import '../constants.dart';
import '../logic/building_state.dart';
import '../logic/destruction_controller.dart';
import '../post/mood_post_process.dart';

/// Proof-of-concept world: ground + one cottage + fire, all inside one
/// post-process so the mood shader grades everything together.
class VillageWorld extends World {
  VillageWorld({required this.controller});

  final DestructionController controller;

  @override
  Future<void> onLoad() async {
    final anchors = await BuildingAnchors.load('assets/anchors/cottage.json');

    // Demo thresholds: damaged at 25%, ruined at 60%.
    // Use BuildingThresholds.seeded(id) for a real village.
    const thresholds = BuildingThresholds(damageAt: 0.25, ruinAt: 0.60);

    final bottomCenter = Vector2(kVillageWidth / 2, 400);
    final buildingTopLeft =
        bottomCenter - Vector2(anchors.canvas.x / 2, anchors.canvas.y);

    final scene = PostProcessComponent(
      postProcess: MoodPostProcess(controller: controller),
      size: Vector2(kVillageWidth, kVillageHeight),
      children: [
        GroundComponent(
          size: Vector2(kVillageWidth, kVillageHeight),
          pathX: bottomCenter.x,
          pathTop: bottomCenter.y - 6,
        ),
        BuildingComponent(
          assetName: 'building_cottage',
          controller: controller,
          thresholds: thresholds,
          size: anchors.canvas,
          bottomCenter: bottomCenter,
        ),
        FireLayer(
          controller: controller,
          origin: buildingTopLeft,
          fires: anchors.fires,
          ruinAt: thresholds.ruinAt,
        ),
      ],
    );
    await add(scene);
  }
}
