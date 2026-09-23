import 'package:flutter/material.dart';

import '../models/clock_settings.dart';
import '../services/device_services.dart';
import '../utils/ru_date.dart';
import 'animated_digit.dart';
import 'charge_badge.dart';

/// Крупное время во весь экран: часы, двоеточие, минуты и, при желании, секунды.
class ClockDisplay extends StatelessWidget {
  const ClockDisplay({
    super.key,
    required this.time,
    required this.settings,
    this.colonVisible = true,
    this.battery,
  });

  /// Все размеры считаются от этого кегля, а затем масштабируются [FittedBox].
  static const _referenceFontSize = 220.0;

  final DateTime time;
  final ClockSettings settings;

  /// Мигание двоеточия раз в секунду.
  final bool colonVisible;

  /// Нужен только для бейджа заряда внутри двоеточия.
  final BatteryStatus? battery;

  @override
  Widget build(BuildContext context) {
    final color = settings.foreground;
    final style = TextStyle(
      fontSize: _referenceFontSize,
      fontWeight: settings.fontWeight,
      color: color,
      height: 1,
      letterSpacing: -_referenceFontSize * 0.02,
    );

    final digitWidth = measureDigitWidth(style);
    final hours = formatHours(
      time,
      use24Hour: settings.use24HourFormat,
      leadingZero: settings.showLeadingZero,
    );
    final minutes = twoDigits(time.minute);

    final cells = <Widget>[
      for (var i = 0; i < hours.length; i++)
        AnimatedDigit(
          key: ValueKey('hour-$i-${hours.length}'),
          character: hours[i],
          style: style,
          animation: settings.animation,
          width: digitWidth,
        ),
      _Colon(
        key: const ValueKey('colon'),
        width: digitWidth * 0.42,
        size: _referenceFontSize,
        color: settings.accentColor,
        visible: colonVisible,
        badge: settings.infoPlacement == InfoPlacement.colon &&
                settings.showBattery &&
                battery != null
            ? ColonChargeBadge(
                status: battery!,
                settings: settings,
                digitSize: _referenceFontSize,
              )
            : null,
      ),
      for (var i = 0; i < minutes.length; i++)
        AnimatedDigit(
          key: ValueKey('minute-$i'),
          character: minutes[i],
          style: style,
          animation: settings.animation,
          width: digitWidth,
        ),
    ];

    return FittedBox(
      fit: BoxFit.contain,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...cells,
          if (settings.secondsMode == SecondsMode.digits)
            _SideColumn(
              seconds: twoDigits(time.second),
              meridiem: settings.use24HourFormat ? null : meridiem(time),
              style: style,
              accent: settings.accentColor,
              animation: settings.animation,
            )
          else if (!settings.use24HourFormat)
            _SideColumn(
              seconds: null,
              meridiem: meridiem(time),
              style: style,
              accent: settings.accentColor,
              animation: settings.animation,
            ),
        ],
      ),
    );
  }

  /// Ширина ячейки под цифру: берём самый широкий из знаков 0–9,
  /// чтобы при смене цифр строка не «дышала».
  static double measureDigitWidth(TextStyle style) {
    var widest = 0.0;
    for (var digit = 0; digit <= 9; digit++) {
      final painter = TextPainter(
        text: TextSpan(text: '$digit', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      widest = widest > painter.width ? widest : painter.width;
      painter.dispose();
    }
    return widest;
  }
}

class _Colon extends StatelessWidget {
  const _Colon({
    super.key,
    required this.width,
    required this.size,
    required this.color,
    required this.visible,
    this.badge,
  });

  final double width;
  final double size;
  final Color color;
  final bool visible;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.1;
    final dots = AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: visible ? 1 : 0.15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(dot),
          SizedBox(height: dot * 1.3),
          _dot(dot),
        ],
      ),
    );

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (badge == null)
            dots
          else
            Align(alignment: const Alignment(0, 0.55), child: dots),
          if (badge != null)
            Positioned(
              top: size * 0.02,
              child: badge!,
            ),
        ],
      ),
    );
  }

  Widget _dot(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
  );
}

/// Узкая колонка справа от минут: секунды и/или AM/PM.
class _SideColumn extends StatelessWidget {
  const _SideColumn({
    required this.seconds,
    required this.meridiem,
    required this.style,
    required this.accent,
    required this.animation,
  });

  final String? seconds;
  final String? meridiem;
  final TextStyle style;
  final Color accent;
  final DigitAnimation animation;

  @override
  Widget build(BuildContext context) {
    final smallStyle = style.copyWith(
      fontSize: style.fontSize! * 0.3,
      color: accent,
    );
    return Padding(
      padding: EdgeInsets.only(left: style.fontSize! * 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meridiem != null)
            Text(meridiem!, style: smallStyle.copyWith(letterSpacing: 0)),
          if (seconds != null)
            _FixedDigits(
              text: seconds!,
              style: smallStyle,
              animation: animation,
            ),
        ],
      ),
    );
  }
}

/// Цифры в ячейках одинаковой ширины. «1» уже «8», и без фиксированной
/// ячейки строка дышит, а [FittedBox] из‑за этого дёргает крупные часы.
class _FixedDigits extends StatelessWidget {
  const _FixedDigits({
    required this.text,
    required this.style,
    required this.animation,
  });

  final String text;
  final TextStyle style;
  final DigitAnimation animation;

  @override
  Widget build(BuildContext context) {
    final cellWidth = ClockDisplay.measureDigitWidth(style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          AnimatedDigit(
            key: ValueKey('$i'),
            character: text[i],
            style: style,
            animation: animation,
            width: cellWidth,
          ),
      ],
    );
  }
}

/// Тонкая полоса, заполняющаяся за минуту — «аналоговые» секунды.
class SecondsBar extends StatelessWidget {
  const SecondsBar({super.key, required this.time, required this.color});

  final DateTime time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (time.second + time.millisecond / 1000) / 60;
    return SizedBox(
      height: 4,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
