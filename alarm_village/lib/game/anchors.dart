import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// One place a fire can burn, in the building's own canvas units
/// (origin = top-left of the SVG canvas).
class FirePoint {
  const FirePoint({
    required this.x,
    required this.y,
    required this.appearAt,
    required this.size,
    required this.onBuilding,
  });

  final double x;
  final double y;

  /// Progress value at which this fire starts.
  final double appearAt;

  /// Width of the flame quad in canvas units.
  final double size;

  /// True for fires on the roof or walls. They fade out when the building
  /// turns to ruins; ground fires keep smouldering in the rubble.
  final bool onBuilding;
}

/// Anchor data shipped next to each building's SVGs (assets/anchors/*.json).
class BuildingAnchors {
  const BuildingAnchors({required this.canvas, required this.fires});

  final Vector2 canvas;
  final List<FirePoint> fires;

  static Future<BuildingAnchors> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final canvas = (json['canvas'] as List).cast<num>();
    final fires = (json['fire_points'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return FirePoint(
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        appearAt: (m['appear_at'] as num).toDouble(),
        size: (m['size'] as num).toDouble(),
        onBuilding: (m['on_building'] as bool?) ?? false,
      );
    }).toList()
      ..sort((a, b) => a.appearAt.compareTo(b.appearAt));
    return BuildingAnchors(
      canvas: Vector2(canvas[0].toDouble(), canvas[1].toDouble()),
      fires: fires,
    );
  }
}
