import 'dart:math' as math;

import 'package:dv_scale/dv_scale.dart';
import 'package:flutter/material.dart';

import 'chart_data.dart';

/// A simple bar chart widget.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.data,
    this.colors,
    this.barPadding = 0.2,
    this.borderRadius = 4.0,
    this.horizontal = false,
    this.showLabels = true,
    this.labelStyle,
    this.padding = const EdgeInsets.all(24),
  });

  /// Data points to display.
  final List<CategoryDataPoint> data;

  /// Colors for bars. Uses default palette if not provided.
  final List<Color>? colors;

  /// Padding between bars (0.0 to 1.0).
  final double barPadding;

  /// Corner radius for bars.
  final double borderRadius;

  /// Whether to render bars horizontally.
  final bool horizontal;

  /// Whether to show category labels.
  final bool showLabels;

  /// Text style for labels.
  final TextStyle? labelStyle;

  /// Padding around the chart.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ?? defaultChartColors;

    return CustomPaint(
      painter: _BarChartPainter(
        data: data,
        colors: effectiveColors,
        barPadding: barPadding,
        borderRadius: borderRadius,
        horizontal: horizontal,
        showLabels: showLabels,
        labelStyle:
            labelStyle ??
            Theme.of(context).textTheme.bodySmall ??
            const TextStyle(fontSize: 12),
        padding: padding,
      ),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.data,
    required this.colors,
    required this.barPadding,
    required this.borderRadius,
    required this.horizontal,
    required this.showLabels,
    required this.labelStyle,
    required this.padding,
  });

  final List<CategoryDataPoint> data;
  final List<Color> colors;
  final double barPadding;
  final double borderRadius;
  final bool horizontal;
  final bool showLabels;
  final TextStyle labelStyle;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final labelHeight = showLabels ? 20.0 : 0.0;

    final chartArea = horizontal
        ? Rect.fromLTWH(
            padding.left + labelHeight,
            padding.top,
            size.width - padding.horizontal - labelHeight,
            size.height - padding.vertical,
          )
        : Rect.fromLTWH(
            padding.left,
            padding.top,
            size.width - padding.horizontal,
            size.height - padding.vertical - labelHeight,
          );

    final labels = data.map((d) => d.label).toList();
    final values = data.map((d) => d.value).toList();
    final maxValue = values.reduce(math.max);

    if (horizontal) {
      _paintHorizontal(
        canvas,
        chartArea,
        labels,
        values,
        maxValue,
        labelHeight,
      );
    } else {
      _paintVertical(canvas, chartArea, labels, values, maxValue, labelHeight);
    }
  }

  void _paintVertical(
    Canvas canvas,
    Rect chartArea,
    List<String> labels,
    List<double> values,
    double maxValue,
    double labelHeight,
  ) {
    final xScale = scaleBand(
      domain: labels,
      range: [chartArea.left, chartArea.right],
      padding: barPadding,
    );
    final yScale = scaleLinear(
      domain: [0, maxValue],
      range: [chartArea.bottom, chartArea.top],
    );

    for (int i = 0; i < data.length; i++) {
      final x = xScale(labels[i]);
      final y = yScale(values[i]);
      final barHeight = chartArea.bottom - y;
      final color = data[i].color ?? colors[i % colors.length];

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, xScale.bandwidth, barHeight),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      );

      canvas.drawRRect(rect, Paint()..color = color);

      // Draw label
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(text: labels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: xScale.bandwidth);

        textPainter.paint(
          canvas,
          Offset(
            x + (xScale.bandwidth - textPainter.width) / 2,
            chartArea.bottom + 4,
          ),
        );
      }
    }
  }

  void _paintHorizontal(
    Canvas canvas,
    Rect chartArea,
    List<String> labels,
    List<double> values,
    double maxValue,
    double labelHeight,
  ) {
    final yScale = scaleBand(
      domain: labels,
      range: [chartArea.top, chartArea.bottom],
      padding: barPadding,
    );
    final xScale = scaleLinear(
      domain: [0, maxValue],
      range: [chartArea.left, chartArea.right],
    );

    for (int i = 0; i < data.length; i++) {
      final y = yScale(labels[i]);
      final barWidth = xScale(values[i]) - chartArea.left;
      final color = data[i].color ?? colors[i % colors.length];

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(chartArea.left, y, barWidth, yScale.bandwidth),
        topRight: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      );

      canvas.drawRRect(rect, Paint()..color = color);

      // Draw label
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(text: labels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            chartArea.left - textPainter.width - 4,
            y + (yScale.bandwidth - textPainter.height) / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        colors != oldDelegate.colors ||
        barPadding != oldDelegate.barPadding ||
        horizontal != oldDelegate.horizontal;
  }
}
