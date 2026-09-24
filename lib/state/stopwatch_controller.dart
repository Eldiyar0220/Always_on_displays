import 'package:flutter/foundation.dart';

enum StopwatchStatus { idle, running, paused }

/// Секундомер считает вперёд по системным часам, чтобы пауза не сдвигала время.
class StopwatchController extends ChangeNotifier {
  Duration _accumulated = Duration.zero;
  DateTime? _runningSince;
  StopwatchStatus _status = StopwatchStatus.idle;

  StopwatchStatus get status => _status;
  bool get isActive =>
      _status == StopwatchStatus.running || _status == StopwatchStatus.paused;

  Duration get elapsed {
    final since = _runningSince;
    if (_status == StopwatchStatus.running && since != null) {
      return _accumulated + DateTime.now().difference(since);
    }
    return _accumulated;
  }

  void start() {
    if (_status == StopwatchStatus.running) return;
    _runningSince = DateTime.now();
    _status = StopwatchStatus.running;
    notifyListeners();
  }

  void pause() {
    if (_status != StopwatchStatus.running) return;
    _accumulated = elapsed;
    _runningSince = null;
    _status = StopwatchStatus.paused;
    notifyListeners();
  }

  void reset() {
    _accumulated = Duration.zero;
    _runningSince = null;
    _status = StopwatchStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _runningSince = null;
    super.dispose();
  }
}
