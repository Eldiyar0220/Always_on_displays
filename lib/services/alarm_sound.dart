import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Проигрывает сигнал будильника и таймера. Звук синтезируется в памяти,
/// поэтому приложению не нужны аудиофайлы в ассетах.
class AlarmSound {
  static const _sampleRate = 44100;

  final _player = AudioPlayer();
  Uint8List? _cachedPattern;
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> start() async {
    if (_playing) return;
    _playing = true;
    final pattern = _cachedPattern ??= _buildPattern();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(BytesSource(pattern, mimeType: 'audio/wav'));
  }

  Future<void> stop() async {
    if (!_playing) return;
    _playing = false;
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }

  /// Два коротких гудка и пауза — цикл длиной около секунды.
  Uint8List _buildPattern() {
    final samples = <double>[];
    for (var i = 0; i < 2; i++) {
      samples.addAll(_tone(frequency: 880, seconds: 0.16));
      samples.addAll(_silence(0.12));
    }
    samples.addAll(_silence(0.6));
    return _encodeWav(samples);
  }

  Iterable<double> _tone({required double frequency, required double seconds}) sync* {
    final total = (seconds * _sampleRate).round();
    // Плавные атака и затухание убирают щелчки на стыках цикла.
    final ramp = (total * 0.15).round();
    for (var i = 0; i < total; i++) {
      final envelope = i < ramp
          ? i / ramp
          : (i > total - ramp ? (total - i) / ramp : 1.0);
      yield sin(2 * pi * frequency * i / _sampleRate) * envelope * 0.7;
    }
  }

  Iterable<double> _silence(double seconds) sync* {
    for (var i = 0; i < (seconds * _sampleRate).round(); i++) {
      yield 0;
    }
  }

  Uint8List _encodeWav(List<double> samples) {
    const bitsPerSample = 16;
    const channels = 1;
    final dataSize = samples.length * 2;
    final bytes = ByteData(44 + dataSize);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, channels, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
    bytes.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final clamped = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      bytes.setInt16(44 + i * 2, clamped, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}
