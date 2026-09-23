import 'package:flutter/material.dart';

import '../utils/ru_date.dart';
import 'panel_shell.dart';

/// Шпаргалка по жестам и текущая дата целиком.
class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.now, this.onClose});

  static const _gestures = [
    (Icons.touch_app_outlined, 'Касание', 'Показать или скрыть панель управления'),
    (Icons.swipe_vertical, 'Свайп вверх/вниз', 'Яркость экрана'),
    (Icons.swipe, 'Свайп влево/вправо', 'Размер цифр'),
    (Icons.ads_click, 'Двойное касание', 'Режим секунд'),
    (Icons.back_hand_outlined, 'Долгое нажатие', 'Фонарик'),
  ];

  final DateTime now;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return PanelShell(
      title: 'Управление жестами',
      onClose: onClose,
      maxHeight: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${weekdayFull(now)}, ${formatFullDate(now)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          for (final (icon, title, description) in _gestures)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          description,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
