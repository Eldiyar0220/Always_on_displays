import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/clock_screen.dart';
import 'services/alarm_sound.dart';
import 'services/device_services.dart';
import 'state/alarm_controller.dart';
import 'state/countdown_controller.dart';
import 'state/settings_controller.dart';
import 'state/stopwatch_controller.dart';
import 'widgets/clock_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final sound = AlarmSound();
  final settings = await SettingsController.load();
  final alarms = await AlarmController.load(sound);

  runApp(
    ClockApp(
      settings: settings,
      alarms: alarms,
      countdown: CountdownController(sound),
      stopwatch: StopwatchController(),
    ),
  );
  preloadClockFonts();
}

class ClockApp extends StatefulWidget {
  const ClockApp({
    super.key,
    required this.settings,
    required this.alarms,
    required this.countdown,
    required this.stopwatch,
  });

  final SettingsController settings;
  final AlarmController alarms;
  final CountdownController countdown;
  final StopwatchController stopwatch;

  @override
  State<ClockApp> createState() => _ClockAppState();
}

class _ClockAppState extends State<ClockApp> {
  final _battery = BatteryMonitor();
  final _torch = TorchService();
  final _brightness = BrightnessService();

  @override
  void initState() {
    super.initState();
    _brightness.apply(widget.settings.value.localBrightness);
  }

  @override
  void dispose() {
    _battery.dispose();
    _torch.dispose();
    widget.countdown.dispose();
    widget.stopwatch.dispose();
    widget.alarms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: widget.settings,
      child: MaterialApp(
        title: 'Часы на экран',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A84FF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFF0A84FF),
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
          ),
        ),
        home: ClockScreen(
          battery: _battery,
          torch: _torch,
          brightnessService: _brightness,
          countdown: widget.countdown,
          stopwatch: widget.stopwatch,
          alarms: widget.alarms,
        ),
      ),
    );
  }
}
