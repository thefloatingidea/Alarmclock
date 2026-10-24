import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../alarm/alarm_engine.dart';
import '../state/village_state.dart';
import 'components/building.dart';
import 'components/villager.dart';
import 'destruction.dart';
import 'iso.dart';
import 'layout.dart';
import 'monsters/monster.dart';
import 'talk.dart';
import 'village_world.dart';

enum BuildState { normal, ruin }

class BuildingStatus {
  const BuildingStatus(this.state, {this.burn = 0, this.collapse = 0, this.burning = false});
  final BuildState state;
  final double burn;
  final double collapse;
  final bool burning;
}

class VillageGame extends FlameGame<VillageWorld> with ScaleDetector, ScrollDetector {
  VillageGame({required this.village, required this.engine}) : super(world: VillageWorld());

  final VillageState village;
  final AlarmEngine engine;

  final Map<int, Building> buildings = {};
  final List<Villager> villagers = [];
  Monster? monster;

  double animTime = 0;
  bool ringing = false;
  double elapsed = 0;
  Offset? breathTarget;

  /// Seconds left of the restore-rain effect.
  double rainT = 0;
  late int _rainSeen = village.rainSerial;

  /// Flash on the shield when the breath hits it.
  double shieldHit = 0;

  late double halfShown = islandHalf(village.level).toDouble();

  final math.Random _rnd = math.Random();
  late final List<double> _noise = List.generate(gridN * gridN, (i) => math.Random(i * 7 + 3).nextDouble());
  final List<Offset> _stars = List.generate(80, (i) {
    final r = math.Random(i * 31 + 7);
    return Offset(r.nextDouble(), r.nextDouble() * 0.65);
  });

  double _zoom = 1, _startZoom = 1, _fitZoom = 1;
  Vector2 _pan = Vector2.zero();
  Vector2 _fitPos = Vector2.zero();
  Rect content = Rect.zero;
  bool _manual = false;
  bool _snapped = false;
  int _lastLevel = -1;
  double _talkCooldown = 2;

  int get level => village.level;

  DateTime get wallNow => DateTime.now();
  double get hourOfDay {
    final n = wallNow;
    return n.hour + n.minute / 60 + n.second / 3600;
  }

  bool get shieldUp => village.shieldActive && !village.destroyed;
  bool get stirring => ringing && elapsed >= Destruction.wake - Destruction.stirWindow && elapsed < Destruction.wake;
  bool get dragonAwake => ringing && elapsed >= Destruction.wake;
  bool get attacking => dragonAwake && !shieldUp;
  double get burnFraction => attacking ? Destruction.fraction(elapsed) : 0;
  double get danger => ringing ? 0.15 + 0.85 * (elapsed / Destruction.total).clamp(0.0, 1.0) : 0;
  double get scorch => burnFraction;
  double get crumble => village.destroyed ? 1 : (attacking ? Destruction.crumble(elapsed) : 0);
  double get nightness => _sky(hourOfDay).$3;
  bool get gold => level >= 30;
  int get villagerCount => village.destroyed ? 0 : 1 + math.min(9, level ~/ 3);

  Color get digitColor {
    if (!ringing) return const Color(0xFFFFC46B);
    final pulse = 0.5 + 0.5 * math.sin(animTime * 8);
    return Color.lerp(const Color(0xFFFF8A3D), const Color(0xFFFF2E2E), pulse)!;
  }

  double _tileExt(int gx, int gy) => math.max((gx + .5 - center).abs(), (gy + .5 - center).abs()) + .5;

  double tileRise(int gx, int gy) {
    if (gx < 0 || gy < 0 || gx >= gridN || gy >= gridN) return 0;
    return (halfShown - _tileExt(gx, gy) + 1).clamp(0.0, 1.0);
  }

  bool itemReady(Item it) => level >= it.day && it.ext <= halfShown + 0.001;

