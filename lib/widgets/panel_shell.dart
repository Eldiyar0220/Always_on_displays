import 'dart:ui';

import 'package:flutter/material.dart';

/// Матовая подложка для нижних панелей — общий каркас для таймера,
/// будильника, настроек и информации.
class PanelShell extends StatelessWidget {
  const PanelShell({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.footer,
    this.maxHeight = 380,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  /// Кнопки действий: остаются на виду, даже когда содержимое прокручивается.
  final Widget? footer;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    // Панель никогда не занимает больше половины видимой области. Клавиатура
    // вычитается, иначе лист остаётся высоким и вылезает за край.
    final media = MediaQuery.of(context);
    final visibleHeight = media.size.height - media.viewInsets.bottom;
    final limit = maxHeight.clamp(0.0, visibleHeight * 0.52);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: limit),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (onClose != null)
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(
                        Icons.close,
                        size: 22,
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: child)),
              if (footer != null) ...[
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Строка «подпись — управление», из которых собраны панели настроек.
class PanelRow extends StatelessWidget {
  const PanelRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Переключатель из нескольких вариантов в стиле сегментированного контрола.
class SegmentedChips<T> extends StatelessWidget {
  const SegmentedChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: value == selected ? 0.22 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: value == selected
                      ? const Color(0xFF0A84FF)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                labelOf(value),
                style: TextStyle(
                  color: value == selected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
