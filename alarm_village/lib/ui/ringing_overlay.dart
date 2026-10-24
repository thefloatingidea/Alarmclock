import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../alarm/alarm.dart';
import '../alarm/alarm_engine.dart';
import '../game/destruction.dart';
import '../state/village_state.dart';
import 'glass.dart';

class RingingOverlay extends StatelessWidget {
  const RingingOverlay({super.key, required this.engine, required this.village});
  final AlarmEngine engine;
  final VillageState village;

  @override
  Widget build(BuildContext context) {
    final alarm = engine.ringing!;
    final e = engine.elapsed;
    final shield = village.shieldActive;
    final awake = e >= Destruction.wake;
    final burned = shield ? 0.0 : Destruction.fraction(e);
    final now = DateTime.now();
    final wakeIn = (Destruction.wake - e).clamp(0, 99).ceil();
    final name = Destruction.spec.name;

    Widget meter;
    if (!awake) {
      meter = Column(children: [
        Text('$name wakes in ${wakeIn}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _Bar(value: 1 - e / Destruction.wake, color: const Color(0xFF7CD67C)),
      ]);
    } else if (shield) {
      meter = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.shield, color: Color(0xFF6FD3FF)),
        const SizedBox(width: 6),
        Text('Shield holding - ${village.shieldCharges} miss${village.shieldCharges == 1 ? '' : 'es'} left',
            style: const TextStyle(color: Color(0xFF6FD3FF), fontWeight: FontWeight.w700)),
      ]);
    } else {
      final pct = (burned * 100).round();
      meter = Column(children: [
        Row(children: [
          const Icon(Icons.local_fire_department, color: Color(0xFFFF6A3D), size: 18),
          const SizedBox(width: 4),
          Text('City burned: $pct%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(burned < .5 ? 'FREE REBUILD' : 'COSTS ${VillageState.restoreCost} BUCKETS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: burned < .5 ? const Color(0xFF7CD67C) : const Color(0xFFFF8A8A))),
        ]),
        const SizedBox(height: 6),
        _Bar(value: burned, color: Color.lerp(const Color(0xFFFFC46B), const Color(0xFFFF2E2E), burned)!, marker: .5),
      ]);
    }

    return Stack(fit: StackFit.expand, children: [
      const ModalBarrier(dismissible: false),
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x00000000), Color(0xAA000000)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Glass(
                tint: awake && !shield ? const Color(0x55601010) : null,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${alarm.label.toUpperCase()}${engine.preview ? '  -  PREVIEW' : ''}',
                      style: const TextStyle(letterSpacing: 2, color: Colors.white70)),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: hourMinute(now.hour, now.minute), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white)),
                    TextSpan(text: ' ${amPm(now.hour)}', style: const TextStyle(fontSize: 18, color: Colors.white)),
                  ])),
                  const SizedBox(height: 4),
                  Text(engine.finishing ? 'Too late! The $name is burning everything...' : Destruction.stageLabel(e, shield: shield),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: awake && !shield ? const Color(0xFFFFB199) : Colors.white)),
                  const SizedBox(height: 10),
                  meter,
                ]),
              ),
              const Spacer(),
              if (!engine.finishing) ...[
                HoldToStopButton(onComplete: engine.stop),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: engine.snooze,
                  icon: const Icon(Icons.snooze, color: Colors.white70),
                  label: Text(shield ? 'Snooze 5 min (shield protects you)' : 'Snooze 5 min (costs one building)',
                      style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color, this.marker});
  final double value;
  final Color color;
  final double? marker;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, c) => Stack(children: [
          Container(decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(6))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: c.maxWidth * value.clamp(0.0, 1.0),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          ),
          if (marker != null)
            Positioned(left: c.maxWidth * marker! - 1, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white)),
        ]),
      ),
    );
  }
}

/// Must be held ~1.4 s - a sleepy tap is not enough.
class HoldToStopButton extends StatefulWidget {
  const HoldToStopButton({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<HoldToStopButton> createState() => _HoldToStopButtonState();
}

class _HoldToStopButtonState extends State<HoldToStopButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onComplete();
        _c.reset();
      }
    });

  void _release() {
    if (!_c.isCompleted) _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _c.forward(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => SizedBox(
          width: 124,
          height: 124,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: _c.value,
                strokeWidth: 8,
                backgroundColor: const Color(0x33FFFFFF),
                color: const Color(0xFFFFC46B),
              ),
            ),
            Container(
              width: 98,
              height: 98,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE85D3F),
                boxShadow: [BoxShadow(color: Color(0x88FF5A1F), blurRadius: 24)],
              ),
              alignment: Alignment.center,
              child: const Text('HOLD\nTO STOP',
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
            ),
          ]),
        ),
      ),
    );
  }
}
