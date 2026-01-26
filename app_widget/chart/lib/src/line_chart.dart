import 'dart:math' as math;

import 'package:dv_curve/dv_curve.dart';
import 'package:dv_point/dv_point.dart';
import 'package:dv_scale/dv_scale.dart';
import 'package:flutter/material.dart';

import 'chart_data.dart';

/// A simple line chart widget.
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.data,
    this.lineColor,
    this.strokeWidth = 2.0,
    this.showPoints = true,
    this.pointRadius = 4.0,
    this.fillArea = false,
    this.fillColor,
    this.smooth = true,
    this.padding = const EdgeInsets.all(24),
  });

  /// Data points to display.
  final List<ChartDataPoint> data;

  /// Color of the line. Defaults to theme primary color.
  final Color? lineColor;

  /// Width of the line stroke.
  final double strokeWidth;

  /// Whether to show data points as circles.
  final bool showPoints;

  /// Radius of data point circles.
  final double pointRadius;

  /// Whether to fill the area under the line.
  final bool fillArea;

  /// Color for area fill. Defaults to line color with opacity.
  final Color? fillColor;

  /// Whether to use smooth curve interpolation.
  final bool smooth;

  /// Padding around the chart.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final color = lineColor ?? Theme.of(context).colorScheme.primary;

    return CustomPaint(
      painter: _LineChartPainter(
        data: data,
        lineColor: color,
        strokeWidth: strokeWidth,
        showPoints: showPoints,
        pointRadius: pointRadius,
        fillArea: fillArea,
        fillColor: fillColor ?? color.withValues(alpha: 0.2),
        smooth: smooth,
        padding: padding,
      ),
      size: Size.infinite,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.strokeWidth,
    required this.showPoints,
    required this.pointRadius,
    required this.fillArea,
    required this.fillColor,
    required this.smooth,
    required this.padding,
  });

  final List<ChartDataPoint> data;
  final Color lineColor;
  final double strokeWidth;
  final bool showPoints;
  final double pointRadius;
  final bool fillArea;
  final Color fillColor;
  final bool smooth;
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

    // Calculate domain from data
    final xValues = data.map((d) => d.x).toList();
    final yValues = data.map((d) => d.y).toList();
    final xMin = xValues.reduce(math.min);
    final xMax = xValues.reduce(math.max);
    final yMin = math.min(0.0, yValues.reduce(math.min));
    final yMax = yValues.reduce(math.max);

    // Create scales
    final xScale = scaleLinear(
      domain: [xMin, xMax],
      range: [chartArea.left, chartArea.right],
    );
    final yScale = scaleLinear(
      domain: [yMin, yMax],
      range: [chartArea.bottom, chartArea.top],
    );

    // Map data to screen points
    final points = data.map((d) => Point(xScale(d.x), yScale(d.y))).toList();

    // Apply curve if smooth
    final curvePoints = smooth ? curveCatmullRom().generate(points) : points;

    if (curvePoints.isEmpty) return;

    // Build path
    final path = Path()..moveTo(curvePoints.first.x, curvePoints.first.y);
    for (final p in curvePoints.skip(1)) {
      path.lineTo(p.x, p.y);
    }

    // Draw area fill
    if (fillArea) {
      final fillPath = Path.from(path)
        ..lineTo(curvePoints.last.x, chartArea.bottom)
        ..lineTo(curvePoints.first.x, chartArea.bottom)
        ..close();

      canvas.drawPath(fillPath, Paint()..color = fillColor);
    }

    // Draw line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw points
    if (showPoints) {
      final pointPaint = Paint()..color = lineColor;
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (final point in points) {
        canvas.drawCircle(Offset(point.x, point.y), pointRadius, pointPaint);
        canvas.drawCircle(Offset(point.x, point.y), pointRadius, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        lineColor != oldDelegate.lineColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        showPoints != oldDelegate.showPoints ||
        fillArea != oldDelegate.fillArea;
  }
}
