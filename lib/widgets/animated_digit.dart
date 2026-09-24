import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/clock_settings.dart';
import 'clock_fonts.dart';

/// Одна цифра времени, которая красиво сменяется при изменении значения.
class AnimatedDigit extends StatelessWidget {
  const AnimatedDigit({
    super.key,
    required this.character,
    required this.style,
    required this.animation,
    this.width,
    this.glass = false,
  });

  final String character;
  final TextStyle style;
  final DigitAnimation animation;
  final bool glass;

  /// Фиксированная ширина ячейки: без неё «1» сдвигала бы соседние цифры.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final text = glass
        ? GlassText(
            key: ValueKey(character),
            text: character,
            style: style,
            textAlign: TextAlign.center,
          )
        : Text(
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
    DigitAnimation.blurMax => const Duration(milliseconds: 780),
    DigitAnimation.segment => const Duration(milliseconds: 450),
    DigitAnimation.sputnik => const Duration(milliseconds: 700),
    DigitAnimation.sputnikPro => const Duration(milliseconds: 920),
    DigitAnimation.sputnikMax => const Duration(milliseconds: 1180),
    DigitAnimation.stretch => const Duration(milliseconds: 500),
    DigitAnimation.fade => const Duration(milliseconds: 420),
    DigitAnimation.roll => const Duration(milliseconds: 480),
    DigitAnimation.rollMax => const Duration(milliseconds: 680),
    DigitAnimation.flip => const Duration(milliseconds: 520),
    DigitAnimation.flipMax => const Duration(milliseconds: 760),
    DigitAnimation.pop => const Duration(milliseconds: 460),
    DigitAnimation.glow => const Duration(milliseconds: 640),
    DigitAnimation.ripple => const Duration(milliseconds: 560),
    DigitAnimation.spin => const Duration(milliseconds: 520),
    DigitAnimation.drop => const Duration(milliseconds: 480),
    DigitAnimation.glitch => const Duration(milliseconds: 420),
    DigitAnimation.wipe => const Duration(milliseconds: 400),
    DigitAnimation.swing => const Duration(milliseconds: 540),
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

      case DigitAnimation.blurMax:
        return FadeTransition(
          opacity: value,
          child: AnimatedBuilder(
            animation: value,
            builder: (context, inner) {
              final t = value.value.clamp(0.0, 1.0);
              final sigma = (1 - t) * 32;
              final smeared = Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(1.7 - 0.7 * t, 0.25 + 0.75 * t, 1),
                child: inner,
              );
              if (sigma < 0.4) return smeared;
              return ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: sigma * 1.4, sigmaY: sigma),
                child: smeared,
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

      case DigitAnimation.sputnikPro:
        // Длинная орбита: цифра заходит сбоку, кувыркается и стыкуется в слот.
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            final travel = 1 - t;
            final sweep = travel * math.pi * 0.85;
            final sigma = travel * 8;
            Widget glyph = FractionalTranslation(
              translation: Offset(
                math.sin(sweep) * 1.6,
                -(1 - math.cos(sweep)) * 0.5,
              ),
              child: Transform.rotate(
                angle: travel * 1.35,
                child: Transform.scale(scale: 0.22 + 0.78 * t, child: inner),
              ),
            );
            if (sigma >= 0.45) {
              glyph = ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: sigma * 0.28,
                  sigmaY: sigma,
                ),
                child: glyph,
              );
            }
            return Opacity(
              opacity: (0.2 + 0.8 * t).clamp(0.0, 1.0),
              child: glyph,
            );
          },
          child: child,
        );

      case DigitAnimation.sputnikMax:
        // Почти полный виток: цифра прилетает издалека, сильно крутится и садится.
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            final travel = 1 - t;
            final sweep = travel * math.pi * 1.35;
            final sigma = travel * 14;
            Widget glyph = FractionalTranslation(
              translation: Offset(
                math.sin(sweep) * 2.4,
                -math.sin(sweep * 0.5) * 1.35,
              ),
              child: Transform.rotate(
                angle: travel * math.pi * 1.15,
                child: Transform.scale(scale: 0.06 + 0.94 * t, child: inner),
              ),
            );
            if (sigma >= 0.45) {
              glyph = ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: sigma * 0.45,
                  sigmaY: sigma,
                ),
                child: glyph,
              );
            }
            return Opacity(
              opacity: (0.12 + 0.88 * t).clamp(0.0, 1.0),
              child: glyph,
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

      case DigitAnimation.fade:
        return FadeTransition(opacity: value, child: child);

      case DigitAnimation.roll:
        return ClipRect(
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(value),
            child: child,
          ),
        );

      case DigitAnimation.rollMax:
        return ClipRect(
          child: AnimatedBuilder(
            animation: value,
            builder: (context, inner) {
              final t = value.value.clamp(0.0, 1.0);
              return FractionalTranslation(
                translation: Offset(0, (1 - t) * 2.4),
                child: Transform.rotate(angle: (1 - t) * 0.55, child: inner),
              );
            },
            child: child,
          ),
        );

      case DigitAnimation.flip:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: t,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX((1 - t) * math.pi / 2),
                child: inner,
              ),
            );
          },
          child: child,
        );

      case DigitAnimation.flipMax:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            final shown = t < 0.12 ? t / 0.12 : 1.0;
            return Opacity(
              opacity: shown,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX((1 - t) * math.pi * 2),
                child: Transform.scale(scale: 0.72 + 0.28 * t, child: inner),
              ),
            );
          },
          child: child,
        );

      case DigitAnimation.pop:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = Curves.easeOutBack.transform(value.value.clamp(0.0, 1.0));
            return Opacity(
              opacity: value.value.clamp(0.0, 1.0),
              child: Transform.scale(scale: t, child: inner),
            );
          },
          child: child,
        );

      case DigitAnimation.glow:
        return FadeTransition(
          opacity: value,
          child: AnimatedBuilder(
            animation: value,
            builder: (context, inner) {
              final t = value.value.clamp(0.0, 1.0);
              final sigma = (1 - t) * 22;
              final scaled = Transform.scale(scale: 0.82 + 0.18 * t, child: inner);
              if (sigma < 0.4) return scaled;
              return ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: scaled,
              );
            },
            child: child,
          ),
        );

      case DigitAnimation.ripple:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.35 + 0.65 * t, child: inner),
            );
          },
          child: child,
        );

      case DigitAnimation.spin:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: t,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY((1 - t) * math.pi / 2),
                child: inner,
              ),
            );
          },
          child: child,
        );

      case DigitAnimation.drop:
        final incoming = value.status != AnimationStatus.reverse;
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            final travel = incoming ? 1 - Curves.easeOutBack.transform(t) : 1 - t;
            return FractionalTranslation(
              translation: Offset(0, -1.15 * travel),
              child: inner,
            );
          },
          child: child,
        );

      case DigitAnimation.glitch:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            final amp = (1 - t) * 16;
            return Opacity(
              opacity: (0.4 + 0.6 * t).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(
                  math.sin(t * math.pi * 7) * amp,
                  math.sin(t * math.pi * 13) * amp * 0.2,
                ),
                child: inner,
              ),
            );
          },
          child: child,
        );

      case DigitAnimation.wipe:
        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: value.value.clamp(0.0, 1.0),
            child: child,
          ),
        );

      case DigitAnimation.swing:
        return AnimatedBuilder(
          animation: value,
          builder: (context, inner) {
            final t = value.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: t,
              child: Transform.rotate(
                alignment: Alignment.topCenter,
                angle: (1 - t) * 0.55,
                child: inner,
              ),
            );
          },
          child: child,
        );
    }
  }
}
