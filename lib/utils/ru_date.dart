import 'package:intl/intl.dart';

import '../models/clock_settings.dart';

const _monthsGenitive = [
  'Января',
  'Февраля',
  'Марта',
  'Апреля',
  'Мая',
  'Июня',
  'Июля',
  'Августа',
  'Сентября',
  'Октября',
  'Ноября',
  'Декабря',
];

const _weekdaysShort = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
const _weekdaysTitle = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _weekdaysFull = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

/// Дата в выбранном стиле. По умолчанию — «23 Сентября  СР».
String formatClockDate(DateTime date, [DateStyle style = DateStyle.dayMonthWeek]) {
  final month = _monthsGenitive[date.month - 1];
  return switch (style) {
    DateStyle.dayMonthWeek => '${date.day} $month  ${weekdayShort(date)}',
    DateStyle.dayMonthShort => '${date.day} $month ${_weekdaysTitle[date.weekday - 1]}',
    DateStyle.numeric => formatFullDate(date),
    DateStyle.weekday => '${weekdayFull(date)}, ${date.day}',
  };
}

String weekdayShort(DateTime date) => _weekdaysShort[date.weekday - 1];

String weekdayFull(DateTime date) => _weekdaysFull[date.weekday - 1];

/// Часы в выбранном формате, с ведущим нулём или без него.
String formatHours(DateTime time, {required bool use24Hour, required bool leadingZero}) {
  var hours = use24Hour ? time.hour : time.hour % 12;
  if (!use24Hour && hours == 0) hours = 12;
  final text = hours.toString();
  return leadingZero ? text.padLeft(2, '0') : text;
}

String twoDigits(int value) => value.toString().padLeft(2, '0');

String meridiem(DateTime time) => time.hour < 12 ? 'AM' : 'PM';

/// «1 ч 23 мин» — для подписи «до будильника».
String formatCountdownWords(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '$hours ч $minutes мин';
  if (minutes > 0) return '$minutes мин';
  return '${duration.inSeconds} сек';
}

String formatTimerDigits(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
  return '${twoDigits(minutes)}:${twoDigits(seconds)}';
}

/// «01:02.34» — минуты, секунды и сотые для секундомера.
String formatStopwatch(Duration duration) {
  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  final centis = twoDigits(duration.inMilliseconds.remainder(1000) ~/ 10);
  final clock = '$minutes:$seconds.$centis';
  if (hours > 0) return '$hours:$clock';
  return clock;
}

/// Короткая дата для панели информации.
String formatFullDate(DateTime date) =>
    DateFormat('dd.MM.yyyy').format(date);
