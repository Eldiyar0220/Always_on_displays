import 'package:flutter/material.dart';

/// Чем открывается панель под доком.
enum DockPanel { timer, settings, alarm, info }

/// Ряд круглых кнопок по центру экрана — вызывается касанием по часам.
class ControlDock extends StatelessWidget {
  const ControlDock({
    super.key,
    required this.selected,
    required this.onSelect,
    this.timerBadge,
    this.alarmBadge,
  });

  final DockPanel? selected;
  final ValueChanged<DockPanel> onSelect;

  /// Оставшееся время таймера прямо на кнопке, как в оригинале.
  final String? timerBadge;
  final String? alarmBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DockButton(
          panel: DockPanel.timer,
          selected: selected == DockPanel.timer,
          onSelect: onSelect,
          icon: Icons.timer_outlined,
          badge: timerBadge,
        ),
        _DockButton(
          panel: DockPanel.settings,
          selected: selected == DockPanel.settings,
          onSelect: onSelect,
          icon: Icons.dashboard_customize_outlined,
        ),
        _DockButton(
          panel: DockPanel.alarm,
          selected: selected == DockPanel.alarm,
          onSelect: onSelect,
          icon: Icons.alarm,
          badge: alarmBadge,
        ),
        _DockButton(
          panel: DockPanel.info,
          selected: selected == DockPanel.info,
          onSelect: onSelect,
          icon: Icons.info_outline,
        ),
      ],
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.panel,
    required this.selected,
    required this.onSelect,
    required this.icon,
    this.badge,
  });

  final DockPanel panel;
  final bool selected;
  final ValueChanged<DockPanel> onSelect;
  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final background = selected ? Colors.white : Colors.white.withValues(alpha: 0.16);
    final foreground = selected ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => onSelect(panel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: badge == null ? 12 : 10),
          constraints: const BoxConstraints(minWidth: 44),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: badge == null
                ? Icon(icon, size: 22, color: foreground)
                : Text(
                    badge!,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
