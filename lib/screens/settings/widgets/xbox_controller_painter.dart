import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'controller_input_state.dart';

/// CustomPainter that draws a top-down Xbox controller schematic.
///
/// Buttons highlight when present in [inputState.pressedButtons].
/// Triggers are drawn as fill bars above the bumpers.
/// Stick dots are drawn inside the stick wells.
class XboxControllerPainter extends CustomPainter {
  XboxControllerPainter({
    required this.inputState,
    required this.colorScheme,
    this.isPlayStation = false,
    this.dimmed = false,
  });

  final ControllerInputState inputState;
  final ColorScheme colorScheme;
  final bool isPlayStation;
  final bool dimmed;

  // ── Proportional positions (0..1) ──────────────────────────────

  // Face buttons center
  static const _abxyX = 0.72;
  static const _abxyY = 0.30;
  static const _abxySpacing = 0.055;

  // D-pad center
  static const _dpadX = 0.28;
  static const _dpadY = 0.55;
  static const _dpadArm = 0.042;
  static const _dpadWidth = 0.030;

  // Center buttons
  static const _guideX = 0.50;
  static const _guideY = 0.22;
  static const _backX = 0.42;
  static const _startX = 0.58;
  static const _centerBtnY = 0.38;

  // Bumpers
  static const _lbLeft = 0.15;
  static const _lbRight = 0.40;
  static const _rbLeft = 0.60;
  static const _rbRight = 0.85;
  static const _bumperTop = 0.08;
  static const _bumperBottom = 0.14;

  // Triggers (above bumpers)
  static const _triggerTop = 0.01;
  static const _triggerBottom = 0.07;

  // Stick wells
  static const _leftStickX = 0.28;
  static const _leftStickY = 0.30;
  static const _rightStickX = 0.65;
  static const _rightStickY = 0.52;
  static const _stickRadius = 0.085;

  // ── Helpers ────────────────────────────────────────────────────

  Color _btnColor(String buttonId) {
    final active = inputState.isPressed(buttonId);
    if (dimmed) {
      return active
          ? colorScheme.primary.withAlpha(120)
          : colorScheme.surfaceContainerHigh.withAlpha(80);
    }
    return active ? colorScheme.primary : colorScheme.surfaceContainerHigh;
  }

  Color _textColor(String buttonId) {
    return inputState.isPressed(buttonId)
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
  }

  String _label(String id) =>
      isPlayStation ? _psLabel(id) : _xboxLabel(id);

  static String _xboxLabel(String id) {
    switch (id) {
      case ButtonId.a: return 'A';
      case ButtonId.b: return 'B';
      case ButtonId.x: return 'X';
      case ButtonId.y: return 'Y';
      case ButtonId.lb: return 'LB';
      case ButtonId.rb: return 'RB';
      case ButtonId.start: return 'ST';
      case ButtonId.back: return 'BK';
      case ButtonId.guide: return 'X';
      default: return id;
    }
  }

  static String _psLabel(String id) {
    switch (id) {
      case ButtonId.a: return '✕';
      case ButtonId.b: return '○';
      case ButtonId.x: return '□';
      case ButtonId.y: return '△';
      case ButtonId.lb: return 'L1';
      case ButtonId.rb: return 'R1';
      case ButtonId.start: return 'OPT';
      case ButtonId.back: return 'SHR';
      case ButtonId.guide: return 'PS';
      default: return id;
    }
  }

