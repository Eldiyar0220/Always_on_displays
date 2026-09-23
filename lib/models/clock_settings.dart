import 'package:flutter/material.dart';

/// Как цифры сменяют друг друга при смене времени.
enum DigitAnimation {
  none('Нет'),
  blur('Blur'),
  segment('Segment'),
  sputnik('Sputnik'),
  stretch('Stretch');

  const DigitAnimation(this.label);

  final String label;
}

/// Способ показать секунды рядом с крупным временем.
enum SecondsMode {
  hidden('Скрыть'),
  digits('Цифры'),
  bar('Полоса'),
  orbit('По кругу');

  const SecondsMode(this.label);

  final String label;
}

/// Куда ставить заряд и дату относительно крупных цифр.
enum InfoPlacement {
  bar('Сверху'),
  colon('В центре'),
  corners('По углам');

  const InfoPlacement(this.label);

  final String label;
}

/// Как записывать дату рядом с часами.
enum DateStyle {
  dayMonthWeek('23 Сентября СР'),
  dayMonthShort('1 Января Пн'),
  numeric('23.09.2026'),
  weekday('Среда, 23');

  const DateStyle(this.sample);

  final String sample;
}

@immutable
class ClockSettings {
  const ClockSettings({
    this.use24HourFormat = true,
    this.showLeadingZero = true,
    this.secondsMode = SecondsMode.hidden,
    this.digitColor = Colors.white,
    this.accentColor = const Color(0xFFB9B9C2),
    this.digitWeight = 8,
    this.digitScale = 1,
    this.animation = DigitAnimation.sputnik,
    this.nightTheme = true,
    this.showDate = true,
    this.showBattery = true,
    this.randomColor = false,
    this.burnInProtection = true,
    this.localBrightness = 1,
    this.flashlightEnabled = true,
    this.infoPlacement = InfoPlacement.bar,
    this.dateStyle = DateStyle.dayMonthWeek,
    this.infoIntensity = 0.7,
    this.infoFollowsDigits = false,
    this.batteryTintByLevel = true,
  });

  /// 24-часовой формат вместо AM/PM.
  final bool use24HourFormat;

  /// Показывать ведущий ноль: `01:27` против `1:27`.
  final bool showLeadingZero;
  final SecondsMode secondsMode;
  final Color digitColor;

  /// Цвет секунд, двоеточия и мелких элементов.
  final Color accentColor;

  /// Толщина цифр, 1..9 — отображается на `FontWeight`.
  final int digitWeight;

  /// Множитель размера цифр, 0.5..1.2.
  final double digitScale;
  final DigitAnimation animation;

  /// Тёмный фон со светлыми цифрами; иначе — наоборот.
  final bool nightTheme;
  final bool showDate;
  final bool showBattery;

  /// Менять цвет цифр случайным образом каждую минуту.
  final bool randomColor;

  /// Сдвигать часы по экрану, чтобы OLED не выгорал.
  final bool burnInProtection;

  /// Программное затемнение поверх системной яркости, 0.15..1.
  final double localBrightness;
  final bool flashlightEnabled;

  /// Где рисовать заряд и дату: строка сверху, бейдж в двоеточии или углы.
  final InfoPlacement infoPlacement;
  final DateStyle dateStyle;

  /// Насколько ярко видны дата и заряд, 0.15..1.
  final double infoIntensity;

  /// Дата и заряд берут цвет крупных цифр.
  final bool infoFollowsDigits;

  /// Кольцо заряда зеленеет на зарядке и краснеет, когда батарея садится.
  final bool batteryTintByLevel;

  FontWeight get fontWeight => switch (digitWeight) {
    <= 1 => FontWeight.w100,
    2 => FontWeight.w200,
    3 => FontWeight.w300,
    4 => FontWeight.w400,
    5 => FontWeight.w500,
    6 => FontWeight.w600,
    7 => FontWeight.w700,
    8 => FontWeight.w800,
    _ => FontWeight.w900,
  };

  Color get background => nightTheme ? Colors.black : const Color(0xFFF2F2F7);

  Color get foreground => nightTheme ? digitColor : _darkenForLightTheme(digitColor);

  static Color _darkenForLightTheme(Color color) {
    if (color.computeLuminance() < 0.6) return color;
    return Colors.black;
  }

