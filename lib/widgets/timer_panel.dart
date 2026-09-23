import 'package:flutter/material.dart';

import '../state/countdown_controller.dart';
import '../utils/ru_date.dart';
import 'panel_shell.dart';

/// Настройка и управление таймером обратного отсчёта.
class TimerPanel extends StatelessWidget {
  const TimerPanel({super.key, required this.controller, this.onClose});

  static const _presets = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 20),
    Duration(minutes: 25),
    Duration(minutes: 45),
  ];

  final CountdownController controller;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final configured = controller.configured;
    final minutes = configured.inMinutes;
    final seconds = configured.inSeconds.remainder(60);
    final active = controller.isActive || controller.status == CountdownStatus.finished;

    return PanelShell(
      title: 'Таймер',
      onClose: onClose,
      maxHeight: 340,
      footer: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: switch (controller.status) {
                CountdownStatus.running => 'Пауза',
                CountdownStatus.paused => 'Продолжить',
                CountdownStatus.finished => 'Стоп',
                CountdownStatus.idle => 'Старт',
              },
              primary: true,
              onTap: () => switch (controller.status) {
                CountdownStatus.running => controller.pause(),
                CountdownStatus.paused => controller.resume(),
                CountdownStatus.finished => controller.stop(),
                CountdownStatus.idle => controller.start(),
              },
            ),
          ),
          if (active) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(label: 'Сброс', onTap: controller.stop),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stepper(
                value: minutes,
                max: 180,
                unit: 'мин',
                onChanged: (value) => controller.configure(
                  Duration(minutes: value, seconds: seconds),
                ),
              ),
              const SizedBox(width: 20),
              _Stepper(
                value: seconds,
                max: 59,
                unit: 'сек',
                onChanged: (value) => controller.configure(
                  Duration(minutes: minutes, seconds: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _presets)
                GestureDetector(
                  onTap: () => controller.configure(preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: preset == configured ? 0.24 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${preset.inMinutes} мин',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (active)
            Text(
              formatTimerDigits(controller.remaining),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final int value;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _arrow(Icons.keyboard_arrow_up, () => onChanged((value + 1) % (max + 1))),
        Container(
          width: 74,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        _arrow(Icons.keyboard_arrow_down, () => onChanged(value == 0 ? max : value - 1)),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: Colors.white70, size: 26),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? const Color(0xFF0A84FF)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