  double tileDrop(int gx, int gy) {
    final c = crumble;
    if (c <= 0 || gx < 0 || gy < 0 || gx >= gridN || gy >= gridN) return 0;
    final h = islandHalf(level);
    final edgeDist = h - _tileExt(gx, gy);
    final thr = edgeDist / math.max(1, h - 1) * 0.85 + _noise[gx * gridN + gy] * 0.12;
    final v = c - thr;
    return v <= 0 ? 0 : v * 1400;
  }

  double dropAt(double gx, double gy) => tileDrop(gx.floor().clamp(0, gridN - 1), gy.floor().clamp(0, gridN - 1));

  BuildingStatus buildingStatus(int id) {
    if (village.ruined.contains(id)) return const BuildingStatus(BuildState.ruin);
    if (!attacking) return const BuildingStatus(BuildState.normal);
    final active = village.activeBuildings;
    final order = active.indexOf(id);
    if (order < 0) return const BuildingStatus(BuildState.normal);
    final t = elapsed - Destruction.igniteAt(order, active.length);
    if (t < 0) return const BuildingStatus(BuildState.normal);
    return BuildingStatus(
      BuildState.normal,
      burning: true,
      burn: (t / Destruction.buildingBurn).clamp(0.0, 1.0),
      collapse: ((t - Destruction.buildingBurn) / Destruction.collapseDuration).clamp(0.0, 1.0),
    );
  }

  /// Floating nest rock the monster sleeps on.
  Offset get perch {
    final h = halfShown;
    return Offset(32 * h + 46, 256 + 16 * h + 118 + math.sin(animTime * 0.8) * 4);
  }

  // shield dome geometry (world space)
  Offset get domeCenter => Iso.p(center, center, 0);
  double get domeRx => 64 * halfShown + 46;
  double get domeH => 300 + 10 * halfShown;

