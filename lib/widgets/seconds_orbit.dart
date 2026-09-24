import 'dart:math';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/clock_settings.dart';

/// Точка секунд, которая за минуту обходит экран по периметру.
class SecondsOrbit extends StatefulWidget {
  const SecondsOrbit({super.key, required this.color, required this.style});

  final Color color;
  final OrbitStyle style;

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
        painter: _OrbitPainter(
          progress: progress,
          color: widget.color,
          style: widget.style,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.progress,
    required this.color,
    required this.style,
  });

  final double progress;
  final Color color;
  final OrbitStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _OrbitGeometry.of(size);
    switch (style) {
      case OrbitStyle.dot:
        _paintDot(canvas, geometry);
      case OrbitStyle.opacity:
        _paintOpacity(canvas, geometry);
      case OrbitStyle.jump:
        _paintJump(canvas, geometry);
    }
  }

  /// Маленькая точка с коротким хвостом.
  void _paintDot(Canvas canvas, _OrbitGeometry geometry) {
    const tail = 0.035;
    for (var i = 8; i >= 1; i--) {
      canvas.drawCircle(
        geometry.point(_wrap(progress - tail * i / 8)),
        2.2,
        Paint()..color = color.withValues(alpha: 0.08 * (9 - i) / 8),
      );
    }
    canvas.drawCircle(geometry.point(progress), 3.4, Paint()..color = color);
  }

  /// Сплошная дуга пройденного пути: у старта почти прозрачная, у головы яркая.
  void _paintOpacity(Canvas canvas, _OrbitGeometry geometry) {
    canvas.drawPath(geometry.path, _stroke(color.withValues(alpha: 0.14), 2));
    if (progress > 0.001) {
      const parts = 28;
      for (var i = 0; i < parts; i++) {
        final start = progress * i / parts;
        final end = progress * (i + 1) / parts;
        final fade = pow((i + 1) / parts, 1.5).toDouble();
        geometry.drawSpan(
          canvas,
          start,
          end,
          _stroke(color.withValues(alpha: fade), 3),
        );
      }
    }
    canvas.drawCircle(geometry.point(progress), 4, Paint()..color = color);
  }

  /// Раз в секунду точка перескакивает по самому краю и коротко подпрыгивает внутрь.
  void _paintJump(Canvas canvas, _OrbitGeometry geometry) {
    canvas.drawPath(geometry.path, _stroke(color.withValues(alpha: 0.12), 1.5));

    final exact = progress * 60;
    final second = exact.floor();
    final fraction = exact - second;
    const jumpWindow = 0.32;
    final jump = (fraction / jumpWindow).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(jump);
    final from = (second - 1) / 60;
    final along = jump >= 1 ? second / 60 : from + eased / 60;
    final onEdge = geometry.point(_wrap(along));
    final hop = sin(jump * pi) * 12;
    final lifted = onEdge + geometry.inward(_wrap(along)) * hop;

    canvas.drawCircle(
      geometry.point(_wrap(second / 60)),
      2,
      Paint()..color = color.withValues(alpha: 0.45),
    );
    canvas.drawCircle(lifted, 3.2 + hop * 0.12, Paint()..color = color);
  }

  Paint _stroke(Color strokeColor, double width) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = strokeColor;
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.style != style;
}

double _wrap(double progress) {
  final value = progress % 1;
  return value < 0 ? value + 1 : value;
}

/// Скруглённый периметр экрана. Ноль прогресса — верхняя середина.
class _OrbitGeometry {
  _OrbitGeometry._(this.size) {
    const inset = 3.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      max(1, size.width - inset * 2),
      max(1, size.height - inset * 2),
    );
    final radius = min(40.0, min(rect.width, rect.height) / 2);
    path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    metric = path.computeMetrics().first;
    _center = rect.center;
    _origin = _distanceOfTopCenter();
  }

  static _OrbitGeometry? _cached;

  static _OrbitGeometry of(Size size) {
    final cached = _cached;
    if (cached != null && cached.size == size) return cached;
    return _cached = _OrbitGeometry._(size);
  }

  final Size size;
  late final Path path;
  late final PathMetric metric;
  late final double _origin;
  late final Offset _center;

  Offset point(double progress) {
    return metric.getTangentForOffset(_distance(progress))!.position;
  }

  /// К центру экрана, чтобы прыжок не вылетал за край.
  Offset inward(double progress) {
    final delta = _center - point(progress);
    final length = delta.distance;
    if (length == 0) return const Offset(0, 1);
    return delta / length;
  }

  void drawSpan(Canvas canvas, double start, double end, Paint paint) {
    final length = metric.length;
    final a = _distance(start);
    final b = _distance(end);
    if ((b - a).abs() < 0.5) return;
    if (b > a) {
      canvas.drawPath(metric.extractPath(a, b), paint);
    } else {
      canvas.drawPath(metric.extractPath(a, length), paint);
      if (b > 0) canvas.drawPath(metric.extractPath(0, b), paint);
    }
  }

  double _distance(double progress) {
    final length = metric.length;
    return (_origin + _wrap(progress) * length) % length;
  }

  /// Контур начинается не сверху, поэтому один раз находим середину верхней стороны.
  double _distanceOfTopCenter() {
    final length = metric.length;
    var best = 0.0;
    var bestScore = double.infinity;
    const steps = 720;
    for (var i = 0; i < steps; i++) {
      final distance = length * i / steps;
      final position = metric.getTangentForOffset(distance)!.position;
      final score = position.dy * 1000 + (position.dx - _center.dx).abs();
      if (score < bestScore) {
        bestScore = score;
        best = distance;
      }
    }
    return best;
  }
}

/// Положение точки на скруглённом периметре. `progress` 0 — верхняя середина,
/// дальше по часовой стрелке.
Offset secondsOrbitPoint(Size size, double progress) {
  return _OrbitGeometry.of(size).point(progress);
}

