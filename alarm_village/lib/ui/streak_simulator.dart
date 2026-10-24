import 'package:flutter/material.dart';

import '../game/layout.dart';
import '../state/village_state.dart';

/// Testing tool: jump to any streak day and test the economy.
Future<void> showStreakSimulator(BuildContext context, VillageState village) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xEE1C2238),
    barrierColor: Colors.transparent,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _StreakSimulator(village: village),
  );
}

class _StreakSimulator extends StatefulWidget {
  const _StreakSimulator({required this.village});
  final VillageState village;

  @override
  State<_StreakSimulator> createState() => _StreakSimulatorState();
}

class _StreakSimulatorState extends State<_StreakSimulator> {
  late double _days = widget.village.level.toDouble();

  void _apply(int d) {
    setState(() => _days = d.toDouble());
    widget.village.simulate(d);
  }

  @override
  Widget build(BuildContext context) {
    final d = _days.round();
    final v = widget.village;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Row(children: [
            Icon(Icons.science_outlined),
            SizedBox(width: 8),
            Text('Test tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          const Text('For testing only - this overwrites your saved progress.', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12),
          Text('Day $d  -  island ${islandHalf(d) * 2} x ${islandHalf(d) * 2} tiles',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Slider(
            value: _days,
            min: 0,
            max: maxLevel.toDouble(),
            divisions: maxLevel,
            label: '$d days',
            onChanged: (x) => setState(() => _days = x),
            onChangeEnd: (x) => v.simulate(x.round()),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in const [0, 3, 7, 15, 30, 60]) ActionChip(label: Text(p == 0 ? 'Reset' : '$p days'), onPressed: () => _apply(p)),
          ]),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              v.simulateOnTimeWake();
              setState(() => _days = v.level.toDouble());
            },
            icon: const Icon(Icons.wb_sunny_outlined),
            label: const Text('+1 day (simulate on-time wake-up)'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => v.addCurrency(shields: 2, buckets: 50, note: 'Test: +2 shields, +50 buckets'),
                icon: const Icon(Icons.add),
                label: const Text('+2 shields +50 buckets'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
