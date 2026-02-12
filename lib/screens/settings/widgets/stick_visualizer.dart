import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular analog stick visualizer with deadzone ring and position dot.
class StickVisualizer extends StatelessWidget {
  const StickVisualizer({
    super.key,
    required this.x,
    required this.y,
    required this.label,
    this.isPressed = false,
    this.deadzone = 0.2,
  });

  final double x;
  final double y;
  final String label;
  final bool isPressed;
  final double deadzone;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
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
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _StickPainter(
                x: x,
                y: y,
                isPressed: isPressed,
                deadzone: deadzone,
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
          if (isPressed)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CLICK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StickPainter extends CustomPainter {
  _StickPainter({
    required this.x,
    required this.y,
    required this.isPressed,
    required this.deadzone,
    required this.colorScheme,
  });

  final double x;
  final double y;
  final bool isPressed;
  final double deadzone;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = colorScheme.surfaceContainerHighest,
    );

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isPressed ? colorScheme.primary : colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Deadzone ring
    if (deadzone > 0) {
      canvas.drawCircle(
        center,
        radius * deadzone,
        Paint()
          ..color = colorScheme.outlineVariant.withAlpha(100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Crosshair
    final crossPaint = Paint()
      ..color = colorScheme.outlineVariant.withAlpha(60)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crossPaint,
    );

    // Position dot
    final dotX = center.dx + x * (radius - 6);
    final dotY = center.dy - y * (radius - 6);
    final magnitude = math.sqrt(x * x + y * y);
    final isActive = magnitude > 0.05;

    canvas.drawCircle(
      Offset(dotX, dotY),
      6,
      Paint()..color = isActive ? colorScheme.primary : colorScheme.outline,
    );

    // Line from center to dot when active
    if (isActive) {
      canvas.drawLine(
        center,
        Offset(dotX, dotY),
        Paint()
          ..color = colorScheme.primary.withAlpha(80)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_StickPainter oldDelegate) =>
      x != oldDelegate.x ||
      y != oldDelegate.y ||
      isPressed != oldDelegate.isPressed ||
      deadzone != oldDelegate.deadzone;
}
