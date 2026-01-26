import 'dart:math' as math;

import 'package:dv_shape/dv_shape.dart';
import 'package:flutter/material.dart';

import 'chart_data.dart';

/// A simple pie/donut chart widget.
class SimplePieChart extends StatelessWidget {
  const SimplePieChart({
    super.key,
    required this.data,
    this.colors,
    this.innerRadiusRatio = 0.0,
    this.startAngle = -math.pi / 2,
    this.showLabels = true,
    this.labelStyle,
    this.padding = const EdgeInsets.all(24),
  });

  /// Data points to display.
  final List<CategoryDataPoint> data;

  /// Colors for slices. Uses default palette if not provided.
  final List<Color>? colors;

  /// Inner radius as ratio of outer radius (0.0 for pie, 0.5+ for donut).
  final double innerRadiusRatio;

  /// Start angle in radians. Default starts at top (-π/2).
  final double startAngle;

  /// Whether to show slice labels.
  final bool showLabels;

  /// Text style for labels.
  final TextStyle? labelStyle;

  /// Padding around the chart.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ?? defaultChartColors;

    return CustomPaint(
      painter: _PieChartPainter(
        data: data,
        colors: effectiveColors,
        innerRadiusRatio: innerRadiusRatio,
        startAngle: startAngle,
        showLabels: showLabels,
        labelStyle:
            labelStyle ??
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
        padding: padding,
      ),
      size: Size.infinite,
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.data,
    required this.colors,
    required this.innerRadiusRatio,
    required this.startAngle,
    required this.showLabels,
    required this.labelStyle,
    required this.padding,
  });

  final List<CategoryDataPoint> data;
  final List<Color> colors;
  final double innerRadiusRatio;
  final double startAngle;
  final bool showLabels;
  final TextStyle labelStyle;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartArea = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );

    final center = chartArea.center;
    final radius = math.min(chartArea.width, chartArea.height) / 2;
    final innerRadius = radius * innerRadiusRatio;

    // Create pie layout
    final pie = PieLayout<CategoryDataPoint>(
      value: (d) => d.value,
      startAngle: startAngle,
      endAngle: startAngle + 2 * math.pi,
    );

    final arcs = pie.generate(data);

    for (int i = 0; i < arcs.length; i++) {
      final arc = arcs[i];
      final color = data[i].color ?? colors[i % colors.length];

      // Draw arc using Path
      final path = _createArcPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: radius,
        startAngle: arc.startAngle,
        endAngle: arc.endAngle,
      );

      canvas.drawPath(path, Paint()..color = color);

      // Draw label
      if (showLabels && arc.endAngle - arc.startAngle > 0.3) {
        final midAngle = (arc.startAngle + arc.endAngle) / 2;
        final labelRadius = (innerRadius + radius) / 2;
        final labelX = center.dx + math.cos(midAngle) * labelRadius;
        final labelY = center.dy + math.sin(midAngle) * labelRadius;

        // Calculate percentage
        final total = data.fold(0.0, (sum, d) => sum + d.value);
        final percentage = (data[i].value / total * 100).round();

        final textPainter = TextPainter(
          text: TextSpan(text: '$percentage%', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            labelX - textPainter.width / 2,
            labelY - textPainter.height / 2,
          ),
        );
      }
    }
  }

  Path _createArcPath({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double endAngle,
  }) {
    final path = Path();

    if (innerRadius <= 0) {
      // Pie slice
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + outerRadius * math.cos(startAngle),
        center.dy + outerRadius * math.sin(startAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        endAngle - startAngle,
        false,
      );
      path.close();
    } else {
      // Donut slice
      path.moveTo(
        center.dx + outerRadius * math.cos(startAngle),
        center.dy + outerRadius * math.sin(startAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        endAngle - startAngle,
        false,
      );
      path.lineTo(
        center.dx + innerRadius * math.cos(endAngle),
        center.dy + innerRadius * math.sin(endAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        endAngle,
        -(endAngle - startAngle),
        false,
      );
      path.close();
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        colors != oldDelegate.colors ||
        innerRadiusRatio != oldDelegate.innerRadiusRatio ||
        startAngle != oldDelegate.startAngle;
  }
}