  // ── Paint ──────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawBody(canvas, w, h);
    _drawTriggers(canvas, w, h);
    _drawBumpers(canvas, w, h);
    _drawDpad(canvas, w, h);
    _drawFaceButtons(canvas, w, h);
    _drawCenterButtons(canvas, w, h);
    _drawStickWells(canvas, w, h);
  }

  void _drawBody(Canvas canvas, double w, double h) {
    final path = Path();

    // Start at top-left shoulder area
    path.moveTo(w * 0.15, h * 0.10);

    // Top-left shoulder curve up to center-left
    path.cubicTo(
      w * 0.18, h * 0.04,
      w * 0.28, h * 0.02,
      w * 0.38, h * 0.06,
    );

    // Top center dip
    path.cubicTo(
      w * 0.44, h * 0.08,
      w * 0.56, h * 0.08,
      w * 0.62, h * 0.06,
    );

    // Top-right shoulder curve
    path.cubicTo(
      w * 0.72, h * 0.02,
      w * 0.82, h * 0.04,
      w * 0.85, h * 0.10,
    );

    // Right side curves down
    path.cubicTo(
      w * 0.88, h * 0.18,
      w * 0.88, h * 0.30,
      w * 0.84, h * 0.42,
    );

    // Right side narrows toward right grip
    path.cubicTo(
      w * 0.80, h * 0.52,
      w * 0.78, h * 0.58,
      w * 0.80, h * 0.65,
    );

    // Right grip going down
    path.cubicTo(
      w * 0.82, h * 0.74,
      w * 0.82, h * 0.82,
      w * 0.80, h * 0.90,
    );

    // Right grip tip (rounded bottom)
    path.cubicTo(
      w * 0.79, h * 0.95,
      w * 0.73, h * 0.97,
      w * 0.70, h * 0.93,
    );

    // Right grip inner side going up
    path.cubicTo(
      w * 0.68, h * 0.88,
      w * 0.67, h * 0.80,
      w * 0.66, h * 0.72,
    );

    // Inner curve from right grip to center bottom
    path.cubicTo(
      w * 0.64, h * 0.64,
      w * 0.58, h * 0.60,
      w * 0.50, h * 0.60,
    );

    // Inner curve from center bottom to left grip
    path.cubicTo(
      w * 0.42, h * 0.60,
      w * 0.36, h * 0.64,
      w * 0.34, h * 0.72,
    );

    // Left grip inner side going down
    path.cubicTo(
      w * 0.33, h * 0.80,
      w * 0.32, h * 0.88,
      w * 0.30, h * 0.93,
    );

    // Left grip tip (rounded bottom)
    path.cubicTo(
      w * 0.27, h * 0.97,
      w * 0.21, h * 0.95,
      w * 0.20, h * 0.90,
    );

    // Left grip going up
    path.cubicTo(
      w * 0.18, h * 0.82,
      w * 0.18, h * 0.74,
      w * 0.20, h * 0.65,
    );

    // Left side narrows from grip back up
    path.cubicTo(
      w * 0.22, h * 0.58,
      w * 0.20, h * 0.52,
      w * 0.16, h * 0.42,
    );

    // Left side curves back up to start
    path.cubicTo(
      w * 0.12, h * 0.30,
      w * 0.12, h * 0.18,
      w * 0.15, h * 0.10,
    );

    path.close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = dimmed
            ? colorScheme.surfaceContainerHighest.withAlpha(80)
            : colorScheme.surfaceContainerHighest,
    );
    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = dimmed
            ? colorScheme.outline.withAlpha(80)
            : colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawTriggers(Canvas canvas, double w, double h) {
    // LT
    _drawTriggerBar(
      canvas,
      Rect.fromLTRB(
        w * _lbLeft, h * _triggerTop,
        w * _lbRight, h * _triggerBottom,
      ),
      inputState.leftTrigger,
      isPlayStation ? 'L2' : 'LT',
    );
    // RT
    _drawTriggerBar(
      canvas,
      Rect.fromLTRB(
        w * _rbLeft, h * _triggerTop,
        w * _rbRight, h * _triggerBottom,
      ),
      inputState.rightTrigger,
      isPlayStation ? 'R2' : 'RT',
    );
  }

  void _drawTriggerBar(
    Canvas canvas,
    Rect rect,
    double value,
    String label,
  ) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    final isActive = value > 0.05;

    // Background
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = dimmed
            ? colorScheme.surfaceContainerHigh.withAlpha(60)
            : colorScheme.surfaceContainerHigh,
    );

    // Fill proportional to trigger value
    if (value > 0.01) {
      final fillRect = Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.left + rect.width * value.clamp(0, 1),
        rect.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(4)),
        Paint()
          ..color = dimmed
              ? colorScheme.primary.withAlpha(80)
              : colorScheme.primary,
      );
    }

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isActive
            ? (dimmed ? colorScheme.primary.withAlpha(80) : colorScheme.primary)
            : (dimmed ? colorScheme.outline.withAlpha(60) : colorScheme.outline)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isActive
              ? (dimmed ? colorScheme.onPrimary.withAlpha(80) : colorScheme.onPrimary)
              : (dimmed ? colorScheme.onSurfaceVariant.withAlpha(80) : colorScheme.onSurfaceVariant),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.center.dy - tp.height / 2,
      ),
    );
  }

  void _drawStickWells(Canvas canvas, double w, double h) {
    // Left stick well
    final leftCenter = Offset(w * _leftStickX, h * _leftStickY);
    final r = w * _stickRadius;
    _drawWell(canvas, leftCenter, r, inputState.isPressed(ButtonId.ls));
    _drawStickDot(
      canvas, leftCenter, r,
      inputState.leftStickX, inputState.leftStickY,
    );

    // Right stick well
    final rightCenter = Offset(w * _rightStickX, h * _rightStickY);
    _drawWell(canvas, rightCenter, r, inputState.isPressed(ButtonId.rs));
    _drawStickDot(
      canvas, rightCenter, r,
      inputState.rightStickX, inputState.rightStickY,
    );
  }

  void _drawWell(Canvas canvas, Offset center, double r, bool pressed) {
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = dimmed
            ? colorScheme.surfaceContainerLow.withAlpha(60)
            : colorScheme.surfaceContainerLow,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = pressed
            ? colorScheme.primary
            : (dimmed ? colorScheme.outline.withAlpha(60) : colorScheme.outline)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pressed ? 2.5 : 1.5,
    );
  }

  void _drawStickDot(
    Canvas canvas,
    Offset wellCenter,
    double wellRadius,
    double stickX,
    double stickY,
  ) {
    final dotRadius = wellRadius * 0.28;
    final range = wellRadius - dotRadius - 2;
    final magnitude = math.sqrt(stickX * stickX + stickY * stickY);
    final isActive = magnitude > 0.05;

    // Negate Y so positive Y (stick up) moves dot UP on screen
    final dotCenter = Offset(
      wellCenter.dx + stickX * range,
      wellCenter.dy - stickY * range,
    );

    canvas.drawCircle(
      dotCenter,
      dotRadius,
      Paint()
        ..color = isActive
            ? (dimmed ? colorScheme.primary.withAlpha(100) : colorScheme.primary)
            : (dimmed
                ? colorScheme.outline.withAlpha(60)
                : colorScheme.outline.withAlpha(120)),
    );

    // Line from center to dot when active
    if (isActive) {
      canvas.drawLine(
        wellCenter,
        dotCenter,
        Paint()
          ..color = dimmed
              ? colorScheme.primary.withAlpha(40)
              : colorScheme.primary.withAlpha(80)
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawBumpers(Canvas canvas, double w, double h) {
    // LB
    _drawRoundedRect(
      canvas,
      Rect.fromLTRB(
        w * _lbLeft, h * _bumperTop,
        w * _lbRight, h * _bumperBottom,
      ),
      8,
      ButtonId.lb,
    );
    // RB
    _drawRoundedRect(
      canvas,
      Rect.fromLTRB(
        w * _rbLeft, h * _bumperTop,
        w * _rbRight, h * _bumperBottom,
      ),
      8,
      ButtonId.rb,
    );
  }

  void _drawRoundedRect(
    Canvas canvas,
    Rect rect,
    double radius,
    String buttonId,
  ) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = _btnColor(buttonId));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = inputState.isPressed(buttonId)
            ? colorScheme.primary
            : (dimmed ? colorScheme.outline.withAlpha(60) : colorScheme.outline)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawLabel(canvas, rect.center, _label(buttonId), buttonId, 11);
  }

  void _drawDpad(Canvas canvas, double w, double h) {
    final cx = w * _dpadX;
    final cy = h * _dpadY;
    final arm = w * _dpadArm;
    final half = w * _dpadWidth;

    // Vertical bar
    _drawDpadArm(
      canvas,
      Rect.fromLTRB(cx - half, cy - arm - half, cx + half, cy + arm + half),
      isUp: inputState.isPressed(ButtonId.dpadUp),
      isDown: inputState.isPressed(ButtonId.dpadDown),
    );
    // Horizontal bar
    _drawDpadArm(
      canvas,
      Rect.fromLTRB(cx - arm - half, cy - half, cx + arm + half, cy + half),
      isLeft: inputState.isPressed(ButtonId.dpadLeft),
      isRight: inputState.isPressed(ButtonId.dpadRight),
    );
    // Center square
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: half * 2, height: half * 2),
      Paint()..color = colorScheme.surfaceContainerHigh,
    );
  }

  void _drawDpadArm(
    Canvas canvas,
    Rect rect, {
    bool isUp = false,
    bool isDown = false,
    bool isLeft = false,
    bool isRight = false,
  }) {
    final isHorizontal = rect.width > rect.height;

    if (isHorizontal) {
      // Left half
      final leftRect = Rect.fromLTRB(
        rect.left, rect.top, rect.center.dx, rect.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(leftRect, const Radius.circular(3)),
        Paint()
          ..color = isLeft
              ? colorScheme.primary
              : (dimmed
                  ? colorScheme.surfaceContainerHigh.withAlpha(60)
                  : colorScheme.surfaceContainerHigh),
      );
      // Right half
      final rightRect = Rect.fromLTRB(
        rect.center.dx, rect.top, rect.right, rect.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rightRect, const Radius.circular(3)),
        Paint()
          ..color = isRight
              ? colorScheme.primary
              : (dimmed
                  ? colorScheme.surfaceContainerHigh.withAlpha(60)
                  : colorScheme.surfaceContainerHigh),
      );
    } else {
      // Top half
      final topRect = Rect.fromLTRB(
        rect.left, rect.top, rect.right, rect.center.dy,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(topRect, const Radius.circular(3)),
        Paint()
          ..color = isUp
              ? colorScheme.primary
              : (dimmed
                  ? colorScheme.surfaceContainerHigh.withAlpha(60)
                  : colorScheme.surfaceContainerHigh),
      );
      // Bottom half
      final bottomRect = Rect.fromLTRB(
        rect.left, rect.center.dy, rect.right, rect.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bottomRect, const Radius.circular(3)),
        Paint()
          ..color = isDown
              ? colorScheme.primary
              : (dimmed
                  ? colorScheme.surfaceContainerHigh.withAlpha(60)
                  : colorScheme.surfaceContainerHigh),
      );
    }

    // Outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = dimmed ? colorScheme.outline.withAlpha(60) : colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawFaceButtons(Canvas canvas, double w, double h) {
    final cx = w * _abxyX;
    final cy = h * _abxyY;
    final sp = w * _abxySpacing;
    final r = w * 0.028;

    // A (bottom)
    _drawCircleButton(canvas, Offset(cx, cy + sp), r, ButtonId.a,
        activeColor: Colors.green);
    // B (right)
    _drawCircleButton(canvas, Offset(cx + sp, cy), r, ButtonId.b,
        activeColor: Colors.red);
    // X (left)
    _drawCircleButton(canvas, Offset(cx - sp, cy), r, ButtonId.x,
        activeColor: Colors.blue);
    // Y (top)
    _drawCircleButton(canvas, Offset(cx, cy - sp), r, ButtonId.y,
        activeColor: Colors.amber);
  }

  void _drawCircleButton(
    Canvas canvas,
    Offset center,
    double radius,
    String buttonId, {
    Color? activeColor,
  }) {
    final isActive = inputState.isPressed(buttonId);
    final fill = isActive
        ? (activeColor ?? colorScheme.primary)
        : (dimmed
            ? colorScheme.surfaceContainerHigh.withAlpha(60)
            : colorScheme.surfaceContainerHigh);

    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = activeColor != null
            ? (dimmed ? activeColor.withAlpha(60) : activeColor)
            : (dimmed ? colorScheme.outline.withAlpha(60) : colorScheme.outline)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawLabel(canvas, center, _label(buttonId), buttonId, 10);
  }

  void _drawCenterButtons(Canvas canvas, double w, double h) {
    final r = w * 0.022;
    // Back
    _drawCircleButton(
      canvas,
      Offset(w * _backX, h * _centerBtnY),
      r,
      ButtonId.back,
    );
    // Start
    _drawCircleButton(
      canvas,
      Offset(w * _startX, h * _centerBtnY),
      r,
      ButtonId.start,
    );
    // Guide (larger)
    _drawCircleButton(
      canvas,
      Offset(w * _guideX, h * _guideY),
      r * 1.3,
      ButtonId.guide,
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    String text,
    String buttonId,
    double fontSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: dimmed ? _textColor(buttonId).withAlpha(80) : _textColor(buttonId),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(XboxControllerPainter oldDelegate) =>
      inputState != oldDelegate.inputState ||
      dimmed != oldDelegate.dimmed ||
      isPlayStation != oldDelegate.isPlayStation;
}
