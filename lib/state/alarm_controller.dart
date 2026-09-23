import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import '../services/alarm_sound.dart';

/// Держит список будильников и следит, не пора ли звонить.
/// Проверка идёт, пока приложение открыто — сценарий «телефон на тумбочке».
class AlarmController extends ChangeNotifier {
  AlarmController(this._preferences, this._sound, List<Alarm> alarms)
    : _alarms = alarms {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  static const _storageKey = 'alarms';

  static Future<AlarmController> load(AlarmSound sound) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_storageKey) ?? const [];
    final alarms = <Alarm>[];
    for (final entry in raw) {
      try {
        alarms.add(Alarm.fromJson(jsonDecode(entry) as Map<String, Object?>));
      } on FormatException {
        // Пропускаем повреждённую запись.
      }
    }
    return AlarmController(preferences, sound, alarms);
  }

  final SharedPreferences _preferences;
  final AlarmSound _sound;
  List<Alarm> _alarms;
  Timer? _ticker;

  Alarm? _ringing;
  Alarm? _snoozed;
  DateTime? _snoozeUntil;
  DateTime? _lastFired;

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  Alarm? get ringing => _ringing;

  /// Будильник, который сработает раньше всех, или `null`, если все выключены.
  Alarm? get next {
    final now = DateTime.now();
    final active = _alarms.where((alarm) => alarm.enabled).toList()
      ..sort(
        (a, b) => a.nextTrigger(now).compareTo(b.nextTrigger(now)),
      );
    return active.isEmpty ? null : active.first;
  }

  Duration? get timeUntilNext {
    final alarm = next;
    if (alarm == null) return null;
    return alarm.nextTrigger(DateTime.now()).difference(DateTime.now());
  }

  void save(Alarm alarm) {
    final index = _alarms.indexWhere((item) => item.id == alarm.id);
    if (index == -1) {
      _alarms = [..._alarms, alarm];
    } else {
      _alarms = [..._alarms]..[index] = alarm;
    }
    _alarms.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    _alarms = _alarms.where((alarm) => alarm.id != id).toList();
    notifyListeners();
    _persist();
  }

  void toggle(String id, bool enabled) {
    final alarm = _alarms.firstWhere((item) => item.id == id);
    save(alarm.copyWith(enabled: enabled));
  }

  void snooze() {
    final alarm = _ringing;
    if (alarm == null) return;
    _snoozed = alarm;
    _snoozeUntil = DateTime.now().add(Duration(minutes: alarm.snoozeMinutes));
    _stopRinging();
  }

  void dismiss() {
    final alarm = _ringing;
    _snoozed = null;
    _snoozeUntil = null;
    if (alarm != null && !alarm.repeats) {
      save(alarm.copyWith(enabled: false));
    }
    _stopRinging();
  }

  void _stopRinging() {
    _ringing = null;
    _sound.stop();
    notifyListeners();
  }

  void _check() {
    if (_ringing != null) return;
    final now = DateTime.now();

    final snoozeUntil = _snoozeUntil;
    final snoozed = _snoozed;
    if (snoozeUntil != null && snoozed != null && !now.isBefore(snoozeUntil)) {
      _snoozeUntil = null;
      _fire(snoozed);
      return;
    }

    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;
      if (alarm.hour != now.hour || alarm.minute != now.minute) continue;
      if (alarm.repeats && !alarm.weekdays.contains(now.weekday)) continue;
      // В пределах одной минуты будильник звонит только один раз.
      final minuteStamp = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      if (_lastFired == minuteStamp) continue;
      _lastFired = minuteStamp;
      _fire(alarm);
      return;
    }
  }

  void _fire(Alarm alarm) {
    _ringing = alarm;
    _sound.start();
    notifyListeners();
  }

  Future<void> _persist() {
    return _preferences.setStringList(
      _storageKey,
      _alarms.map((alarm) => jsonEncode(alarm.toJson())).toList(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
