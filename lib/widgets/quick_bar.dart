import 'dart:ui';

import 'package:flutter/material.dart';

/// Нижняя полоса: фонарик, «световой экран» и яркость.
class QuickBar extends StatelessWidget {
  const QuickBar({
    super.key,
    required this.torchOn,
    required this.screenLightOn,
    required this.brightness,
    required this.onTorch,
    required this.onScreenLight,
    required this.onBrightness,
    this.showFlashlight = true,
  });

  final bool torchOn;
  final bool screenLightOn;
  final double brightness;
  final VoidCallback onTorch;
  final VoidCallback onScreenLight;
  final ValueChanged<double> onBrightness;
  final bool showFlashlight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              if (showFlashlight) ...[
                _RoundButton(
                  icon: Icons.flashlight_on_outlined,
                  active: torchOn,
                  onTap: onTorch,
                ),
                const SizedBox(width: 8),
                _RoundButton(
                  icon: Icons.highlight_outlined,
                  active: screenLightOn,
                  onTap: onScreenLight,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 10,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: brightness.clamp(0.05, 1.0),
                    min: 0.05,
                    onChanged: onBrightness,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 21, color: active ? Colors.black : Colors.white),
      ),
    );
  }
}
