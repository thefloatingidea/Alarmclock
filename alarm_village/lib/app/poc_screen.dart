import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/alarm_village_game.dart';
import '../game/constants.dart';
import '../game/logic/destruction_clock.dart';
import '../game/logic/destruction_controller.dart';
import '../game/logic/quality_tier.dart';

/// Proof-of-concept screen: the game on top, plain Flutter controls below.
/// The sliders stand in for the alarm; later the alarm plugin drives progress.
class PocScreen extends StatefulWidget {
  const PocScreen({super.key});

  @override
  State<PocScreen> createState() => _PocScreenState();
}

class _PocScreenState extends State<PocScreen> {
  late final DestructionController _controller;
  late final AlarmVillageGame _game;
  Timer? _demo;

  @override
  void initState() {
    super.initState();
    _controller = DestructionController();
    _game = AlarmVillageGame(controller: _controller);
  }

  @override
  void dispose() {
    _demo?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Plays a 20 second burn using the real DestructionClock.
  void _playDemo() {
    _demo?.cancel();
    final clock = DestructionClock(
      ringStart: DateTime.now(),
      grace: const Duration(seconds: 2),
      total: const Duration(seconds: 20),
    );
    _demo = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      final p = clock.progressAt(DateTime.now());
      _controller.progress.value = p;
      if (p >= 1) timer.cancel();
    });
  }

  void _reset() {
    _demo?.cancel();
    _controller.progress.value = 0;
    _controller.dusk.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: kVillageWidth / kVillageHeight,
                  child: GameWidget(
                    game: _game,
                    // Shows asset / shader loading problems on screen.
                    errorBuilder: (context, error) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Load error:\n$error'),
                    ),
                  ),
                ),
              ),
            ),
            _ControlPanel(
              controller: _controller,
              onPlay: _playDemo,
              onReset: _reset,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.controller,
    required this.onPlay,
    required this.onReset,
  });

  final DestructionController controller;
  final VoidCallback onPlay;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SliderRow(label: 'Destruction', notifier: controller.progress),
          _SliderRow(label: 'Dusk', notifier: controller.dusk),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<QualityTier>(
                  valueListenable: controller.quality,
                  builder: (context, tier, _) => SegmentedButton<QualityTier>(
                    segments: [
                      for (final t in QualityTier.values)
                        ButtonSegment(value: t, label: Text(t.label)),
                    ],
                    selected: {tier},
                    onSelectionChanged: (s) => controller.quality.value = s.first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPlay,
                  child: const Text('Play 20 s burn'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.notifier});

  final String label;
  final ValueNotifier<double> notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: notifier,
      builder: (context, value, _) => Row(
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(
            child: Slider(value: value, onChanged: (v) => notifier.value = v),
          ),
          SizedBox(width: 44, child: Text('${(value * 100).round()}%')),
        ],
      ),
    );
  }
}