  ClockSettings copyWith({
    bool? use24HourFormat,
    bool? showLeadingZero,
    SecondsMode? secondsMode,
    Color? digitColor,
    Color? accentColor,
    int? digitWeight,
    double? digitScale,
    DigitAnimation? animation,
    bool? nightTheme,
    bool? showDate,
    bool? showBattery,
    bool? randomColor,
    bool? burnInProtection,
    double? localBrightness,
    bool? flashlightEnabled,
    InfoPlacement? infoPlacement,
    DateStyle? dateStyle,
    double? infoIntensity,
    bool? infoFollowsDigits,
    bool? batteryTintByLevel,
  }) {
    return ClockSettings(
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      showLeadingZero: showLeadingZero ?? this.showLeadingZero,
      secondsMode: secondsMode ?? this.secondsMode,
      digitColor: digitColor ?? this.digitColor,
      accentColor: accentColor ?? this.accentColor,
      digitWeight: digitWeight ?? this.digitWeight,
      digitScale: digitScale ?? this.digitScale,
      animation: animation ?? this.animation,
      nightTheme: nightTheme ?? this.nightTheme,
      showDate: showDate ?? this.showDate,
      showBattery: showBattery ?? this.showBattery,
      randomColor: randomColor ?? this.randomColor,
      burnInProtection: burnInProtection ?? this.burnInProtection,
      localBrightness: localBrightness ?? this.localBrightness,
      flashlightEnabled: flashlightEnabled ?? this.flashlightEnabled,
      infoPlacement: infoPlacement ?? this.infoPlacement,
      dateStyle: dateStyle ?? this.dateStyle,
      infoIntensity: infoIntensity ?? this.infoIntensity,
      infoFollowsDigits: infoFollowsDigits ?? this.infoFollowsDigits,
      batteryTintByLevel: batteryTintByLevel ?? this.batteryTintByLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClockSettings &&
        other.use24HourFormat == use24HourFormat &&
        other.showLeadingZero == showLeadingZero &&
        other.secondsMode == secondsMode &&
        other.digitColor == digitColor &&
        other.accentColor == accentColor &&
        other.digitWeight == digitWeight &&
        other.digitScale == digitScale &&
        other.animation == animation &&
        other.nightTheme == nightTheme &&
        other.showDate == showDate &&
        other.showBattery == showBattery &&
        other.randomColor == randomColor &&
        other.burnInProtection == burnInProtection &&
        other.localBrightness == localBrightness &&
        other.flashlightEnabled == flashlightEnabled &&
        other.infoPlacement == infoPlacement &&
        other.dateStyle == dateStyle &&
        other.infoIntensity == infoIntensity &&
        other.infoFollowsDigits == infoFollowsDigits &&
        other.batteryTintByLevel == batteryTintByLevel;
  }

  @override
  int get hashCode => Object.hash(
    use24HourFormat,
    showLeadingZero,
    secondsMode,
    digitColor,
    accentColor,
    digitWeight,
    digitScale,
    animation,
    nightTheme,
    showDate,
    showBattery,
    randomColor,
    burnInProtection,
    localBrightness,
    flashlightEnabled,
    infoPlacement,
    dateStyle,
    infoIntensity,
    infoFollowsDigits,
    batteryTintByLevel,
  );

  Map<String, Object?> toJson() => {
    'use24HourFormat': use24HourFormat,
    'showLeadingZero': showLeadingZero,
    'secondsMode': secondsMode.name,
    'digitColor': digitColor.toARGB32(),
    'accentColor': accentColor.toARGB32(),
    'digitWeight': digitWeight,
    'digitScale': digitScale,
    'animation': animation.name,
    'nightTheme': nightTheme,
    'showDate': showDate,
    'showBattery': showBattery,
    'randomColor': randomColor,
    'burnInProtection': burnInProtection,
    'localBrightness': localBrightness,
    'flashlightEnabled': flashlightEnabled,
    'infoPlacement': infoPlacement.name,
    'dateStyle': dateStyle.name,
    'infoIntensity': infoIntensity,
    'infoFollowsDigits': infoFollowsDigits,
    'batteryTintByLevel': batteryTintByLevel,
  };

  factory ClockSettings.fromJson(Map<String, Object?> json) {
    const fallback = ClockSettings();
    T pick<T>(String key, T fallbackValue) {
      final value = json[key];
      return value is T ? value : fallbackValue;
    }

    return ClockSettings(
      use24HourFormat: pick('use24HourFormat', fallback.use24HourFormat),
      showLeadingZero: pick('showLeadingZero', fallback.showLeadingZero),
      secondsMode: SecondsMode.values.firstWhere(
        (mode) => mode.name == json['secondsMode'],
        orElse: () => fallback.secondsMode,
      ),
      digitColor: Color(pick('digitColor', fallback.digitColor.toARGB32())),
      accentColor: Color(pick('accentColor', fallback.accentColor.toARGB32())),
      digitWeight: pick('digitWeight', fallback.digitWeight),
      digitScale: pick('digitScale', fallback.digitScale),
      animation: DigitAnimation.values.firstWhere(
        (value) => value.name == json['animation'],
        orElse: () => fallback.animation,
      ),
      nightTheme: pick('nightTheme', fallback.nightTheme),
      showDate: pick('showDate', fallback.showDate),
      showBattery: pick('showBattery', fallback.showBattery),
      randomColor: pick('randomColor', fallback.randomColor),
      burnInProtection: pick('burnInProtection', fallback.burnInProtection),
      localBrightness: pick('localBrightness', fallback.localBrightness),
      flashlightEnabled: pick('flashlightEnabled', fallback.flashlightEnabled),
      infoPlacement: InfoPlacement.values.firstWhere(
        (value) => value.name == json['infoPlacement'],
        orElse: () => fallback.infoPlacement,
      ),
      dateStyle: DateStyle.values.firstWhere(
        (value) => value.name == json['dateStyle'],
        orElse: () => fallback.dateStyle,
      ),
      infoIntensity: pick('infoIntensity', fallback.infoIntensity),
      infoFollowsDigits: pick('infoFollowsDigits', fallback.infoFollowsDigits),
      batteryTintByLevel: pick('batteryTintByLevel', fallback.batteryTintByLevel),
    );
  }
}
