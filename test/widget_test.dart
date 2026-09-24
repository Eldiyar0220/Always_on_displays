import 'package:always_on_display_app/models/alarm.dart';
import 'package:always_on_display_app/models/clock_settings.dart';
import 'package:always_on_display_app/utils/ru_date.dart';
import 'package:always_on_display_app/widgets/clock_display.dart';
import 'package:always_on_display_app/widgets/seconds_orbit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  group('ClockSettings', () {
    test('переживает сохранение и чтение', () {
      const settings = ClockSettings(
        use24HourFormat: false,
        digitColor: Color(0xFFFF9F0A),
        digitWeight: 3,
        animation: DigitAnimation.stretch,
        secondsMode: SecondsMode.bar,
        customNote: 'спокойной ночи',
        notePlacement: NotePlacement.bottom,
        noteFont: ClockFont.comfortaa,
        noteWeight: 3,
        noteSize: 32,
      );

      expect(ClockSettings.fromJson(settings.toJson()), settings);
    });

    test('подставляет значения по умолчанию для незнакомых данных', () {
      final restored = ClockSettings.fromJson({'digitWeight': 'мусор'});

      expect(restored, const ClockSettings());
    });
  });

  group('Форматирование времени', () {
    test('12-часовой формат превращает полночь в 12', () {
      final midnight = DateTime(2026, 9, 23, 0, 5);

      expect(formatHours(midnight, use24Hour: false, leadingZero: false), '12');
      expect(formatHours(midnight, use24Hour: true, leadingZero: true), '00');
    });

    test('ведущий ноль отключается', () {
      final time = DateTime(2026, 9, 23, 7, 5);

      expect(formatHours(time, use24Hour: true, leadingZero: false), '7');
      expect(formatHours(time, use24Hour: true, leadingZero: true), '07');
    });

    test('дата собирается по-русски', () {
      final date = DateTime(2026, 9, 23);
      expect(formatClockDate(date), '23 Сентября  СР');
      expect(formatClockDate(date, DateStyle.dayMonthShort), '23 Сентября Ср');
      expect(formatClockDate(date, DateStyle.weekday), 'Среда, 23');
    });
  });

  group('Alarm', () {
    test('разовый будильник переносится на завтра, если время прошло', () {
      const alarm = Alarm(id: 'a', hour: 7, minute: 0);
      final now = DateTime(2026, 9, 23, 9, 0);

      expect(alarm.nextTrigger(now), DateTime(2026, 9, 24, 7, 0));
    });

    test('будильник с повторами ждёт нужный день недели', () {
      // 23.09.2026 — среда, ближайшая суббота 26-го.
      const alarm = Alarm(
        id: 'a',
        hour: 7,
        minute: 0,
        weekdays: {DateTime.saturday},
      );
      final now = DateTime(2026, 9, 23, 9, 0);

      expect(alarm.nextTrigger(now), DateTime(2026, 9, 26, 7, 0));
    });
  });

  testWidgets('ClockDisplay рисует часы и минуты', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: ClockDisplay(
              time: DateTime(2026, 9, 23, 17, 6),
              settings: const ClockSettings(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('стеклянные цифры рисуются без ошибки', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 200,
            child: ClockDisplay(
              time: DateTime(2026, 9, 23, 17, 6),
              settings: const ClockSettings(
                clockFont: ClockFont.glass,
                animation: DigitAnimation.none,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('узкие секунды не меняют ширину крупных часов', (tester) async {
    const settings = ClockSettings(
      secondsMode: SecondsMode.digits,
      animation: DigitAnimation.none,
    );

    Future<double> unscaledWidth(int second) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: ClockDisplay(
                time: DateTime(2026, 9, 23, 17, 6, second),
                settings: settings,
              ),
            ),
          ),
        ),
      );
      final fitted = tester.renderObject<RenderFittedBox>(
        find.byType(FittedBox),
      );
      return fitted.child!.size.width;
    }

    // «11» заметно уже «00»: раньше из‑за этого FittedBox перемасштабировал часы.
    final narrow = await unscaledWidth(11);
    final wide = await unscaledWidth(0);

    expect(narrow, moreOrLessEquals(wide, epsilon: 0.5));
  });

  test('точка секунд стартует сверху и через полминуты оказывается снизу', () {
    const size = Size(200, 400);
    final start = secondsOrbitPoint(size, 0);
    final half = secondsOrbitPoint(size, 0.5);

    expect(start.dx, moreOrLessEquals(size.width / 2, epsilon: 1));
    expect(start.dy, lessThan(20));
    expect(half.dx, moreOrLessEquals(size.width / 2, epsilon: 1));
    expect(half.dy, greaterThan(size.height - 20));
  });
}
