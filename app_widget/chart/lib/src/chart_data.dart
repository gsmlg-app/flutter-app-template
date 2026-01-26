import 'package:flutter/material.dart';

/// Data point for line and scatter charts.
class ChartDataPoint {
  const ChartDataPoint(this.x, this.y, {this.label});

  final double x;
  final double y;
  final String? label;
}

/// Data point for categorical charts (bar, pie).
class CategoryDataPoint {
  const CategoryDataPoint({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;
}

/// Default color palette for charts.
const List<Color> defaultChartColors = [
  Color(0xFF2196F3), // Blue
  Color(0xFFF44336), // Red
  Color(0xFF4CAF50), // Green
  Color(0xFFFF9800), // Orange
  Color(0xFF9C27B0), // Purple
  Color(0xFF00BCD4), // Cyan
  Color(0xFFFFEB3B), // Yellow
  Color(0xFF795548), // Brown
];
