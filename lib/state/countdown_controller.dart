import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/alarm_sound.dart';

enum CountdownStatus { idle, running, paused, finished }

/// Таймер обратного отсчёта. Время считается по системным часам, поэтому
/// секунды не «уплывают», если тики задерживаются.
class CountdownController extends ChangeNotifier {
  CountdownController(this._sound);

  final AlarmSound _sound;
  Timer? _ticker;
  DateTime? _deadline;

  Duration _configured = const Duration(minutes: 5);
  Duration _remaining = const Duration(minutes: 5);
  CountdownStatus _status = CountdownStatus.idle;

  Duration get configured => _configured;
  Duration get remaining => _remaining;
  CountdownStatus get status => _status;
  bool get isActive => _status == CountdownStatus.running || _status == CountdownStatus.paused;

  void configure(Duration duration) {
    _configured = duration.isNegative ? Duration.zero : duration;
    if (!isActive) {
      _remaining = _configured;
      notifyListeners();
    }
  }

  void start([Duration? duration]) {
    if (duration != null) _configured = duration;
    if (_configured == Duration.zero) return;
    _remaining = _configured;
    _deadline = DateTime.now().add(_remaining);
    _status = CountdownStatus.running;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_status != CountdownStatus.running) return;
    _ticker?.cancel();
    _status = CountdownStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != CountdownStatus.paused) return;
    _deadline = DateTime.now().add(_remaining);
    _status = CountdownStatus.running;
    _startTicker();
    notifyListeners();
  }

  void stop() {
    _ticker?.cancel();
    _sound.stop();
    _status = CountdownStatus.idle;
    _remaining = _configured;
    _deadline = null;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    final deadline = _deadline;
    if (deadline == null) return;
    final left = deadline.difference(DateTime.now());
    if (left <= Duration.zero) {
      _ticker?.cancel();
      _remaining = Duration.zero;
      _status = CountdownStatus.finished;
      _sound.start();
      notifyListeners();
      return;
    }
    final seconds = left.inSeconds;
    if (seconds != _remaining.inSeconds) {
      _remaining = Duration(seconds: seconds + 1);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
