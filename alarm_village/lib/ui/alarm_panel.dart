import 'package:flutter/material.dart';

import '../alarm/alarm.dart';
import '../alarm/alarm_engine.dart';
import '../alarm/alarm_store.dart';
import '../state/village_state.dart';
import 'alarm_editor.dart';
import 'glass.dart';
import 'shop_sheet.dart';
import 'streak_simulator.dart';

/// Glass alarm card. Tap the header to collapse it and see more of the island.
class AlarmPanel extends StatefulWidget {
  const AlarmPanel({super.key, required this.store, required this.engine, required this.village});

  final AlarmStore store;
  final AlarmEngine engine;
  final VillageState village;

  @override
  State<AlarmPanel> createState() => _AlarmPanelState();
}

class _AlarmPanelState extends State<AlarmPanel> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.store, widget.engine]),
      builder: (context, _) {
        final alarms = widget.store.alarms;
        final now = DateTime.now();
        final next = widget.store.next(now);
        String sub = 'No alarm set';
        if (widget.engine.snoozeUntil != null) {
          final s = widget.engine.snoozeUntil!;
          sub = 'Snoozed till ${hourMinute(s.hour, s.minute)}';
        } else if (next != null) {
          final diff = next.$2.difference(now);
          sub = 'Next in ${diff.inHours}h ${diff.inMinutes % 60}m';
        }
        return Glass(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _collapsed = !_collapsed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('Alarms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                          Icon(_collapsed ? Icons.expand_less : Icons.expand_more, color: Colors.white70, size: 20),
                        ]),
                        Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ]),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Shop',
                  icon: const Icon(Icons.storefront, color: Color(0xFFFFC46B)),
                  onPressed: () => showShop(context, widget.village),
                ),
                IconButton(
                  tooltip: 'Streak simulator (testing)',
                  icon: const Icon(Icons.science_outlined, color: Colors.white),
                  onPressed: () => showStreakSimulator(context, widget.village),
                ),
                IconButton(
                  tooltip: 'Preview the attack (4x speed, nothing saved)',
                  icon: const Icon(Icons.bolt, color: Colors.white),
                  onPressed: widget.engine.previewRing,
                ),
                IconButton(
                  tooltip: 'Add alarm',
                  icon: const Icon(Icons.add_alarm, color: Colors.white),
                  onPressed: () => showAlarmEditor(context, widget.store),
                ),
              ]),
              if (!_collapsed)
                if (alarms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('No alarms yet - tap + to add one', style: TextStyle(color: Colors.white70)),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: alarms.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x33FFFFFF)),
                      itemBuilder: (context, i) => _AlarmRow(alarm: alarms[i], store: widget.store),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _AlarmRow extends StatelessWidget {
  const _AlarmRow({required this.alarm, required this.store});
  final Alarm alarm;
  final AlarmStore store;

  @override
  Widget build(BuildContext context) {
    final dim = alarm.enabled ? Colors.white : Colors.white54;
    return InkWell(
      onTap: () => showAlarmEditor(context, store, existing: alarm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: hourMinute(alarm.hour, alarm.minute), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: dim)),
                TextSpan(text: ' ${amPm(alarm.hour)}', style: TextStyle(fontSize: 13, color: dim)),
              ])),
              Text('${alarm.label.toUpperCase()}  -  ${alarm.daysLabel}',
                  style: TextStyle(fontSize: 11, letterSpacing: 1, color: dim.withAlpha(200))),
            ]),
          ),
          Switch(value: alarm.enabled, onChanged: (v) => store.toggle(alarm.id, v)),
        ]),
      ),
    );
  }
}
