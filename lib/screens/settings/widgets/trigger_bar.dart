import 'package:flutter/material.dart';

/// Horizontal fill bar showing trigger analog value (0–100%).
class TriggerBar extends StatelessWidget {
  const TriggerBar({
    super.key,
    required this.value,
    required this.label,
  });

  /// 0.0 – 1.0
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = value > 0.05;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 120,
          height: 16,
          child: Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isActive ? colorScheme.primary : colorScheme.outline,
                  ),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(value.clamp(0, 1) * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
