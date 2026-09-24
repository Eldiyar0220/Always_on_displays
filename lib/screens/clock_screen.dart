import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/clock_settings.dart';
import '../services/device_services.dart';
import '../state/alarm_controller.dart';
import '../state/countdown_controller.dart';
import '../state/settings_controller.dart';
import '../state/stopwatch_controller.dart';
import '../utils/ru_date.dart';
import '../widgets/alarm_panel.dart';
import '../widgets/charge_badge.dart';
import '../widgets/clock_display.dart';
import '../widgets/clock_fonts.dart';
import '../widgets/control_dock.dart';
import '../widgets/info_panel.dart';
import '../widgets/quick_bar.dart';
import '../widgets/ringing_overlay.dart';
import '../widgets/seconds_orbit.dart';
import '../widgets/settings_panel.dart';
import '../widgets/status_bar.dart';
import '../widgets/timer_panel.dart';

/// Главный экран: часы во весь экран плюс скрытая панель управления.
class ClockScreen extends StatefulWidget {
  const ClockScreen({
    super.key,
    required this.battery,
    required this.torch,
    required this.brightnessService,
    required this.countdown,
    required this.stopwatch,
    required this.alarms,
  });

  final BatteryMonitor battery;
  final TorchService torch;
  final BrightnessService brightnessService;
  final CountdownController countdown;
  final StopwatchController stopwatch;
  final AlarmController alarms;

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> with WidgetsBindingObserver {
  /// Панель управления прячется сама, чтобы ночью ничего не светилось.
  static const _autoHide = Duration(seconds: 8);

  Timer? _ticker;
  Timer? _hideTimer;
  DateTime _now = DateTime.now();
  bool _controlsVisible = false;
  bool _screenLight = false;
  DockPanel? _panel;
  int _lastColorMinute = -1;
  SettingsController? _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = SettingsScope.of(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setWakelock(true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _onTick(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _setWakelock(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.brightnessService.restore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Фонарик не должен гореть, когда приложение ушло в фон.
    if (state == AppLifecycleState.paused && widget.torch.value) {
      widget.torch.setEnabled(false);
    }
  }

  /// Не на каждой платформе есть wakelock, и это не повод падать.
  Future<void> _setWakelock(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } on Object {
      // Платформа не умеет держать экран включённым.
    }
  }

  void _onTick() {
    final now = DateTime.now();
    final settings = _settings;
    if (settings != null &&
        settings.value.randomColor &&
        now.minute != _lastColorMinute) {
      _lastColorMinute = now.minute;
      settings.shuffleDigitColor();
    }
    setState(() => _now = now);
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _restartHideTimer();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    // Открытый лист (настройки, таймер, будильник) не прячется сам.
    if (_panel != null) return;
    _hideTimer = Timer(_autoHide, () {
      if (!mounted) return;
      setState(() {
        _controlsVisible = false;
        _panel = null;
      });
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() {
        _controlsVisible = false;
        _panel = null;
      });
    } else {
      _showControls();
    }
  }

  void _selectPanel(DockPanel panel) {
    setState(() => _panel = _panel == panel ? null : panel);
    _restartHideTimer();
  }

  void _cycleSecondsMode() {
    final controller = SettingsScope.of(context);
    final modes = SecondsMode.values;
    final next =
        modes[(modes.indexOf(controller.value.secondsMode) + 1) % modes.length];
    controller.update((current) => current.copyWith(secondsMode: next));
  }

  /// Вертикальный свайп — яркость, горизонтальный — размер цифр.
  void _onVerticalDrag(DragUpdateDetails details, Size size) {
    final controller = SettingsScope.of(context);
    final delta = -details.primaryDelta! / size.height;
    final next = (controller.value.localBrightness + delta).clamp(0.05, 1.0);
    controller.update((current) => current.copyWith(localBrightness: next));
    widget.brightnessService.apply(next);
  }

  void _onHorizontalDrag(DragUpdateDetails details, Size size) {
    final controller = SettingsScope.of(context);
    final delta = details.primaryDelta! / size.width;
    final next = (controller.value.digitScale + delta).clamp(0.5, 1.2);
    controller.update((current) => current.copyWith(digitScale: next));
  }

  /// Медленный дрейф цифр: за час картинка обходит небольшой эллипс,
  /// и пиксели OLED не выгорают в одном месте.
  Offset _burnInOffset(ClockSettings settings, Size size) {
    if (!settings.burnInProtection) return Offset.zero;
    final minutes = _now.hour * 60 + _now.minute;
    final angle = minutes / 60 * 2 * pi;
    final radiusX = size.width * 0.02;
    final radiusY = size.height * 0.03;
    return Offset(cos(angle) * radiusX, sin(angle * 1.6) * radiusY);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.settingsOf(context);
    final size = MediaQuery.sizeOf(context);
    final ringing = widget.alarms.ringing;

    if (_screenLight) {
      return GestureDetector(
        onTap: () => setState(() => _screenLight = false),
        child: const ColoredBox(color: Colors.white, child: SizedBox.expand()),
      );
    }

    return Scaffold(
      backgroundColor: settings.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onDoubleTap: _cycleSecondsMode,
        onLongPress: settings.flashlightEnabled ? widget.torch.toggle : null,
        onVerticalDragUpdate: (details) => _onVerticalDrag(details, size),
        onHorizontalDragUpdate: (details) => _onHorizontalDrag(details, size),
        child: Stack(
          children: [
            _buildClock(settings, size),
            if (settings.secondsMode == SecondsMode.orbit)
              Positioned.fill(
                child: SecondsOrbit(
                  color: settings.accentColor,
                  style: settings.orbitStyle,
                ),
              ),
            if (settings.timerVisual == TimerVisual.orbit && widget.stopwatch.isActive)
              Positioned.fill(
                child: SecondsOrbit(
                  color: settings.foreground,
                  style: settings.orbitStyle,
                  progressOf: _stopwatchLap,
                ),
              ),
            if (settings.timerVisual == TimerVisual.orbit &&
                (widget.countdown.isActive ||
                    widget.countdown.status == CountdownStatus.finished))
              Positioned.fill(
                child: SecondsOrbit(
                  color: settings.accentColor,
                  style: settings.orbitStyle,
                  progressOf: _countdownLap,
                ),
              ),
            if (settings.notePlacement != NotePlacement.clock)
              Positioned.fill(
                child: IgnorePointer(
                  child: _NoteStack(
                    settings: settings,
                    controlsVisible: _controlsVisible,
                    countdown: widget.countdown,
                    stopwatch: widget.stopwatch,
                  ),
                ),
              ),
            _buildDimmer(settings),
            SafeArea(
              minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildStatusBar(settings),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTimerFinishedBanner(),
                        _buildDock(),
                        const SizedBox(height: 12),
                        // Лист сжимается, когда клавиатура забирает низ экрана.
                        Flexible(child: _buildBottomArea(settings)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (ringing != null)
              Positioned.fill(
                child: RingingOverlay(
                  alarm: ringing,
                  now: _now,
                  onSnooze: widget.alarms.snooze,
                  onDismiss: widget.alarms.dismiss,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Секундомер обходит край за текущую минуту.
  double _stopwatchLap() {
    return (widget.stopwatch.elapsed.inMilliseconds % 60000) / 60000;
  }

  /// Отсчёт проходит край один раз за всё заданное время.
  double _countdownLap() {
    final total = widget.countdown.configured.inMilliseconds;
    if (total <= 0) return 0;
    final left = widget.countdown.remaining.inMilliseconds.clamp(0, total);
    return 1 - left / total;
  }

  Widget _buildClock(ClockSettings settings, Size size) {
    final battery = widget.battery.value;
    final showBar = settings.secondsMode == SecondsMode.bar;
    // Рамка чуть меньше экрана: FittedBox вписывает цифры и в портрет, и в альбом.
    // Сама рамка стоит в центре экрана, дата и полоса секунд её не сдвигают.
    final boxWidth = size.width * 0.92 * settings.digitScale;
    final boxHeight = size.height * 0.62 * settings.digitScale;
    final drift = settings.secondsMode == SecondsMode.orbit
        ? Offset.zero
        : _burnInOffset(settings, size);

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: drift,
          child: SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ClockDisplay(
                  time: _now,
                  settings: settings,
                  battery: battery,
                  colonVisible:
                      settings.secondsMode != SecondsMode.hidden ||
                      _now.millisecond < 500,
                ),
                if (settings.infoPlacement == InfoPlacement.corners)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _CornerInfo(
                      settings: settings,
                      battery: battery,
                      date: _now,
                    ),
                  ),
                if (settings.infoPlacement == InfoPlacement.colon &&
                    settings.showDate)
                  Positioned(
                    bottom: -8,
                    left: 0,
                    right: 0,
                    child: Text(
                      formatClockDate(_now, settings.dateStyle),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryInfoColor(settings),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (showBar)
                  Positioned(
                    bottom: -14,
                    left: boxWidth * 0.18,
                    right: boxWidth * 0.18,
                    child: SecondsBar(time: _now, color: settings.accentColor),
                  ),
                if (settings.notePlacement == NotePlacement.clock)
                  Positioned(
                    left: _digitBounds(settings, boxWidth, boxHeight).right + 14,
                    width: _noteRoom(size, boxWidth, boxHeight, settings),
                    top: _digitBounds(settings, boxWidth, boxHeight).center.dy,
                    child: IgnorePointer(
                      child: FractionalTranslation(
                        translation: const Offset(0, -0.5),
                        child: _NoteStack(
                          settings: settings,
                          controlsVisible: _controlsVisible,
                          countdown: widget.countdown,
                          stopwatch: widget.stopwatch,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Rect _digitBounds(ClockSettings settings, double boxWidth, double boxHeight) {
    return ClockDisplay.paintedBounds(_now, settings, Size(boxWidth, boxHeight));
  }

  /// Сколько места справа от цифр остаётся до края экрана.
  double _noteRoom(
    Size screen,
    double boxWidth,
    double boxHeight,
    ClockSettings settings,
  ) {
    final bounds = _digitBounds(settings, boxWidth, boxHeight);
    final screenRight = boxWidth + (screen.width - boxWidth) / 2;
    final room = screenRight - bounds.right - 16;
    if (room < 48) return 48;
    return room;
  }

  /// Программное затемнение поверх системной яркости — ночью экран
  /// можно увести темнее системного минимума.
  Widget _buildDimmer(ClockSettings settings) {
    final alpha = (1 - settings.localBrightness).clamp(0.0, 0.85);
    if (alpha <= 0.01) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(color: Colors.black.withValues(alpha: alpha)),
      ),
    );
  }

  Widget _buildStatusBar(ClockSettings settings) {
    final controller = SettingsScope.of(context);
    return ValueListenableBuilder<BatteryStatus>(
      valueListenable: widget.battery,
      builder: (context, status, child) => ClockStatusBar(
        settings: settings,
        battery: status,
        date: _now,
        controlsVisible: _controlsVisible,
        onToggleBattery: () => controller.update(
          (current) => current.copyWith(showBattery: !current.showBattery),
        ),
        onToggleDate: () => controller.update(
          (current) => current.copyWith(showDate: !current.showDate),
        ),
      ),
    );
  }

  /// Сигнал таймера должен выключаться одним касанием, без захода в панель.
  Widget _buildTimerFinishedBanner() {
    if (widget.countdown.status != CountdownStatus.finished) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: widget.countdown.stop,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_off_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Отсчёт завершён — стоп',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDock() {
    final countdown = widget.countdown;
    final untilAlarm = widget.alarms.timeUntilNext;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: _controlsVisible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: ControlDock(
          selected: _panel,
          onSelect: _selectPanel,
          timerBadge: countdown.isActive
              ? formatTimerDigits(countdown.remaining)
              : widget.stopwatch.isActive
              ? formatTimerDigits(widget.stopwatch.elapsed)
              : null,
          alarmBadge: untilAlarm != null && untilAlarm.inHours < 12
              ? formatCountdownWords(untilAlarm)
              : null,
        ),
      ),
    );
  }

  Widget _buildBottomArea(ClockSettings settings) {
    if (!_controlsVisible) return const SizedBox(height: 60);

    final panel = _panel;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: panel == null
          ? QuickBar(
              torchOn: widget.torch.value,
              screenLightOn: _screenLight,
              brightness: settings.localBrightness,
              showFlashlight: settings.flashlightEnabled,
              onTorch: () async {
                await widget.torch.toggle();
                if (mounted) setState(() {});
                _restartHideTimer();
              },
              onScreenLight: () => setState(() => _screenLight = true),
              onBrightness: (value) {
                SettingsScope.of(
                  context,
                ).update((current) => current.copyWith(localBrightness: value));
                widget.brightnessService.apply(value);
                _restartHideTimer();
              },
            )
          : _buildPanel(panel),
    );
  }

  Widget _buildPanel(DockPanel panel) {
    void close() {
      setState(() => _panel = null);
      _restartHideTimer();
    }

    return switch (panel) {
      DockPanel.timer => ListenableBuilder(
        listenable: Listenable.merge([widget.countdown, widget.stopwatch]),
        builder: (context, child) => TimerPanel(
          countdown: widget.countdown,
          stopwatch: widget.stopwatch,
          onClose: close,
        ),
      ),
      DockPanel.settings => SettingsPanel(onClose: close),
      DockPanel.alarm => ListenableBuilder(
        listenable: widget.alarms,
        builder: (context, child) =>
            AlarmPanel(controller: widget.alarms, onClose: close),
      ),
      DockPanel.info => InfoPanel(now: _now, onClose: close),
    };
  }
}

/// Надпись и таймеры в одну строку: секундомер и отсчёт справа от надписи.
class _NoteStack extends StatelessWidget {
  const _NoteStack({
    required this.settings,
    required this.controlsVisible,
    required this.countdown,
    required this.stopwatch,
  });

  final ClockSettings settings;
  final bool controlsVisible;
  final CountdownController countdown;
  final StopwatchController stopwatch;

  @override
  Widget build(BuildContext context) {
    final atTop = settings.notePlacement == NotePlacement.top;
    final onClock = settings.notePlacement == NotePlacement.clock;
    final note = settings.customNote.trim();
    final showTimers =
        countdown.isActive ||
        countdown.status == CountdownStatus.finished ||
        stopwatch.isActive;
    final noteLabel = note.isEmpty ? null : _noteLabel(settings);
    final timers = RunningTimers(
      countdown: countdown,
      stopwatch: stopwatch,
      color: settings.foreground,
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (noteLabel != null) _noteChip(settings, noteLabel),
        if (noteLabel != null && showTimers) const SizedBox(width: 12),
        timers,
      ],
    );

    if (onClock) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: row,
      );
    }

    return SafeArea(
      child: Align(
        alignment: atTop ? Alignment.topCenter : Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: 28,
            right: 28,
            top: atTop ? 48 : 12,
            bottom: atTop ? 12 : (controlsVisible ? 168 : 28),
          ),
          child: row,
        ),
      ),
    );
  }

  Widget _noteChip(ClockSettings settings, Widget label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: settings.nightTheme
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: label,
      ),
    );
  }

  Widget _noteLabel(ClockSettings settings) {
    final style = withClockFont(
      settings.noteFont,
      TextStyle(
        color: settings.foreground,
        fontSize: settings.noteSize,
        fontWeight: settings.noteFontWeight,
        height: 1.15,
      ),
    );
    final text = settings.customNote.trim();
    if (settings.noteFont == ClockFont.glass) {
      return GlassText(
        text: text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: style,
      );
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// Заряд в левом верхнем углу циферблата, дата — в правом.
class _CornerInfo extends StatelessWidget {
  const _CornerInfo({
    required this.settings,
    required this.battery,
    required this.date,
  });

  final ClockSettings settings;
  final BatteryStatus battery;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: secondaryInfoColor(settings),
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.showBattery) ...[
            ChargeRing(
              status: battery,
              color: chargeAccentColor(settings, battery),
              size: 22,
            ),
            const SizedBox(width: 6),
            Text('${battery.level}%', style: style),
          ],
          const Spacer(),
          if (settings.showDate)
            Text(formatClockDate(date, settings.dateStyle), style: style),
        ],
      ),
    );
  }
}
