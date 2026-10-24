/// A single alarm. [days] uses DateTime.weekday (1 = Mon ... 7 = Sun).
/// Empty [days] means a one-time alarm.
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = 'Alarm',
    this.enabled = true,
    this.days = const {},
  });

  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final Set<int> days;

  Alarm copyWith({int? hour, int? minute, String? label, bool? enabled, Set<int>? days}) => Alarm(
        id: id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        label: label ?? this.label,
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
      );

  bool firesAt(DateTime now) =>
      enabled && now.hour == hour && now.minute == minute && (days.isEmpty || days.contains(now.weekday));

  DateTime? nextFire(DateTime now) {
    if (!enabled) return null;
    for (var i = 0; i <= 7; i++) {
      final d = DateTime(now.year, now.month, now.day + i, hour, minute);
      if (d.isAfter(now) && (days.isEmpty || days.contains(d.weekday))) return d;
    }
    return null;
  }

  String get daysLabel {
    if (days.isEmpty) return 'Once';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.containsAll(const [1, 2, 3, 4, 5])) return 'Weekdays';
    if (days.length == 2 && days.containsAll(const [6, 7])) return 'Weekends';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'hour': hour, 'minute': minute, 'label': label, 'enabled': enabled, 'days': days.toList()};

  factory Alarm.fromJson(Map<String, dynamic> j) => Alarm(
        id: j['id'] as String,
        hour: (j['hour'] as num).toInt(),
        minute: (j['minute'] as num).toInt(),
        label: (j['label'] as String?) ?? 'Alarm',
        enabled: (j['enabled'] as bool?) ?? true,
        days: ((j['days'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet(),
      );
}

String hourMinute(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${minute.toString().padLeft(2, '0')}';
}

String amPm(int hour) => hour < 12 ? 'AM' : 'PM';
