import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../utils/ru_date.dart';

/// Экран звонящего будильника: крупные кнопки «Отложить» и «Стоп».
class RingingOverlay extends StatelessWidget {
  const RingingOverlay({
    super.key,
    required this.alarm,
    required this.now,
    required this.onSnooze,
    required this.onDismiss,
  });

  final Alarm alarm;
  final DateTime now;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, color: Colors.white, size: 42),
            const SizedBox(height: 16),
            Text(
              '${twoDigits(now.hour)}:${twoDigits(now.minute)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 78,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (alarm.label.isNotEmpty)
              Text(
                alarm.label,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _Button(
                      label: 'Отложить ${alarm.snoozeMinutes} мин',
                      color: Colors.white.withValues(alpha: 0.16),
                      onTap: onSnooze,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Button(
                      label: 'Стоп',
                      color: const Color(0xFFFF3B30),
                      onTap: onDismiss,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
