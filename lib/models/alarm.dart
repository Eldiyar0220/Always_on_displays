import 'package:flutter/foundation.dart';

@immutable
class Alarm {
  const Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.weekdays = const {},
    this.label = '',
    this.snoozeMinutes = 9,
  });

  final String id;
  final int hour;
  final int minute;
  final bool enabled;

  /// Дни недели по нумерации `DateTime.monday`..`DateTime.sunday`.
  /// Пустое множество означает однократное срабатывание.
  final Set<int> weekdays;
  final String label;
  final int snoozeMinutes;

  bool get repeats => weekdays.isNotEmpty;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Ближайшее срабатывание после [from].
  DateTime nextTrigger(DateTime from) {
    var candidate = DateTime(from.year, from.month, from.day, hour, minute);
    if (!candidate.isAfter(from)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    if (!repeats) return candidate;
    for (var i = 0; i < 7; i++) {
      final day = candidate.add(Duration(days: i));
      if (weekdays.contains(day.weekday)) return day;
    }
    return candidate;
  }

  Alarm copyWith({
    int? hour,
    int? minute,
    bool? enabled,
    Set<int>? weekdays,
    String? label,
    int? snoozeMinutes,
  }) {
    return Alarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      weekdays: weekdays ?? this.weekdays,
      label: label ?? this.label,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'weekdays': weekdays.toList(),
    'label': label,
    'snoozeMinutes': snoozeMinutes,
  };

  factory Alarm.fromJson(Map<String, Object?> json) => Alarm(
    id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    hour: json['hour'] as int? ?? 7,
    minute: json['minute'] as int? ?? 0,
    enabled: json['enabled'] as bool? ?? true,
    weekdays: {...?(json['weekdays'] as List?)?.cast<int>()},
    label: json['label'] as String? ?? '',
    snoozeMinutes: json['snoozeMinutes'] as int? ?? 9,
  );
}
