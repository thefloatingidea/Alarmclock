import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm.dart';

class AlarmStore extends ChangeNotifier {
  AlarmStore(this._prefs) {
    _load();
  }

  static const _key = 'alarms_v1';
  final SharedPreferences _prefs;
  final List<Alarm> _alarms = [];

  List<Alarm> get alarms => List.unmodifiable(_alarms);

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _alarms.addAll(const [
        Alarm(id: 'work', hour: 7, minute: 0, label: 'Work', days: {1, 2, 3, 4, 5}),
        Alarm(id: 'gym', hour: 8, minute: 30, label: 'Gym', enabled: false, days: {6, 7}),
      ]);
      _save();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _alarms.addAll(list.map((e) => Alarm.fromJson(e as Map<String, dynamic>)));
      _sort();
    } catch (_) {
      _alarms.clear();
    }
  }

  void _sort() => _alarms.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

  void _save() {
    _prefs.setString(_key, jsonEncode(_alarms.map((a) => a.toJson()).toList()));
    notifyListeners();
  }

  void upsert(Alarm alarm) {
    final i = _alarms.indexWhere((a) => a.id == alarm.id);
    if (i >= 0) {
      _alarms[i] = alarm;
    } else {
      _alarms.add(alarm);
    }
    _sort();
    _save();
  }

  void remove(String id) {
    _alarms.removeWhere((a) => a.id == id);
    _save();
  }

  void toggle(String id, bool enabled) {
    final i = _alarms.indexWhere((a) => a.id == id);
    if (i < 0) return;
    _alarms[i] = _alarms[i].copyWith(enabled: enabled);
    _save();
  }

  (Alarm, DateTime)? next(DateTime now) {
    (Alarm, DateTime)? best;
    for (final a in _alarms) {
      final t = a.nextFire(now);
      if (t != null && (best == null || t.isBefore(best.$2))) best = (a, t);
    }
    return best;
  }
}
