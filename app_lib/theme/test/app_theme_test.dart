import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds one to input values', () {
    final lightTheme = ThemeMode.light.toString();
    expect(lightTheme, 'Light');
  });
}
