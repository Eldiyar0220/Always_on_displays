import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:torch_light/torch_light.dart';

@immutable
class BatteryStatus {
  const BatteryStatus({required this.level, required this.charging});

  final int level;
  final bool charging;

  @override
  bool operator ==(Object other) =>
      other is BatteryStatus &&
      other.level == level &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(level, charging);
}

/// Опрашивает уровень заряда и следит за подключением зарядки.
class BatteryMonitor extends ValueNotifier<BatteryStatus> {
  BatteryMonitor() : super(const BatteryStatus(level: 100, charging: false)) {
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    _stateSubscription = _battery.onBatteryStateChanged.listen((_) => _refresh());
  }

  final _battery = Battery();
  Timer? _poll;
  StreamSubscription<BatteryState>? _stateSubscription;

  Future<void> _refresh() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final charging =
          state == BatteryState.charging || state == BatteryState.full;
      value = BatteryStatus(level: level, charging: charging);
    } on Object {
      // Симуляторы и десктоп могут не отдавать заряд — оставляем прошлое значение.
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}

/// Управляет системной яркостью только на время работы приложения.
class BrightnessService {
  final _screenBrightness = ScreenBrightness();

  Future<void> apply(double value) async {
    try {
      await _screenBrightness.setApplicationScreenBrightness(
        value.clamp(0.0, 1.0),
      );
    } on Object {
      // Платформа может не поддерживать управление яркостью.
    }
  }

  Future<void> restore() async {
    try {
      await _screenBrightness.resetApplicationScreenBrightness();
    } on Object {
      // Нечего восстанавливать.
    }
  }
}

/// Фонарик с запоминанием состояния, чтобы UI показывал актуальную кнопку.
class TorchService extends ValueNotifier<bool> {
  TorchService() : super(false);

  Future<bool> isAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } on Object {
      return false;
    }
  }

  Future<void> toggle() => setEnabled(!value);

  Future<void> setEnabled(bool enabled) async {
    try {
      if (enabled) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
      value = enabled;
    } on Object {
      value = false;
    }
  }

  @override
  void dispose() {
    if (value) TorchLight.disableTorch().ignore();
    super.dispose();
  }
}
