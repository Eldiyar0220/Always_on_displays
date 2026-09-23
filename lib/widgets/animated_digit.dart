import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/clock_settings.dart';

/// Одна цифра времени, которая красиво сменяется при изменении значения.
class AnimatedDigit extends StatelessWidget {
  const AnimatedDigit({
    super.key,
    required this.character,
    required this.style,
    required this.animation,
    this.width,
  });

  final String character;
  final TextStyle style;
  final DigitAnimation animation;

  /// Фиксированная ширина ячейки: без неё «1» сдвигала бы соседние цифры.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      character,
      key: ValueKey(character),
      style: style,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
    );

    final child = animation == DigitAnimation.none
        ? text
        : AnimatedSwitcher(
            duration: _durationFor(animation),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, value) =>
                _buildTransition(animation, child, value),
            // Уходящая и приходящая цифры рисуются друг поверх друга.
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.center,
              children: [...previous, ?current],
            ),
            child: text,
          );

    if (width == null) return child;
    return SizedBox(
      width: width,
      child: Center(child: child),
    );
  }

  static Duration _durationFor(DigitAnimation animation) => switch (animation) {
    DigitAnimation.none => Duration.zero,
    DigitAnimation.blur => const Duration(milliseconds: 550),
    DigitAnimation.segment => const Duration(milliseconds: 450),
    DigitAnimation.sputnik => const Duration(milliseconds: 700),
    DigitAnimation.stretch => const Duration(milliseconds: 500),
  };

  static Widget _buildTransition(
    DigitAnimation animation,
    Widget child,
    Animation<double> value,
  ) {
    switch (animation) {
      case DigitAnimation.none:
        return child;

      case DigitAnimation.blur:
        return FadeTransition(
          opacity: value,
          child: AnimatedBuilder(
            animation: value,
            builder: (context, inner) {
              final sigma = (1 - value.value) * 14;
              if (sigma < 0.1) return inner!;
              return ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: inner,
              );
            },
            child: child,
          ),
        );

      case DigitAnimation.segment:
        return ClipRect(
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(value),
            child: FadeTransition(opacity: value, child: child),
          ),
        );

      case DigitAnimation.sputnik:
        // Цифра «прилетает» по дуге, слегка вращаясь вокруг своего центра.
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value;
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 0.18 * 100),
                child: Transform.rotate(
                  angle: (1 - t) * 0.45,
                  child: Transform.scale(scale: 0.55 + 0.45 * t, child: inner),
                ),
              ),
            );
          },
          child: child,
        );

      case DigitAnimation.stretch:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1, 0.2 + 0.8 * value.value, 1),
            child: Opacity(opacity: value.value.clamp(0.0, 1.0), child: inner),
          ),
          child: child,
        );
    }
  }
}
