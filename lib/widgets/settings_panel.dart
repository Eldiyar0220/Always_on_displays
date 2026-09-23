import 'package:flutter/material.dart';

import '../models/clock_settings.dart';
import '../state/settings_controller.dart';
import 'panel_shell.dart';

/// Панель внешнего вида: цвет, толщина и размер цифр, анимация, формат времени.
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, this.onClose});

  static const _palette = [
    Colors.white,
    Color(0xFFB9B9C2),
    Color(0xFFFF3B30),
    Color(0xFFFF9F0A),
    Color(0xFFFFD60A),
    Color(0xFF30D158),
    Color(0xFF64D2FF),
    Color(0xFF0A84FF),
    Color(0xFFBF5AF2),
    Color(0xFFFF6482),
  ];

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.of(context);
    final settings = controller.value;

    return PanelShell(
      title: 'Внешний вид',
      onClose: onClose,
      maxHeight: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Где показывать заряд и дату',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          _PlacementPicker(
            selected: settings.infoPlacement,
            onChanged: (value) => controller.update(
              (current) => current.copyWith(infoPlacement: value),
            ),
          ),
          const SizedBox(height: 8),
          PanelRow(
            label: 'Толщина',
            child: Slider(
              value: settings.digitWeight.toDouble(),
              min: 1,
              max: 9,
              divisions: 8,
              label: '${settings.digitWeight}',
              onChanged: (value) => controller.update(
                (current) => current.copyWith(digitWeight: value.round()),
              ),
            ),
          ),
          PanelRow(
            label: 'Размер',
            child: Slider(
              value: settings.digitScale,
              min: 0.5,
              max: 1.2,
              onChanged: (value) => controller.update(
                (current) => current.copyWith(digitScale: value),
              ),
            ),
          ),
          PanelRow(
            label: 'Цвет цифр',
            child: _DigitColorPicker(settings: settings, controller: controller),
          ),
          PanelRow(
            label: 'Цвет секунд',
            child: _ColorRow(
              selected: settings.accentColor,
              onSelected: (color) => controller.update(
                (current) => current.copyWith(accentColor: color),
              ),
            ),
          ),
          PanelRow(
            label: 'Анимация',
            child: SegmentedChips<DigitAnimation>(
              values: DigitAnimation.values,
              selected: settings.animation,
              labelOf: (value) => value.label,
              onChanged: (value) => controller.update(
                (current) => current.copyWith(animation: value),
              ),
            ),
          ),
          PanelRow(
            label: 'Секунды',
            child: SegmentedChips<SecondsMode>(
              values: SecondsMode.values,
              selected: settings.secondsMode,
              labelOf: (value) => value.label,
              onChanged: (value) => controller.update(
                (current) => current.copyWith(secondsMode: value),
              ),
            ),
          ),
          PanelRow(
            label: 'Формат',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Toggle(
                  label: '24',
                  active: settings.use24HourFormat,
                  onTap: () => controller.update(
                    (current) => current.copyWith(use24HourFormat: true),
                  ),
                ),
                _Toggle(
                  label: 'AM/PM',
                  active: !settings.use24HourFormat,
                  onTap: () => controller.update(
                    (current) => current.copyWith(use24HourFormat: false),
                  ),
                ),
                _Toggle(
                  label: '1:27',
                  active: !settings.showLeadingZero,
                  onTap: () => controller.update(
                    (current) => current.copyWith(showLeadingZero: false),
                  ),
                ),
                _Toggle(
                  label: '01:27',
                  active: settings.showLeadingZero,
                  onTap: () => controller.update(
                    (current) => current.copyWith(showLeadingZero: true),
                  ),
                ),
              ],
            ),
          ),
          PanelRow(
            label: 'Тема',
            child: Wrap(
              spacing: 8,
              children: [
                _Toggle(
                  icon: Icons.nightlight_round,
                  active: settings.nightTheme,
                  onTap: () => controller.update(
                    (current) => current.copyWith(nightTheme: true),
                  ),
                ),
                _Toggle(
                  icon: Icons.wb_sunny_outlined,
                  active: !settings.nightTheme,
                  onTap: () => controller.update(
                    (current) => current.copyWith(nightTheme: false),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Дополнительная информация',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PanelRow(
            label: 'Формат даты',
            child: SegmentedChips<DateStyle>(
              values: DateStyle.values,
              selected: settings.dateStyle,
              labelOf: (value) => value.sample,
              onChanged: (value) => controller.update(
                (current) => current.copyWith(dateStyle: value),
              ),
            ),
          ),
          Text(
            'Интенсивность ${(settings.infoIntensity * 100).round()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Slider(
            value: settings.infoIntensity,
            min: 0.2,
            max: 1,
            onChanged: (value) => controller.update(
              (current) => current.copyWith(infoIntensity: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Цвет как у цифр',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            value: settings.infoFollowsDigits,
            onChanged: (value) => controller.update(
              (current) => current.copyWith(infoFollowsDigits: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Индикация уровня заряда цветом',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            value: settings.batteryTintByLevel,
            onChanged: (value) => controller.update(
              (current) => current.copyWith(batteryTintByLevel: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Защита от выгорания',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: const Text(
              'Цифры медленно смещаются по экрану',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            value: settings.burnInProtection,
            onChanged: (value) => controller.update(
              (current) => current.copyWith(burnInProtection: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Фонарик по касанию',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            value: settings.flashlightEnabled,
            onChanged: (value) => controller.update(
              (current) => current.copyWith(flashlightEnabled: value),
            ),
          ),
        ],
      ),
    );
  }
}

/// Три схемы расположения — сверху, бейдж в двоеточии, углы циферблата.
class _PlacementPicker extends StatelessWidget {
  const _PlacementPicker({required this.selected, required this.onChanged});

  final InfoPlacement selected;
  final ValueChanged<InfoPlacement> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final placement in InfoPlacement.values) ...[
          if (placement != InfoPlacement.values.first) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(placement),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: placement == selected
                        ? const Color(0xFF0A84FF)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    _PlacementSketch(placement: placement),
                    const SizedBox(height: 6),
                    Text(
                      placement.label,
                      style: TextStyle(
                        color: placement == selected ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlacementSketch extends StatelessWidget {
  const _PlacementSketch({required this.placement});

  final InfoPlacement placement;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 64,
      child: switch (placement) {
        InfoPlacement.bar => const Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Dot(color: Color(0xFF30D158)),
                _Dash(width: 22),
              ],
            ),
            Spacer(),
            _Dash(width: 40, height: 8),
          ],
        ),
        InfoPlacement.colon => const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dash(width: 16, height: 16),
            SizedBox(width: 4),
            _Dot(color: Color(0xFF8E8E93), size: 10),
            SizedBox(width: 4),
            _Dash(width: 16, height: 16),
          ],
        ),
        InfoPlacement.corners => const Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Dot(color: Color(0xFF30D158), size: 7),
                _Dash(width: 18),
              ],
            ),
            Spacer(),
            _Dash(width: 36, height: 10),
            Spacer(),
          ],
        ),
      },
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash({required this.width, this.height = 3});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Палитра, случайный цвет и ручной подбор R/G/B, как в пипетке на скрине.
class _DigitColorPicker extends StatefulWidget {
  const _DigitColorPicker({required this.settings, required this.controller});

  final ClockSettings settings;
  final SettingsController controller;

  @override
  State<_DigitColorPicker> createState() => _DigitColorPickerState();
}

class _DigitColorPickerState extends State<_DigitColorPicker> {
  bool _custom = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final color = settings.digitColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColorRow(
          selected: color,
          randomActive: settings.randomColor,
          onSelected: (value) {
            setState(() => _custom = false);
            widget.controller.update(
              (current) => current.copyWith(digitColor: value, randomColor: false),
            );
          },
          onRandom: () {
            widget.controller.update((current) => current.copyWith(randomColor: true));
            widget.controller.shuffleDigitColor();
          },
          trailing: GestureDetector(
            onTap: () => setState(() => _custom = !_custom),
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: _custom ? const Color(0xFF0A84FF) : Colors.white24,
                  width: _custom ? 2.5 : 1,
                ),
              ),
              child: const Icon(Icons.colorize, size: 16, color: Colors.black54),
            ),
          ),
        ),
        if (_custom) ...[
          const SizedBox(height: 8),
          _ChannelSlider(
            label: 'R',
            value: color.r,
            tint: const Color(0xFFFF3B30),
            onChanged: (value) => _setChannel(red: value),
          ),
          _ChannelSlider(
            label: 'G',
            value: color.g,
            tint: const Color(0xFF30D158),
            onChanged: (value) => _setChannel(green: value),
          ),
          _ChannelSlider(
            label: 'B',
            value: color.b,
            tint: const Color(0xFF0A84FF),
            onChanged: (value) => _setChannel(blue: value),
          ),
        ],
      ],
    );
  }

  void _setChannel({double? red, double? green, double? blue}) {
    final color = widget.settings.digitColor;
    widget.controller.update(
      (current) => current.copyWith(
        randomColor: false,
        digitColor: color.withValues(
          red: red ?? color.r,
          green: green ?? color.g,
          blue: blue ?? color.b,
        ),
      ),
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.tint,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color tint;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(
            '$label ${(value * 255).round()}',
            style: TextStyle(color: tint, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tint,
              thumbColor: Colors.white,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.selected,
    required this.onSelected,
    this.onRandom,
    this.randomActive = false,
    this.trailing,
  });

  final Color selected;
  final ValueChanged<Color> onSelected;
  final VoidCallback? onRandom;
  final bool randomActive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final color in SettingsPanel._palette)
            GestureDetector(
              onTap: () => onSelected(color),
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: color == selected && !randomActive
                        ? const Color(0xFF0A84FF)
                        : Colors.white24,
                    width: color == selected && !randomActive ? 2.5 : 1,
                  ),
                ),
              ),
            ),
          if (onRandom != null)
            GestureDetector(
              onTap: onRandom,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF3B30),
                      Color(0xFFFFD60A),
                      Color(0xFF30D158),
                      Color(0xFF0A84FF),
                      Color(0xFFBF5AF2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: randomActive ? const Color(0xFF0A84FF) : Colors.white24,
                    width: randomActive ? 2.5 : 1,
                  ),
                ),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({this.label, this.icon, required this.active, required this.onTap});

  final String? label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.24 : 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: icon != null
            ? Icon(icon, size: 18, color: active ? Colors.white : Colors.white54)
            : Text(
                label!,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
