import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clock_settings.dart';

/// Хранит настройки часов и пишет их в SharedPreferences с задержкой,
/// чтобы перетаскивание слайдера не порождало десятки записей на диск.
class SettingsController extends ChangeNotifier {
  SettingsController(this._preferences, this._settings);

  static const _storageKey = 'clock_settings';

  static Future<SettingsController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    var settings = const ClockSettings();
    if (raw != null) {
      try {
        settings = ClockSettings.fromJson(
          jsonDecode(raw) as Map<String, Object?>,
        );
      } on FormatException {
        // Повреждённая запись — возвращаемся к значениям по умолчанию.
      }
    }
    return SettingsController(preferences, settings);
  }

  final SharedPreferences _preferences;
  final _random = Random();
  ClockSettings _settings;

  ClockSettings get value => _settings;

  void update(ClockSettings Function(ClockSettings current) transform) {
    final next = transform(_settings);
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    _persist();
  }

  /// Случайный, но всегда хорошо читаемый цвет: высокая насыщенность и яркость.
  void shuffleDigitColor() {
    final color = HSVColor.fromAHSV(
      1,
      _random.nextDouble() * 360,
      0.55 + _random.nextDouble() * 0.45,
      1,
    ).toColor();
    update((current) => current.copyWith(digitColor: color));
  }

  Future<void> _persist() {
    return _preferences.setString(_storageKey, jsonEncode(_settings.toJson()));
  }
}

/// Даёт доступ к [SettingsController] из любого места дерева виджетов.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope не найден выше по дереву');
    return scope!.notifier!;
  }

  static ClockSettings settingsOf(BuildContext context) => of(context).value;
}
