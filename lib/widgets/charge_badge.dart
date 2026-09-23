import 'package:flutter/material.dart';

import '../models/clock_settings.dart';
import '../services/device_services.dart';

/// Цвет даты и процентов: интенсивность и, по желанию, цвет самих цифр.
Color secondaryInfoColor(ClockSettings settings) {
  final base = settings.infoFollowsDigits ? settings.foreground : settings.foreground;
  final alpha = settings.infoFollowsDigits
      ? settings.infoIntensity
      : settings.infoIntensity * 0.8;
  return base.withValues(alpha: alpha.clamp(0.15, 1.0));
}

/// Цвет кольца заряда. При включённой индикации зелёный на зарядке
/// и красный, когда батарея почти села.
Color chargeAccentColor(ClockSettings settings, BatteryStatus status) {
  if (settings.batteryTintByLevel) {
    if (status.charging) return const Color(0xFF34C759);
    if (status.level <= 20) return const Color(0xFFFF3B30);
    if (status.level <= 40) return const Color(0xFFFF9F0A);
  }
  return secondaryInfoColor(settings);
}

/// Кольцо уровня заряда с молнией, если телефон подключён к сети.
class ChargeRing extends StatelessWidget {
  const ChargeRing({
    super.key,
    required this.status,
    required this.color,
    this.size = 26,
  });

  final BatteryStatus status;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: status.level / 100,
            strokeWidth: size * 0.085,
            backgroundColor: color.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Icon(
            status.charging ? Icons.bolt : Icons.battery_std,
            size: size * 0.54,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Бейдж «100%» поверх двоеточия. Размеры заданы в тех же единицах,
/// что и крупные цифры, поэтому после [FittedBox] он остаётся пропорциональным
/// и не раздвигает строку часов.
class ColonChargeBadge extends StatelessWidget {
  const ColonChargeBadge({
    super.key,
    required this.status,
    required this.settings,
    required this.digitSize,
  });

  final BatteryStatus status;
  final ClockSettings settings;
  final double digitSize;

  @override
  Widget build(BuildContext context) {
    final accent = chargeAccentColor(settings, status);
    final label = secondaryInfoColor(settings);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: digitSize * 0.06,
        vertical: digitSize * 0.035,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(digitSize * 0.08),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChargeRing(status: status, color: accent, size: digitSize * 0.16),
          SizedBox(height: digitSize * 0.012),
          Text(
            '${status.level}%',
            style: TextStyle(
              color: label,
              fontSize: digitSize * 0.075,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
