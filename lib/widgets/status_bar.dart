import 'package:flutter/material.dart';

import '../models/clock_settings.dart';
import '../services/device_services.dart';
import '../utils/ru_date.dart';
import 'charge_badge.dart';

/// Верхняя строка: заряд слева, дата справа.
/// Глазки для быстрого скрытия появляются только вместе с панелью управления.
class ClockStatusBar extends StatelessWidget {
  const ClockStatusBar({
    super.key,
    required this.settings,
    required this.battery,
    required this.date,
    required this.controlsVisible,
    required this.onToggleBattery,
    required this.onToggleDate,
  });

  final ClockSettings settings;
  final BatteryStatus battery;
  final DateTime date;
  final bool controlsVisible;
  final VoidCallback onToggleBattery;
  final VoidCallback onToggleDate;

  @override
  Widget build(BuildContext context) {
    final muted = secondaryInfoColor(settings);
    final textStyle = TextStyle(
      color: muted,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    final showInBar = settings.infoPlacement == InfoPlacement.bar;

    return Row(
      children: [
        if (controlsVisible)
          _EyeButton(
            active: settings.showBattery,
            color: muted,
            onPressed: onToggleBattery,
          ),
        if (showInBar && settings.showBattery) ...[
          const SizedBox(width: 6),
          ChargeRing(
            status: battery,
            color: chargeAccentColor(settings, battery),
          ),
          const SizedBox(width: 8),
          Text('${battery.level}%', style: textStyle),
        ],
        const Spacer(),
        if (showInBar && settings.showDate)
          Text(formatClockDate(date, settings.dateStyle), style: textStyle),
        if (controlsVisible) ...[
          const SizedBox(width: 6),
          _EyeButton(
            active: settings.showDate,
            color: muted,
            onPressed: onToggleDate,
          ),
        ],
      ],
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({
    required this.active,
    required this.color,
    required this.onPressed,
  });

  final bool active;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Icon(
        active ? Icons.visibility : Icons.visibility_off,
        size: 20,
        color: active ? const Color(0xFF0A84FF) : color,
      ),
    );
  }
}