  @override
  Color backgroundColor() => const Color(0xFF101830);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;
  }

  void resetView() => _manual = false;

  void _computeFit() {
    if (size.x <= 0 || size.y <= 0) return;
    final h = halfShown;
    final top = shieldUp ? domeCenter.dy - domeH - 10 : Iso.p(center, center, 290).dy;
    final bottom = math.max(Iso.p(center + h, center + h).dy + 105, perch.dy + 90);
    final halfW = math.max(64 * h + 12, perch.dx + 70);
    content = Rect.fromLTRB(-halfW, top, halfW, bottom);

    final w = size.x, hh = size.y;
    final portrait = hh > w;
    const topPad = 64.0;
    final bottomPad = portrait ? 210.0 : 30.0;
    final availH = math.max(120.0, hh - topPad - bottomPad);
    final fit = math.min(w * 0.98 / content.width, availH / content.height);
    final closer = portrait ? 1.0 + 0.4 * ((h - 3) / 5).clamp(0.0, 1.0) : 1.0;
    _fitZoom = fit * closer;
    final availCenterY = topPad + availH / 2;
    final cy = portrait && closer > 1 ? Iso.p(center, center, 40).dy : content.center.dy;
    _fitPos = Vector2(0, cy - (availCenterY - hh / 2) / _fitZoom);
  }

  double get _minZoom => _fitZoom * 0.55;
  double get _maxZoom => _fitZoom * 4.5;

  @override
  void onScaleStart(ScaleStartInfo info) {
    _startZoom = _zoom;
    _manual = true;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final s = info.scale.global;
    if ((s.x - 1).abs() > 0.01 || (s.y - 1).abs() > 0.01) {
      _zoom = (_startZoom * (s.x + s.y) / 2).clamp(_minZoom, _maxZoom);
    }
    _pan = _pan - info.delta.global / _zoom;
    _clampPan();
  }

  @override
  void onScroll(PointerScrollInfo info) {
    _manual = true;
    final dy = info.scrollDelta.global.y;
    _zoom = (_zoom * (dy > 0 ? 0.9 : 1.1)).clamp(_minZoom, _maxZoom);
  }

  void _clampPan() {
    if (content == Rect.zero) return;
    _pan = Vector2(_pan.x.clamp(content.left, content.right), _pan.y.clamp(content.top, content.bottom));
  }

  @override
  void update(double dt) {
    animTime += dt;
    ringing = engine.isRinging;
    elapsed = engine.elapsed;

    if (village.rainSerial != _rainSeen) {
      _rainSeen = village.rainSerial;
      rainT = 4.5;
    }
    if (rainT > 0) rainT = math.max(0, rainT - dt);
    if (shieldHit > 0) shieldHit = math.max(0, shieldHit - dt * 2);

    final ht = islandHalf(level).toDouble();
    if (halfShown < ht) halfShown = math.min(ht, halfShown + dt * 1.2);
    if (halfShown > ht) halfShown = math.max(ht, halfShown - dt * 3);
    if (_lastLevel != level) {
      _lastLevel = level;
      _manual = false;
    }

    _computeFit();
    if (!_snapped && size.x > 0) {
      _zoom = _fitZoom;
      _pan = _fitPos.clone();
      _snapped = true;
    } else if (!_manual) {
      final k = math.min(1.0, dt * 3);
      _zoom += (_fitZoom - _zoom) * k;
      _pan += (_fitPos - _pan) * k;
    }

    _updateBreath();
    _updateTalk(dt);

    double amp = 0;
    if (stirring) amp = 1.5;
    if (attacking) amp = 2.5 + 6 * crumble;
    if (dragonAwake && shieldUp && breathTarget != null) amp = 1.5;
    camera.viewfinder.zoom = _zoom;
    camera.viewfinder.position = _pan + Vector2(_rnd.nextDouble() - .5, _rnd.nextDouble() - .5) * (2 * amp);

    super.update(dt);
  }

  void _updateBreath() {
    breathTarget = null;
    if (!dragonAwake) return;
    if (shieldUp) {
      // Blast the dome in bursts.
      if (math.sin(animTime * 1.6) > 0) {
        final m = monster;
        final dir = m == null ? 1.0 : (m.pos.dx >= 0 ? 1.0 : -1.0);
        breathTarget = domeCenter + Offset(dir * domeRx * .35, -domeH * .85);
        shieldHit = 1;
      }
      return;
    }
    final active = village.activeBuildings;
    for (var i = 0; i < active.length; i++) {
      final t = elapsed - Destruction.igniteAt(i, active.length);
      if (t >= 0 && t < 2.5) {
        final b = buildings[active[i]];
        if (b != null) breathTarget = b.fireAnchor.translate(0, dropAt(b.x, b.y));
      }
    }
    if (breathTarget == null && math.sin(animTime * 1.3) > -0.2) {
      final h = halfShown * 0.6;
      breathTarget = Iso.p(center + math.sin(animTime * .7) * h, center + math.cos(animTime * .9) * h);
    }
  }

  void _updateTalk(double dt) {
    _talkCooldown -= dt;
    if (_talkCooldown > 0) return;
    final visible = villagers.where((v) => v.visible && v.saying == null).toList();
    if (visible.isNotEmpty) {
      final v = visible[_rnd.nextInt(visible.length)];
      v.say(Talk.pick(this, _rnd, keeper: v.index == 0));
    }
    // Monster growls occasionally while attacking.
    final m = monster;
    if (m != null && dragonAwake && _rnd.nextDouble() < .35 && m.spec.taunts.isNotEmpty) {
      monsterLine = m.spec.taunts[_rnd.nextInt(m.spec.taunts.length)];
      monsterLineT = 2.5;
    }
    _talkCooldown = ringing ? 1.4 + _rnd.nextDouble() : 6 + _rnd.nextDouble() * 5;
  }

  String? monsterLine;
  double monsterLineT = 0;

  @override
  void render(Canvas canvas) {
    _paintSky(canvas);
    super.render(canvas);
  }

  static const _keys = <(double, int, int, double)>[
    (0, 0xFF0B1026, 0xFF1B2A4A, 1),
    (5, 0xFF141E45, 0xFF2D3C6B, 1),
    (6.5, 0xFF5B6FB5, 0xFFF4A6A0, .35),
    (8.5, 0xFF4A90D9, 0xFFBDE3F7, 0),
    (17, 0xFF4A90D9, 0xFFBDE3F7, 0),
    (18.8, 0xFF3A3F7A, 0xFFF39C6B, .35),
    (20.5, 0xFF0B1026, 0xFF1B2A4A, 1),
    (24, 0xFF0B1026, 0xFF1B2A4A, 1),
  ];

  (Color, Color, double) _sky(double h) {
    for (var i = 0; i < _keys.length - 1; i++) {
      final a = _keys[i], b = _keys[i + 1];
      if (h >= a.$1 && h <= b.$1) {
        final t = (h - a.$1) / (b.$1 - a.$1);
        return (
          Color.lerp(Color(a.$2), Color(b.$2), t)!,
          Color.lerp(Color(a.$3), Color(b.$3), t)!,
          a.$4 + (b.$4 - a.$4) * t,
        );
      }
    }
    return (Color(_keys.first.$2), Color(_keys.first.$3), 1);
  }

  final Paint _skyPaint = Paint()..isAntiAlias = true;

  void _paintSky(Canvas canvas) {
    final rect = Offset.zero & Size(size.x, size.y);
    var (top, bottom, night) = _sky(hourOfDay);
    if (ringing && dragonAwake && !shieldUp) {
      final tint = danger * (0.85 + 0.15 * math.sin(animTime * 6));
      top = Color.lerp(top, const Color(0xFF2A0606), tint)!;
      bottom = Color.lerp(bottom, const Color(0xFFC0391B), tint)!;
    } else if (ringing) {
      top = Color.lerp(top, const Color(0xFF3A1010), .3)!;
    }
    if (rainT > 0) {
      final k = (math.min(rainT, 1.0)) * .6;
      top = Color.lerp(top, const Color(0xFF2E3A4A), k)!;
      bottom = Color.lerp(bottom, const Color(0xFF5A6E82), k)!;
    }
    _skyPaint.shader =
        LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(rect);
    canvas.drawRect(rect, _skyPaint);
    _skyPaint.shader = null;
    if (night > 0.05) {
      for (var i = 0; i < _stars.length; i++) {
        final tw = 0.6 + 0.4 * math.sin(animTime * 2 + i);
        _skyPaint.color = Colors.white.withAlpha((night * tw * 200).round());
        canvas.drawCircle(Offset(_stars[i].dx * size.x, _stars[i].dy * size.y), i % 5 == 0 ? 1.6 : 1, _skyPaint);
      }
      _skyPaint
        ..color = Color.fromRGBO(255, 244, 214, night * .9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(size.x * .82, size.y * .12), 18, _skyPaint);
      _skyPaint.maskFilter = null;
    }
    final cloudA = (1 - night) * .75 + .12;
    for (var i = 0; i < 6; i++) {
      final speed = 6.0 + i * 2.5;
      final span = size.x + 260;
      final x = (i * 197.0 + animTime * speed) % span - 130;
      final y = size.y * (0.08 + (i % 3) * 0.09);
      final s = 0.7 + (i % 4) * 0.2;
      _skyPaint.color = Color.fromRGBO(255, 255, 255, cloudA * (ringing ? .35 : 1) * .8);
      for (final o in const [(0.0, 0.0, 22.0), (24.0, -8.0, 26.0), (50.0, 0.0, 20.0), (26.0, 6.0, 22.0)]) {
        canvas.drawCircle(Offset(x + o.$1 * s, y + o.$2 * s), o.$3 * s, _skyPaint);
      }
    }
  }
}
