import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/clock_settings.dart';

/// Подставляет выбранный шрифт, не теряя размер, цвет и толщину.
TextStyle withClockFont(ClockFont font, TextStyle style) {
  final spaced = style.copyWith(letterSpacing: _letterSpacing(font, style.fontSize ?? 16));
  final styled = switch (font) {
    ClockFont.system => spaced,
    ClockFont.oswald => GoogleFonts.oswald(textStyle: spaced),
    ClockFont.bebas => GoogleFonts.bebasNeue(textStyle: spaced),
    ClockFont.orbitron => GoogleFonts.orbitron(textStyle: spaced),
    ClockFont.comfortaa => GoogleFonts.comfortaa(textStyle: spaced),
    ClockFont.montserrat => GoogleFonts.montserrat(textStyle: spaced),
    ClockFont.mono => GoogleFonts.shareTechMono(textStyle: spaced),
    // Стекло — это отделка поверх ровного геометрического начертания.
    ClockFont.glass => GoogleFonts.montserrat(textStyle: spaced),
  };
  return styled.copyWith(height: 1);
}

double _letterSpacing(ClockFont font, double fontSize) => switch (font) {
  ClockFont.system => -fontSize * 0.02,
  ClockFont.oswald => -fontSize * 0.03,
  ClockFont.bebas => fontSize * 0.01,
  ClockFont.orbitron => fontSize * 0.02,
  ClockFont.comfortaa => -fontSize * 0.01,
  ClockFont.montserrat => -fontSize * 0.015,
  ClockFont.mono => fontSize * 0.01,
  ClockFont.glass => fontSize * 0.02,
};

/// Качает файлы шрифтов заранее, чтобы первая смена не мигала запасным начертанием.
Future<void> preloadClockFonts() {
  return GoogleFonts.pendingFonts([
    GoogleFonts.oswald(),
    GoogleFonts.bebasNeue(),
    GoogleFonts.orbitron(),
    GoogleFonts.comfortaa(),
    GoogleFonts.montserrat(),
    GoogleFonts.shareTechMono(),
  ]);
}

/// Цифры из стекла: прозрачная середина, светлая кромка и мягкое свечение.
class GlassText extends StatelessWidget {
  const GlassText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.clip,
    this.softWrap = false,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 16;
    final tint = style.color ?? Colors.white;
    final fill = style.copyWith(color: Colors.white, shadows: const []);
    final highlight = Color.lerp(tint, Colors.white, 0.82) ?? Colors.white;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: (fontSize * 0.035).clamp(0.8, 7),
            sigmaY: (fontSize * 0.035).clamp(0.8, 7),
          ),
          child: _line(
            fill.copyWith(color: tint.withValues(alpha: 0.45)),
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              highlight.withValues(alpha: 0.96),
              tint.withValues(alpha: 0.72),
              tint.withValues(alpha: 0.16),
              tint.withValues(alpha: 0.42),
              highlight.withValues(alpha: 0.9),
            ],
            stops: const [0, 0.22, 0.5, 0.78, 1],
          ).createShader(bounds),
          child: _line(fill),
        ),
        _line(
          fill.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = (fontSize * 0.012).clamp(0.7, 2.4)
              ..color = highlight.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _line(TextStyle lineStyle) {
    return Text(
      text,
      style: lineStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
