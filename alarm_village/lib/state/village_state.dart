import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/layout.dart';

/// Persistent progress + in-game currency (shields and water buckets).
class VillageState extends ChangeNotifier {
  VillageState(this._prefs) {
    _load();
  }

  static const _key = 'village_v3';
  static const int restoreCost = 20; // water buckets to restore a burned city
  static const int missesPerShield = 2; // one shield protects 2 missed alarms
  static const int bucketsPerWake = 5; // free reward for every on-time wake-up
  static const int shieldEveryDays = 7; // free shield every 7-day streak

  final SharedPreferences _prefs;

  // progress
  int level = 0;
  int streak = 0;
  int bestStreak = 0;
  bool destroyed = false;
  final Set<int> ruined = {};
  int damagePct = 0; // > 0 = city partly burned, free rebuild pending

  // wallet (new players get a small welcome gift)
  int shields = 1;
  int buckets = 10;
  int shieldCharges = 0; // missed alarms the active shield can still absorb

  int rainSerial = 0; // bumps every time a restore should play the rain effect
  String? _message;

  bool get shieldActive => shieldCharges > 0;
  bool get canRestore => buckets >= restoreCost;
  List<int> get activeBuildings => activeBuildingIds(level, ruined);

  String? takeMessage() {
    final m = _message;
    _message = null;
    return m;
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      int i(String k, int def) => (m[k] as num?)?.toInt() ?? def;
      level = i('level', 0);
      streak = i('streak', 0);
      bestStreak = i('best', 0);
      damagePct = i('damage', 0);
      shields = i('shields', 1);
      buckets = i('buckets', 10);
      shieldCharges = i('charges', 0);
      destroyed = (m['destroyed'] as bool?) ?? false;
      ruined.addAll(((m['ruined'] as List?) ?? const []).map((e) => (e as num).toInt()));
    } catch (_) {}
  }

  void _save() {
    _prefs.setString(
        _key,
        jsonEncode({
          'level': level,
          'streak': streak,
          'best': bestStreak,
          'damage': damagePct,
          'shields': shields,
          'buckets': buckets,
          'charges': shieldCharges,
          'destroyed': destroyed,
          'ruined': ruined.toList(),
        }));
    notifyListeners();
  }

  String _unlockText(int day) {
    final names = <String>{
      for (final it in layout)
        if (it.day == day && kindNames.containsKey(it.kind)) kindNames[it.kind]!,
    };
    if (day > 0 && islandHalf(day) > islandHalf(day - 1)) names.add('the island grew');
    if (day == 30) names.add('the clock tower turned gold');
    return names.isEmpty ? 'more trees and flowers grew' : names.join(', ');
  }

  // ---------------- alarm outcomes ----------------

  /// Stopped before the monster woke up.
  void wakeOnTime() {
    streak++;
    bestStreak = math.max(bestStreak, streak);
    if (level < maxLevel) level++;
    buckets += bucketsPerWake;
    var text = 'Day $level: ${_unlockText(level)}. +$bucketsPerWake water buckets';
    if (streak % shieldEveryDays == 0) {
      shields++;
      text += ', +1 shield for a $streak-day streak';
    }
    _message = '$text.';
    _save();
  }

  /// Late, but the shield took the hit. Streak is kept.
  void shieldBlocked() {
    shieldCharges = math.max(0, shieldCharges - 1);
    _message = shieldCharges > 0
        ? 'Your shield blocked the attack. It can absorb $shieldCharges more missed alarm.'
        : 'Your shield blocked the attack and faded away. Buy or activate a new one.';
    _save();
  }

  /// Stopped while less than 50% was burned: free rebuild offered.
  void partialDamage(List<int> collapsed, double fraction) {
    ruined.addAll(collapsed);
    streak = 0;
    damagePct = math.max(1, (fraction * 100).round());
    _save();
  }

  void restoreFree() {
    ruined.clear();
    damagePct = 0;
    rainSerial++;
    _message = 'The villagers put out the fires and rebuilt everything. Streak starts again.';
    _save();
  }

  /// 50% or more burned (or alarm never stopped): the city is gone.
  void markDestroyed() {
    destroyed = true;
    streak = 0;
    damagePct = 0;
    _save();
  }

  /// Rain 20 water buckets on the ashes and bring the city back.
  bool restoreWithWater() {
    if (!canRestore) return false;
    buckets -= restoreCost;
    destroyed = false;
    ruined.clear();
    rainSerial++;
    _message = 'Rain! Your day-$level city is back. Streak starts again.';
    _save();
    return true;
  }

  /// Rule: a fully burned city that is not restored starts again from day 0.
  void startOver() {
    destroyed = false;
    level = 0;
    streak = 0;
    damagePct = 0;
    ruined.clear();
    _message = 'A new island begins. Wake on time to grow it.';
    _save();
  }

  void applySnooze(List<int> collapsed) {
    ruined.addAll(collapsed);
    if (shieldActive) {
      _message = 'Snoozed - your shield kept the dragon away.';
    } else {
      final active = activeBuildings;
      if (active.isNotEmpty) ruined.add(active.last);
      _message = active.isEmpty ? 'Snoozed.' : 'Snoozed - the dragon took a building as payment.';
      if (ruined.isNotEmpty) damagePct = math.max(damagePct, 1);
    }
    _save();
  }

  // ---------------- wallet ----------------

  bool activateShield() {
    if (shields <= 0) return false;
    shields--;
    shieldCharges += missesPerShield;
    _message = 'Shield up! It can absorb $shieldCharges missed alarms.';
    _save();
    return true;
  }

  void addCurrency({int shields = 0, int buckets = 0, String? note}) {
    this.shields += shields;
    this.buckets += buckets;
    _message = note;
    _save();
  }

  // ---------------- testing helpers ----------------

  void simulateOnTimeWake() {
    destroyed = false;
    wakeOnTime();
  }

  void simulate(int days) {
    level = days.clamp(0, maxLevel);
    streak = level;
    bestStreak = math.max(bestStreak, streak);
    destroyed = false;
    damagePct = 0;
    ruined.clear();
    _message = 'Simulated a $level-day streak.';
    _save();
  }
}
