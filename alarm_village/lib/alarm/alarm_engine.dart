import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../game/destruction.dart';
import '../state/village_state.dart';
import 'alarm.dart';
import 'alarm_store.dart';

/// Watches the clock, rings alarms and runs the attack timeline.
///
/// Rules:
///  - stop within [Destruction.wake] (15 s)        -> island grows
///  - shield active and late                        -> shield absorbs it, streak kept
///  - stop with < 50% burned                        -> free rebuild offered
///  - stop with >= 50% burned / never stopped        -> monster finishes, city is gone
class AlarmEngine extends ChangeNotifier {
  AlarmEngine(this.alarms, this.village);

  final AlarmStore alarms;
  final VillageState village;

  Timer? _timer;
  Alarm? ringing;
  bool preview = false;

  /// True after a late stop (>= 50%): the monster quickly finishes the job.
  bool finishing = false;

  double _base = 0;
  DateTime? _segStart;
  double _scale = 1;

  Alarm? _snoozed;
  DateTime? snoozeUntil;
  String? _lastFiredKey;

  Future<void> Function()? _stopAudio;
  int _session = 0;

  bool get isRinging => ringing != null;

  double get elapsed => _segStart == null
      ? 0
      : _base + DateTime.now().difference(_segStart!).inMilliseconds / 1000.0 * _scale;

  void _setScale(double s) {
    _base = elapsed;
    _segStart = DateTime.now();
    _scale = s;
  }

  void start() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    if (isRinging) {
      if (elapsed >= Destruction.total) {
        _timeout();
        return;
      }
    } else if (snoozeUntil != null && !now.isBefore(snoozeUntil!)) {
      final a = _snoozed;
      snoozeUntil = null;
      _snoozed = null;
      if (a != null) _ring(a);
    } else {
      final key = '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}';
      if (key != _lastFiredKey) {
        for (final a in alarms.alarms) {
          if (a.firesAt(now)) {
            _lastFiredKey = key;
            if (a.days.isEmpty) alarms.upsert(a.copyWith(enabled: false));
            _ring(a);
            break;
          }
        }
      }
    }
    notifyListeners();
  }

  /// Plays the whole attack at 4x speed without touching saved progress.
  void previewRing() {
    if (isRinging) return;
    final now = DateTime.now();
    _ring(Alarm(id: 'preview', hour: now.hour, minute: now.minute, label: 'Preview'), preview: true, scale: 4);
  }

  Future<void> _ring(Alarm a, {bool preview = false, double scale = 1}) async {
    ringing = a;
    this.preview = preview;
    finishing = false;
    _base = 0;
    _segStart = DateTime.now();
    _scale = scale;
    final session = ++_session;
    notifyListeners();
    try {
      final player = await FlameAudio.loop('alarm.wav');
      if (session != _session || !isRinging || finishing) {
        await player.stop();
        await player.dispose();
        return;
      }
      _stopAudio = () async {
        await player.stop();
        await player.dispose();
      };
    } catch (e) {
      debugPrint('Alarm audio failed: $e');
    }
  }

  void _silence() {
    final s = _stopAudio;
    _stopAudio = null;
    s?.call();
  }

  void _timeout() {
    if (!preview) {
      if (village.shieldActive) {
        village.shieldBlocked();
      } else {
        village.markDestroyed();
      }
    }
    _end();
  }

  void stop() {
    if (!isRinging || finishing) return;
    final e = elapsed;
    if (e < Destruction.wake) {
      if (!preview) village.wakeOnTime();
      _end();
    } else if (village.shieldActive) {
      if (!preview) village.shieldBlocked();
      _end();
    } else if (Destruction.fraction(e) < Destruction.freeRestoreLimit) {
      if (!preview) village.partialDamage(Destruction.collapsed(e, village.activeBuildings), Destruction.fraction(e));
      _end();
    } else {
      // Too late: let the monster finish quickly, then the city is gone.
      finishing = true;
      _silence();
      _setScale(10);
      notifyListeners();
    }
  }

  void snooze() {
    final a = ringing;
    if (a == null || finishing) return;
    if (!preview) {
      village.applySnooze(village.shieldActive ? const [] : Destruction.collapsed(elapsed, village.activeBuildings));
      _snoozed = a;
      snoozeUntil = DateTime.now().add(const Duration(minutes: 5));
    }
    _end();
  }

  void _end() {
    ringing = null;
    _segStart = null;
    _base = 0;
    preview = false;
    finishing = false;
    _scale = 1;
    _session++;
    _silence();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
