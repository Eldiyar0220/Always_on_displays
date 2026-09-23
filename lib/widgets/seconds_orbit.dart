import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Точка секунд, которая за минуту обходит экран по периметру.
class SecondsOrbit extends StatefulWidget {
  const SecondsOrbit({super.key, required this.color});

  final Color color;

  @override
  State<SecondsOrbit> createState() => _SecondsOrbitState();
}

class _SecondsOrbitState extends State<SecondsOrbit> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final progress = (now.second + now.millisecond / 1000) / 60;
    return IgnorePointer(
      child: CustomPaint(
        painter: _OrbitPainter(progress: progress, color: widget.color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Короткий хвост позади точки, чтобы движение читалось на чёрном фоне.
    const tail = 0.035;
    for (var i = 8; i >= 1; i--) {
      final t = (progress - tail * i / 8) % 1;
      final point = secondsOrbitPoint(size, t < 0 ? t + 1 : t);
      canvas.drawCircle(
        point,
        2.2,
        Paint()..color = color.withValues(alpha: 0.08 * (9 - i) / 8),
      );
    }

    canvas.drawCircle(
      secondsOrbitPoint(size, progress),
      3.4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Положение точки на скруглённом периметре. `progress` 0 — верхняя середина,
/// дальше по часовой стрелке.
Offset secondsOrbitPoint(Size size, double progress) {
  const inset = 3.0;
  final rect = Rect.fromLTWH(
    inset,
    inset,
    max(1, size.width - inset * 2),
    max(1, size.height - inset * 2),
  );
  final radius = min(40.0, min(rect.width, rect.height) / 2);
  final straightW = rect.width - 2 * radius;
  final straightH = rect.height - 2 * radius;
  final corner = pi * radius / 2;
  final perimeter = 2 * (straightW + straightH) + 4 * corner;
  var distance = (progress % 1) * perimeter;

  Offset take(double length, Offset Function(double t) at) {
    if (distance <= length || length == 0) {
      final t = length == 0 ? 1.0 : (distance / length).clamp(0.0, 1.0);
      distance = 0;
      return at(t);
    }
    distance -= length;
    return at(1);
  }

  Offset? hit;

  // Верхняя сторона, от середины вправо.
  hit = take(straightW / 2, (t) => Offset(rect.center.dx + straightW / 2 * t, rect.top));
  if (distance == 0) return hit;

  // Правый верхний угол.
  hit = take(
    corner,
    (t) => _corner(Offset(rect.right - radius, rect.top + radius), radius, -pi / 2, t),
  );
  if (distance == 0) return hit;

  hit = take(straightH, (t) => Offset(rect.right, rect.top + radius + straightH * t));
  if (distance == 0) return hit;

  hit = take(
    corner,
    (t) => _corner(Offset(rect.right - radius, rect.bottom - radius), radius, 0, t),
  );
  if (distance == 0) return hit;

  hit = take(straightW, (t) => Offset(rect.right - radius - straightW * t, rect.bottom));
  if (distance == 0) return hit;

  hit = take(
    corner,
    (t) => _corner(Offset(rect.left + radius, rect.bottom - radius), radius, pi / 2, t),
  );
  if (distance == 0) return hit;

  hit = take(straightH, (t) => Offset(rect.left, rect.bottom - radius - straightH * t));
  if (distance == 0) return hit;

  hit = take(
    corner,
    (t) => _corner(Offset(rect.left + radius, rect.top + radius), radius, pi, t),
  );
  if (distance == 0) return hit;

  return take(straightW / 2, (t) => Offset(rect.left + radius + straightW / 2 * t, rect.top));
}

Offset _corner(Offset center, double radius, double startAngle, double t) {
  final angle = startAngle + (pi / 2) * t;
  return Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
}
