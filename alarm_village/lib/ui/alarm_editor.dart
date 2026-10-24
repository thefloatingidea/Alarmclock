import 'package:flutter/material.dart';

import '../alarm/alarm.dart';
import '../alarm/alarm_store.dart';

Future<void> showAlarmEditor(BuildContext context, AlarmStore store, {Alarm? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C2238),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AlarmEditor(store: store, existing: existing),
  );
}

class _AlarmEditor extends StatefulWidget {
  const _AlarmEditor({required this.store, this.existing});
  final AlarmStore store;
  final Alarm? existing;

  @override
  State<_AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<_AlarmEditor> {
  late TimeOfDay _time;
  late final TextEditingController _label;
  late Set<int> _days;

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _time = e == null ? const TimeOfDay(hour: 7, minute: 0) : TimeOfDay(hour: e.hour, minute: e.minute);
    _label = TextEditingController(text: e?.label ?? 'Wake up');
    _days = {...?e?.days};
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _save() {
    widget.store.upsert(Alarm(
      id: widget.existing?.id ?? AlarmStore.newId(),
      hour: _time.hour,
      minute: _time.minute,
      label: _label.text.trim().isEmpty ? 'Alarm' : _label.text.trim(),
      enabled: true,
      days: _days,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.existing == null ? 'New alarm' : 'Edit alarm', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: hourMinute(_time.hour, _time.minute), style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w300)),
                TextSpan(text: ' ${amPm(_time.hour)}', style: const TextStyle(fontSize: 20)),
              ]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        TextField(controller: _label, decoration: const InputDecoration(labelText: 'Label')),
        const SizedBox(height: 14),
        const Text('Repeat (none = once)'),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final day = i + 1;
            final on = _days.contains(day);
            return GestureDetector(
              onTap: () => setState(() => on ? _days.remove(day) : _days.add(day)),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: on ? Theme.of(context).colorScheme.primary : const Color(0x22FFFFFF),
                child: Text(_dayNames[i], style: TextStyle(color: on ? Theme.of(context).colorScheme.onPrimary : Colors.white70)),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Row(children: [
          if (widget.existing != null)
            TextButton.icon(
              onPressed: () {
                widget.store.remove(widget.existing!.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          const Spacer(),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ]),
      ]),
    );
  }
}
