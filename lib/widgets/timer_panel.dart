import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/clock_settings.dart';
import '../state/countdown_controller.dart';
import '../state/settings_controller.dart';
import '../state/stopwatch_controller.dart';
import '../utils/ru_date.dart';
import 'animated_digit.dart';
import 'clock_display.dart';
import 'panel_shell.dart';

enum _TimerKind { countdown, stopwatch }

/// Таймер: обратный отсчёт и секундомер в одном листе.
class TimerPanel extends StatefulWidget {
  const TimerPanel({
    super.key,
    required this.countdown,
    required this.stopwatch,
    this.onClose,
  });

  final CountdownController countdown;
  final StopwatchController stopwatch;
  final VoidCallback? onClose;

  @override
  State<TimerPanel> createState() => _TimerPanelState();
}

class _TimerPanelState extends State<TimerPanel> {
  static const _presets = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 20),
    Duration(minutes: 25),
    Duration(minutes: 45),
  ];

  late _TimerKind _kind;

  @override
  void initState() {
    super.initState();
    _kind = widget.stopwatch.isActive && !widget.countdown.isActive
        ? _TimerKind.stopwatch
        : _TimerKind.countdown;
  }

  @override
  Widget build(BuildContext context) {
    final countdown = widget.countdown;
    final stopwatch = widget.stopwatch;
    final countingDown = _kind == _TimerKind.countdown;

    return PanelShell(
      title: 'Таймер',
      onClose: widget.onClose,
      maxHeight: 440,
      footer: countingDown ? _countdownFooter(countdown) : _stopwatchFooter(stopwatch),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedChips<_TimerKind>(
            values: _TimerKind.values,
            selected: _kind,
            labelOf: (kind) => kind == _TimerKind.countdown ? 'Отсчёт' : 'Секундомер',
            onChanged: (kind) => setState(() => _kind = kind),
          ),
          const SizedBox(height: 10),
          SegmentedChips<TimerVisual>(
            values: TimerVisual.values,
            selected: SettingsScope.of(context).value.timerVisual,
            labelOf: (value) => value.label,
            onChanged: (value) => SettingsScope.of(context).update(
              (current) => current.copyWith(timerVisual: value),
            ),
          ),
          if (SettingsScope.of(context).value.timerVisual == TimerVisual.orbit) ...[
            const SizedBox(height: 10),
            SegmentedChips<OrbitStyle>(
              values: OrbitStyle.values,
              selected: SettingsScope.of(context).value.orbitStyle,
              labelOf: (value) => value.label,
              onChanged: (value) => SettingsScope.of(context).update(
                (current) => current.copyWith(orbitStyle: value),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (countingDown) _countdownBody(countdown) else _stopwatchBody(stopwatch),
        ],
      ),
    );
  }

  Widget _countdownFooter(CountdownController countdown) {
    final active = countdown.isActive || countdown.status == CountdownStatus.finished;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: switch (countdown.status) {
              CountdownStatus.running => 'Пауза',
              CountdownStatus.paused => 'Продолжить',
              CountdownStatus.finished => 'Стоп',
              CountdownStatus.idle => 'Старт',
            },
            primary: true,
            onTap: () => switch (countdown.status) {
              CountdownStatus.running => countdown.pause(),
              CountdownStatus.paused => countdown.resume(),
              CountdownStatus.finished => countdown.stop(),
              CountdownStatus.idle => countdown.start(),
            },
          ),
        ),
        if (active) ...[
          const SizedBox(width: 10),
          Expanded(child: _ActionButton(label: 'Сброс', onTap: countdown.stop)),
        ],
      ],
    );
  }

  Widget _stopwatchFooter(StopwatchController stopwatch) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: switch (stopwatch.status) {
              StopwatchStatus.running => 'Пауза',
              StopwatchStatus.paused => 'Продолжить',
              StopwatchStatus.idle => 'Старт',
            },
            primary: true,
            onTap: () => switch (stopwatch.status) {
              StopwatchStatus.running => stopwatch.pause(),
              StopwatchStatus.paused => stopwatch.start(),
              StopwatchStatus.idle => stopwatch.start(),
            },
          ),
        ),
        if (stopwatch.isActive) ...[
          const SizedBox(width: 10),
          Expanded(child: _ActionButton(label: 'Сброс', onTap: stopwatch.reset)),
        ],
      ],
    );
  }

  Widget _countdownBody(CountdownController countdown) {
    final configured = countdown.configured;
    final minutes = configured.inMinutes;
    final seconds = configured.inSeconds.remainder(60);
    final active = countdown.isActive || countdown.status == CountdownStatus.finished;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Stepper(
              value: minutes,
              max: 180,
              unit: 'мин',
              onChanged: (value) => countdown.configure(
                Duration(minutes: value, seconds: seconds),
              ),
            ),
            const SizedBox(width: 20),
            _Stepper(
              value: seconds,
              max: 59,
              unit: 'сек',
              onChanged: (value) => countdown.configure(
                Duration(minutes: minutes, seconds: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              GestureDetector(
                onTap: () => countdown.configure(preset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: preset == configured ? 0.24 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${preset.inMinutes} мин',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
        if (active) ...[
          const SizedBox(height: 16),
          Text(
            formatTimerDigits(countdown.remaining),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }

  Widget _stopwatchBody(StopwatchController stopwatch) {
    return Text(
      formatStopwatch(stopwatch.elapsed),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Время идущего отсчёта и секундомера на циферблате.
class RunningTimers extends StatefulWidget {
  const RunningTimers({
    super.key,
    required this.countdown,
    required this.stopwatch,
    required this.color,
  });

  final CountdownController countdown;
  final StopwatchController stopwatch;
  final Color color;

  @override
  State<RunningTimers> createState() => _RunningTimersState();
}

class _RunningTimersState extends State<RunningTimers> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker(false);
    widget.countdown.addListener(_onChange);
    widget.stopwatch.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant RunningTimers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countdown != widget.countdown) {
      oldWidget.countdown.removeListener(_onChange);
      widget.countdown.addListener(_onChange);
    }
    if (oldWidget.stopwatch != widget.stopwatch) {
      oldWidget.stopwatch.removeListener(_onChange);
      widget.stopwatch.addListener(_onChange);
    }
    _syncTicker(false);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.countdown.removeListener(_onChange);
    widget.stopwatch.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    _syncTicker(false);
    if (mounted) setState(() {});
  }

  int? _interval;

  /// Сотые секундомера двигаются чаще, чем общий тик экрана.
  /// Кольцо и волна тикают ещё чаще, чтобы ход был плавным.
  void _syncTicker(bool smooth) {
    final running = widget.stopwatch.status == StopwatchStatus.running ||
        (smooth && widget.countdown.status == CountdownStatus.running);
    final interval = smooth ? 16 : 80;
    if (running) {
      if (_ticker != null && _interval == interval) return;
      _ticker?.cancel();
      _interval = interval;
      _ticker = Timer.periodic(Duration(milliseconds: interval), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
      _interval = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final countdown = widget.countdown;
    final stopwatch = widget.stopwatch;
    final showCountdown =
        countdown.isActive || countdown.status == CountdownStatus.finished;
    final showStopwatch = stopwatch.isActive;
    if (!showCountdown && !showStopwatch) return const SizedBox.shrink();

    final settings = SettingsScope.settingsOf(context);
    final smooth = settings.timerVisual == TimerVisual.ring ||
        settings.timerVisual == TimerVisual.wave;
    _syncTicker(smooth);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCountdown)
          _Readout(
            label: 'Отсчёт',
            value: formatTimerDigits(countdown.remaining),
            color: countdown.status == CountdownStatus.finished
                ? const Color(0xFFFF3B30)
                : widget.color,
            dimmed: countdown.status == CountdownStatus.paused,
            animation: settings.animation,
            visual: settings.timerVisual,
            progress: _countdownProgress(countdown),
          ),
        if (showCountdown && showStopwatch) const SizedBox(height: 8),
        if (showStopwatch)
          _Readout(
            label: 'Секундомер',
            value: formatStopwatch(stopwatch.elapsed),
            color: widget.color,
            dimmed: stopwatch.status == StopwatchStatus.paused,
            animation: settings.animation,
            visual: settings.timerVisual,
            progress: (stopwatch.elapsed.inMilliseconds % 60000) / 60000,
          ),
      ],
    );
  }

  double _countdownProgress(CountdownController countdown) {
    final total = countdown.configured.inMilliseconds;
    if (total <= 0) return 0;
    final left = countdown.remaining.inMilliseconds.clamp(0, total);
    return 1 - left / total;
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.label,
    required this.value,
    required this.color,
    required this.dimmed,
    required this.animation,
    required this.visual,
    required this.progress,
  });

  final String label;
  final String value;
  final Color color;
  final bool dimmed;
  final DigitAnimation animation;
  final TimerVisual visual;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Сотые у секундомера меняются слишком часто для смены цифры.
    final dot = value.indexOf('.');
    final head = dot == -1 ? value : value.substring(0, dot);
    final tail = dot == -1 ? '' : value.substring(dot);
    final digitWidth = ClockDisplay.measureDigitWidth(style);

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < head.length; i++)
                _digit(head[i], i, style, digitWidth),
              if (tail.isNotEmpty) Text(tail, style: style),
            ],
          ),
          if (visual == TimerVisual.bar) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 112,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (visual == TimerVisual.ring) ...[
            const SizedBox(height: 8),
            _TimerRing(progress: progress, color: color),
          ],
          if (visual == TimerVisual.wave) ...[
            const SizedBox(height: 8),
            _TimerWave(progress: progress, color: color),
          ],
        ],
      ),
    );
  }

  Widget _digit(String character, int index, TextStyle style, double digitWidth) {
    if (int.tryParse(character) == null) {
      return Text(character, style: style);
    }
    return AnimatedDigit(
      key: ValueKey('slot-$index'),
      character: character,
      style: style,
      animation: animation,
      width: digitWidth,
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0, 1), color: color),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: 0.18);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress * 6.2832,
      false,
      arc,
    );
    final angle = -1.5708 + progress * 6.2832;
    canvas.drawCircle(
      Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
      3.2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _TimerWave extends StatelessWidget {
  const _TimerWave({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const count = 16;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: 5,
            height: 5 + 7 * _glow(i, count),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16 + 0.84 * _glow(i, count)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }

  double _glow(int index, int count) {
    final x = index / (count - 1);
    final delta = (x - progress).abs();
    final wrapped = delta < 0.5 ? delta : 1 - delta;
    return (1 - wrapped / 0.16).clamp(0.0, 1.0);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final int value;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _arrow(Icons.keyboard_arrow_up, () => onChanged((value + 1) % (max + 1))),
        Container(
          width: 74,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        _arrow(Icons.keyboard_arrow_down, () => onChanged(value == 0 ? max : value - 1)),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: Colors.white70, size: 26),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF0A84FF) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
