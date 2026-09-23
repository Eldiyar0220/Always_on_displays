import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../state/alarm_controller.dart';
import '../utils/ru_date.dart';
import 'panel_shell.dart';

/// Список будильников с повторами по дням недели.
class AlarmPanel extends StatelessWidget {
  const AlarmPanel({super.key, required this.controller, this.onClose});

  static const _weekdayLabels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  final AlarmController controller;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final alarms = controller.alarms;
    final untilNext = controller.timeUntilNext;

    return PanelShell(
      title: 'Будильник',
      onClose: onClose,
      maxHeight: 400,
      footer: GestureDetector(
        onTap: () => _edit(context, null),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Новый будильник',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (untilNext != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Сигнал через ${formatCountdownWords(untilNext)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          if (alarms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Будильников пока нет',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          for (final alarm in alarms)
            _AlarmTile(
              alarm: alarm,
              onToggle: (value) => controller.toggle(alarm.id, value),
              onEdit: () => _edit(context, alarm),
              onDelete: () => controller.remove(alarm.id),
              onWeekdayTap: (weekday) {
                final weekdays = {...alarm.weekdays};
                if (!weekdays.add(weekday)) weekdays.remove(weekday);
                controller.save(alarm.copyWith(weekdays: weekdays));
              },
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, Alarm? alarm) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: alarm == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: alarm.hour, minute: alarm.minute),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (picked == null) return;
    controller.save(
      (alarm ??
              Alarm(id: DateTime.now().microsecondsSinceEpoch.toString(), hour: 7, minute: 0))
          .copyWith(hour: picked.hour, minute: picked.minute, enabled: true),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onWeekdayTap,
  });

  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onWeekdayTap;

  @override
  Widget build(BuildContext context) {
    final opacity = alarm.enabled ? 1.0 : 0.4;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Opacity(
                opacity: opacity,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Text(
                    alarm.timeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline, color: Colors.white38, size: 22),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(value: alarm.enabled, onChanged: onToggle),
            ],
          ),
          Opacity(
            opacity: opacity,
            child: Row(
              children: [
                for (var weekday = 1; weekday <= 7; weekday++)
                  GestureDetector(
                    onTap: () => onWeekdayTap(weekday),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: alarm.weekdays.contains(weekday) ? 0.28 : 0.06,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AlarmPanel._weekdayLabels[weekday - 1],
                        style: TextStyle(
                          color: alarm.weekdays.contains(weekday)
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
