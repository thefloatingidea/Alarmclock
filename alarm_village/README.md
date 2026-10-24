# Alarm Village - proof of concept (milestone 1)

One cottage in four states (healthy, lit at night, damaged, ruined), a procedural
fire shader and a mood shader, all driven by a single destruction value.
Built with Flutter + Flame. Free tools only: no Rive, no Spine, no purchased assets.

> Status: written without a Flutter SDK available, so it has **not been compiled or run**.
> The SVG art was rendered and checked; the Dart and GLSL were reviewed by hand only.
> Treat the first `flutter run` as the real test, using the checklist below.

## Run it

```bash
cd alarm_village
flutter create --platforms=android,ios --project-name alarm_village .   # adds android/ and ios/ (keeps lib/ and pubspec)
flutter pub get
flutter run            # pick a real phone if you can
flutter test           # pure-Dart logic tests
```

If `pub get` reports a version or SDK conflict, run `flutter pub add flame flame_svg`
and let pub choose compatible versions. The pinned versions (flame ^1.38.2,
flame_svg ^2.0.0) are the latest I found on pub.dev.

## What you should see

A cottage on grass. **Destruction** slider: fires start around 12%, the cottage fades to
damaged at 25% and ruined at 60%, the scene warms to orange then cools and desaturates.
**Dusk** slider: night grade and lit windows. **Play 20 s burn** runs the real
`DestructionClock`. **High / Medium / Low** switches the quality tier.

## Structure

```
lib/
  main.dart
  app/poc_screen.dart                 Flutter UI: game + sliders (stand-in for the alarm)
  alarm/alarm_service.dart            AlarmService interface + timer-based fake (not wired in yet)
  game/
    constants.dart                    scene size (320x512), debug flag
    alarm_village_game.dart           FlameGame with a fixed-resolution camera
    anchors.dart                      loads assets/anchors/*.json (fire points)
    world/village_world.dart          ground + building + fire inside one post-process
    components/
      building_component.dart         stacked SVG states, cross-fade by progress
      fade_layer.dart                 one SVG with adjustable opacity
      ground_component.dart           placeholder grass + path (drawn in code)
      fire_layer.dart                 one fire.frag quad + glow per fire point
    post/mood_post_process.dart       mood.frag applied to the whole scene
    logic/                            pure Dart, unit-tested
      destruction_clock.dart          timestamps -> progress (grace + total)
      destruction_controller.dart     progress / dusk / quality notifiers
      building_state.dart             thresholds -> which SVG state
      fire_math.dart                  fire intensity curve
      quality_tier.dart               High / Medium / Low
shaders/mood.frag, shaders/fire.frag
assets/images/svg/                    4 cottage SVG states
assets/anchors/cottage.json           window + fire points
tools/gen_cottage_svgs.py             regenerates the SVGs and anchors
test/                                 clock, state and fire tests
```

One value drives everything: `DestructionController.progress`. Building state, fire
count and the mood shader all read it every frame. To connect the real alarm later, write
`DestructionClock.progressAt(DateTime.now())` into that notifier. Because progress comes
from timestamps, opening the app late shows the correct state straight away.

## Verify first (things I could not test)

1. **Shader coordinates.** Both shaders use `FlutterFragCoord()` divided by their size
   uniform. Set `kDebugShaderBounds = true` in `lib/game/constants.dart`, run on a
   high-DPI phone, and check the flames sit in their cyan boxes and the grade covers the
   whole scene. If they are offset or scaled, the coordinate space differs from my
   assumption and the uniforms need a pixel-ratio correction.
2. **SVG path.** `Svg.load('svg/...')` is assumed to resolve under `assets/images/`
   (Flame's default prefix). If loading fails, the on-screen error text will say so.
3. **Post-process API.** `PostProcessComponent` and `PostProcess.rasterizeSubtree()`
   follow the Flame docs; names may differ slightly in your Flame version.
4. **Performance.** Check frame rate on a mid-range Android phone with High quality.
   The glow paint is allocated per fire per frame, which is fine for 5 fires but should
   be pooled before scaling to 60.
5. **Impeller / Skia.** Flutter documents custom shaders on both; confirm on your devices.

## Next steps

- Connect the alarm plugin so it writes progress through `DestructionClock`.
- Add the barn, windmill, trees and villagers as more `BuildingComponent`s and sprite strips.
- Replace `GroundComponent` with SVG ground art.
- Pool the glow paints; add the frame-time based automatic quality tier.

## Art rules

Every state of a building uses the same canvas size and bottom-centre origin so states
overlay exactly. Keep SVGs simple (paths, solid fills, no filters, no text). Log every
file in `ASSETS.md`.
