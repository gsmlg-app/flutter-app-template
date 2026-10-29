import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Time-of-day theme for the pelican ride scene.
enum PelicanRideTimeOfDay { day, sunset, night }

/// Parameters configuring the pelican bicycle painter.
class PelicanBicyclePainterOptions {
  final double animationValue; // 0.0 to 1.0 continuous progress
  final double speedFactor; // 0.2 to 3.0
  final PelicanRideTimeOfDay timeOfDay;
  final bool showSunglasses;
  final bool showCap;
  final bool showFishInPouch;
  final bool showSpeedLines;
  final bool showDust;
  final Color? bikeFrameColor;

  const PelicanBicyclePainterOptions({
    required this.animationValue,
    this.speedFactor = 1.0,
    this.timeOfDay = PelicanRideTimeOfDay.day,
    this.showSunglasses = true,
    this.showCap = true,
    this.showFishInPouch = true,
    this.showSpeedLines = true,
    this.showDust = true,
    this.bikeFrameColor,
  });
}

/// CustomPainter rendering a charming pelican riding a bicycle with realistic
/// 2D inverse-kinematic pedaling, secondary motion, and parallax road environment.
class PelicanBicyclePainter extends CustomPainter {
  final PelicanBicyclePainterOptions options;

  PelicanBicyclePainter({required this.options});

  // Reference canvas size for coordinate design
  static const double refWidth = 600.0;
  static const double refHeight = 400.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Scale canvas to maintain aspect ratio and fill center
    canvas.save();
    final scale = math.min(size.width / refWidth, size.height / refHeight);
    final dx = (size.width - refWidth * scale) / 2;
    final dy = (size.height - refHeight * scale) / 2;
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    // Clip to reference rect
    final bounds = const Rect.fromLTWH(0, 0, refWidth, refHeight);
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(16)),
    );

    final t = options.animationValue;
    final speed = options.speedFactor;

    // 1. Draw Background Sky & Celestials
    _drawSkyAndEnvironment(canvas, bounds, t, speed);

    // 2. Road surface & Moving road dashes
    _drawRoad(canvas, bounds, t, speed);

    // 3. Bicycle and Pelican calculations
    // Ground Y = 320
    // Wheel Radius = 56
    // Front wheel center: (420, 264), Rear wheel center: (190, 264)
    const double rearAxleX = 190.0;
    const double rearAxleY = 264.0;
    const double frontAxleX = 420.0;
    const double frontAxleY = 264.0;
    const double wheelRadius = 56.0;

    // Bottom bracket (crank axis)
    const double crankX = 295.0;
    const double crankY = 264.0;
    const double crankRadius = 24.0;

    // Phase angles
    final double pedalAngle = (t * math.pi * 2 * 3.5 * speed) % (math.pi * 2);
    final double wheelAngle = (t * math.pi * 2 * 5.0 * speed) % (math.pi * 2);

    // Dynamic bobbing: body and saddle bounce gently
    final double bobY = math.sin(pedalAngle * 2) * 3.0;
    final double pouchJiggle = math.sin(pedalAngle * 2 - 0.8) * 4.0;

    // Left pedal (far) and Right pedal (near)
    final Offset leftPedal = Offset(
      crankX + crankRadius * math.cos(pedalAngle + math.pi),
      crankY + crankRadius * math.sin(pedalAngle + math.pi),
    );
    final Offset rightPedal = Offset(
      crankX + crankRadius * math.cos(pedalAngle),
      crankY + crankRadius * math.sin(pedalAngle),
    );

    // Pelican Hip position
    final Offset hip = Offset(272.0, 138.0 + bobY);

    // 4. Ground Shadow
    _drawShadow(canvas, rearAxleX, frontAxleX, crankX, bobY);

    // 5. Dust Particles behind rear tire
    if (options.showDust && speed > 0.4) {
      _drawDustParticles(canvas, rearAxleX - 10, 320.0, t, speed);
    }

    // 6. Far Leg (Left leg, behind bicycle)
    _drawPelicanLeg(canvas, hip, leftPedal, isFarLeg: true);

    // 7. Bicycle Wheels (Rims, Spokes, Tires)
    _drawWheel(
      canvas,
      const Offset(rearAxleX, rearAxleY),
      wheelRadius,
      wheelAngle,
    );
    _drawWheel(
      canvas,
      const Offset(frontAxleX, frontAxleY),
      wheelRadius,
      wheelAngle,
    );

    // 8. Bicycle Frame & Components (Chain, Sprockets, Tubes, Saddle, Handlebars)
    _drawBicycleFrame(
      canvas,
      rearAxle: const Offset(rearAxleX, rearAxleY),
      frontAxle: const Offset(frontAxleX, frontAxleY),
      crank: const Offset(crankX, crankY),
      pedalAngle: pedalAngle,
      frameColor: options.bikeFrameColor ?? const Color(0xFFE65100),
    );

    // 9. Pelican Body, Head, Beak, Pouch & Accessories
    _drawPelican(
      canvas,
      hip: hip,
      bobY: bobY,
      pouchJiggle: pouchJiggle,
      handlebarGrip: const Offset(390.0, 126.0),
    );

    // 10. Near Leg (Right leg, in front of bicycle)
    _drawPelicanLeg(canvas, hip, rightPedal, isFarLeg: false);

    // 11. Near Crank Arm & Pedal
    _drawCrankArm(
      canvas,
      const Offset(crankX, crankY),
      rightPedal,
      isNear: true,
    );

    // 12. Speed Lines (Wind effect)
    if (options.showSpeedLines && speed > 0.6) {
      _drawSpeedLines(canvas, bounds, t, speed);
    }

    canvas.restore();
  }

  // --- 1. Sky & Environment ---
  void _drawSkyAndEnvironment(
    Canvas canvas,
    Rect bounds,
    double t,
    double speed,
  ) {
    final Paint skyPaint = Paint()..style = PaintingStyle.fill;

    switch (options.timeOfDay) {
      case PelicanRideTimeOfDay.day:
        skyPaint.shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64B5F6), Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
        ).createShader(bounds);
        break;
      case PelicanRideTimeOfDay.sunset:
        skyPaint.shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A148C), Color(0xFFD81B60), Color(0xFFFFB74D)],
        ).createShader(bounds);
        break;
      case PelicanRideTimeOfDay.night:
        skyPaint.shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
        ).createShader(bounds);
        break;
    }
    canvas.drawRect(bounds, skyPaint);

    // Celestial body
    if (options.timeOfDay == PelicanRideTimeOfDay.night) {
      // Crescent Moon
      const moonCenter = Offset(500, 75);
      final moonGlow = Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(moonCenter, 28, moonGlow);

      final moonPaint = Paint()..color = const Color(0xFFFFF9C4);
      canvas.drawCircle(moonCenter, 22, moonPaint);
      final darkMoon = Paint()..color = const Color(0xFF122033);
      canvas.drawCircle(const Offset(492, 70), 18, darkMoon);

      // Twinkling stars
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      const starPositions = [
        Offset(60, 40),
        Offset(120, 80),
        Offset(180, 35),
        Offset(270, 70),
        Offset(340, 30),
        Offset(430, 90),
        Offset(550, 45),
      ];
      for (int i = 0; i < starPositions.length; i++) {
        final twinkle = 1.0 + 0.5 * math.sin((t * 6 + i) * math.pi);
        canvas.drawCircle(starPositions[i], 1.5 * twinkle, starPaint);
      }
    } else {
      // Sun
      final isSunset = options.timeOfDay == PelicanRideTimeOfDay.sunset;
      final sunCenter = isSunset
          ? const Offset(490, 180)
          : const Offset(490, 70);
      final sunColor = isSunset
          ? const Color(0xFFFF7043)
          : const Color(0xFFFFEB3B);

      final glowPaint = Paint()
        ..color = sunColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(sunCenter, 44, glowPaint);

      final sunPaint = Paint()..color = sunColor;
      canvas.drawCircle(sunCenter, 28, sunPaint);
    }

    // Distant Rolling Hills (Parallax layer 1)
    final hillPaint = Paint()
      ..color =
          (options.timeOfDay == PelicanRideTimeOfDay.night
                  ? const Color(0xFF243B55)
                  : (options.timeOfDay == PelicanRideTimeOfDay.sunset
                        ? const Color(0xFF6D214F)
                        : const Color(0xFFA5D6A7)))
              .withValues(alpha: 0.7);

    final hillPath = Path();
    hillPath.moveTo(0, 320);
    for (double x = 0; x <= refWidth; x += 10) {
      final hillY = 240 + math.sin((x * 0.008) + (t * speed * 0.2)) * 30;
      hillPath.lineTo(x, hillY);
    }
    hillPath.lineTo(refWidth, 320);
    hillPath.close();
    canvas.drawPath(hillPath, hillPaint);

    // Floating Clouds (Parallax layer 2)
    _drawClouds(canvas, t, speed);
  }

  void _drawClouds(Canvas canvas, double t, double speed) {
    final cloudColor = (options.timeOfDay == PelicanRideTimeOfDay.night)
        ? Colors.white.withValues(alpha: 0.12)
        : (options.timeOfDay == PelicanRideTimeOfDay.sunset
              ? const Color(0xFFFFCCBC).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.85));

    final cloudPaint = Paint()..color = cloudColor;

    // Moving clouds from right to left
    final cloudOffsets = [
      Offset((680 - (t * speed * 70 + 80)) % 750 - 80, 50),
      Offset((680 - (t * speed * 50 + 350)) % 750 - 80, 95),
      Offset((680 - (t * speed * 90 + 580)) % 750 - 80, 40),
    ];

    for (final pos in cloudOffsets) {
      canvas.drawCircle(pos, 22, cloudPaint);
      canvas.drawCircle(pos + const Offset(18, -6), 18, cloudPaint);
      canvas.drawCircle(pos + const Offset(36, 2), 16, cloudPaint);
      canvas.drawCircle(pos + const Offset(-18, 4), 15, cloudPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - 22, pos.dy, 68, 16),
          const Radius.circular(8),
        ),
        cloudPaint,
      );
    }
  }

  // --- 2. Road Surface & Dashes ---
  void _drawRoad(Canvas canvas, Rect bounds, double t, double speed) {
    const double roadTop = 320.0;
    final roadRect = Rect.fromLTWH(0, roadTop, refWidth, refHeight - roadTop);

    // Road body
    final roadPaint = Paint()
      ..color = (options.timeOfDay == PelicanRideTimeOfDay.night)
          ? const Color(0xFF1E272C)
          : const Color(0xFF455A64);
    canvas.drawRect(roadRect, roadPaint);

    // Top road curb / verge line
    final curbPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawLine(
      const Offset(0, roadTop),
      const Offset(refWidth, roadTop),
      curbPaint,
    );

    // Moving dashed road line
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final dashOffset = (t * speed * 350) % 50;
    for (double x = -dashOffset; x < refWidth; x += 50) {
      canvas.drawLine(Offset(x, 355), Offset(x + 28, 355), dashPaint);
    }
  }

  // --- 4. Shadow ---
  void _drawShadow(
    Canvas canvas,
    double rearX,
    double frontX,
    double crankX,
    double bobY,
  ) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Rear wheel contact shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rearX, 320), width: 70, height: 12),
      shadowPaint,
    );
    // Front wheel contact shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(frontX, 320), width: 70, height: 12),
      shadowPaint,
    );
    // Center bike & pelican body shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(crankX + 10, 321), width: 140, height: 14),
      shadowPaint,
    );
  }

  // --- 5. Dust Particles ---
  void _drawDustParticles(
    Canvas canvas,
    double originX,
    double originY,
    double t,
    double speed,
  ) {
    final dustPaint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);

    for (int i = 0; i < 7; i++) {
      final seed = (t * 4 * speed + i * 0.17) % 1.0;
      final x = originX - seed * 60 - rand.nextDouble() * 20;
      final y = originY - math.sin(seed * math.pi) * 22 - rand.nextDouble() * 5;
      final alpha = (1.0 - seed) * 0.45;
      final radius = 2.0 + seed * 8.0;

      dustPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, dustPaint);
    }
  }

  // --- 7. Wheels & Spokes ---
  void _drawWheel(Canvas canvas, Offset center, double radius, double angle) {
    // Outer tire (Rubber)
    final tirePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;
    canvas.drawCircle(center, radius, tirePaint);

    // Rim
    final rimPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius - 4.5, rimPaint);

    // Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const int numSpokes = 12;
    for (int i = 0; i < numSpokes; i++) {
      final a = angle + (i * 2 * math.pi / numSpokes);
      final spokeEnd = Offset(
        center.dx + (radius - 5) * math.cos(a),
        center.dy + (radius - 5) * math.sin(a),
      );
      canvas.drawLine(center, spokeEnd, spokePaint);
    }

    // Hub cap
    final hubPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawCircle(center, 6.0, hubPaint);
    final hubPin = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawCircle(center, 2.5, hubPin);
  }

  // --- 8. Bicycle Frame ---
  void _drawBicycleFrame(
    Canvas canvas, {
    required Offset rearAxle,
    required Offset frontAxle,
    required Offset crank,
    required double pedalAngle,
    required Color frameColor,
  }) {
    const seatJunction = Offset(265.0, 175.0);
    const headTubeTop = Offset(385.0, 148.0);
    const headTubeBottom = Offset(390.0, 178.0);

    // Frame tubes paint
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rearStayPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // Chain (from crank to rear axle)
    final chainPaint = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawLine(
      crank + const Offset(0, -9),
      rearAxle + const Offset(0, -6),
      chainPaint,
    );
    canvas.drawLine(
      crank + const Offset(0, 9),
      rearAxle + const Offset(0, 6),
      chainPaint,
    );

    // Rear sprocket
    final sprocketPaint = Paint()..color = const Color(0xFF90A4AE);
    canvas.drawCircle(rearAxle, 11.0, sprocketPaint);

    // Rear stays: Seat junction -> Rear axle, and Crank -> Rear axle
    canvas.drawLine(seatJunction, rearAxle, rearStayPaint);
    canvas.drawLine(crank, rearAxle, rearStayPaint);

    // Main diamond triangle
    canvas.drawLine(crank, seatJunction, framePaint); // Seat tube
    canvas.drawLine(crank, headTubeBottom, framePaint); // Down tube
    canvas.drawLine(seatJunction, headTubeTop, framePaint); // Top tube
    canvas.drawLine(headTubeTop, headTubeBottom, framePaint); // Head tube

    // Front fork: Head tube bottom -> Front axle
    final forkPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(headTubeBottom, frontAxle, forkPaint);

    // Seat post & Saddle
    final seatPostPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawLine(seatJunction, const Offset(262.0, 150.0), seatPostPaint);

    // Saddle (padded leather seat)
    final saddlePath = Path()
      ..moveTo(238.0, 147.0)
      ..quadraticBezierTo(258.0, 142.0, 280.0, 147.0)
      ..quadraticBezierTo(275.0, 155.0, 255.0, 154.0)
      ..close();
    final saddlePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawPath(saddlePath, saddlePaint);

    // Stem and Handlebars
    final stemPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(headTubeTop, const Offset(384.0, 126.0), stemPaint);

    // Handlebar bar & curved grips
    final barPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;
    final barPath = Path()
      ..moveTo(375.0, 128.0)
      ..quadraticBezierTo(388.0, 122.0, 396.0, 134.0);
    canvas.drawPath(barPath, barPaint);

    // Front chainring
    final chainringPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(crank, 15.0, chainringPaint);
    final chainringDetail = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(crank, 11.0, chainringDetail);

    // Left crank arm (Far)
    _drawCrankArm(
      canvas,
      crank,
      Offset(
        crank.dx + 24.0 * math.cos(pedalAngle + math.pi),
        crank.dy + 24.0 * math.sin(pedalAngle + math.pi),
      ),
      isNear: false,
    );
  }

  void _drawCrankArm(
    Canvas canvas,
    Offset crankCenter,
    Offset pedalPos, {
    required bool isNear,
  }) {
    final crankPaint = Paint()
      ..color = isNear ? const Color(0xFFCFD8DC) : const Color(0xFF78909C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(crankCenter, pedalPos, crankPaint);

    // Pedal block
    final pedalPaint = Paint()
      ..color = isNear ? const Color(0xFF263238) : const Color(0xFF1B2428)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      pedalPos - const Offset(8, 0),
      pedalPos + const Offset(8, 0),
      pedalPaint,
    );
  }

  // --- 6 & 10. Pelican Leg & Pedaling Inverse Kinematics ---
  void _drawPelicanLeg(
    Canvas canvas,
    Offset hip,
    Offset pedal, {
    required bool isFarLeg,
  }) {
    // Bone lengths
    const double l1 = 66.0; // Thigh
    const double l2 = 64.0; // Shin

    final double dx = pedal.dx - hip.dx;
    final double dy = pedal.dy - hip.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);

    // Clamped distance to avoid singularity
    final double d = dist.clamp(10.0, l1 + l2 - 1.0);

    // Angle of direct line from hip to pedal
    final double alpha = math.atan2(dy, dx);

    // Law of cosines for knee angle
    final double cosBeta = ((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)).clamp(
      -1.0,
      1.0,
    );
    final double beta = math.acos(cosBeta);

    // Pelican faces right: knee bends forward (-beta)
    final double thighAngle = alpha - beta;
    final Offset knee = Offset(
      hip.dx + l1 * math.cos(thighAngle),
      hip.dy + l1 * math.sin(thighAngle),
    );

    // Leg colors (orange/amber bird leg)
    final Color legColor = isFarLeg
        ? const Color(0xFFE65100)
        : const Color(0xFFFFA000);
    final legPaint = Paint()
      ..color = legColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isFarLeg ? 4.5 : 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw Thigh and Shin
    canvas.drawLine(hip, knee, legPaint);
    canvas.drawLine(knee, pedal, legPaint);

    // Knee joint bump
    final kneePaint = Paint()..color = legColor;
    canvas.drawCircle(knee, isFarLeg ? 3.5 : 4.5, kneePaint);

    // Pelican Webbed Foot resting on pedal
    final footPaint = Paint()
      ..color = legColor
      ..style = PaintingStyle.fill;

    final footPath = Path()
      ..moveTo(pedal.dx - 10, pedal.dy)
      ..lineTo(pedal.dx + 14, pedal.dy - 3)
      ..lineTo(pedal.dx + 16, pedal.dy + 4)
      ..lineTo(pedal.dx + 2, pedal.dy + 3)
      ..close();
    canvas.drawPath(footPath, footPaint);
  }

  // --- 9. Pelican Body, Head, Beak, Pouch & Accessories ---
  void _drawPelican(
    Canvas canvas, {
    required Offset hip,
    required double bobY,
    required double pouchJiggle,
    required Offset handlebarGrip,
  }) {
    // 1. Tail Feathers (behind torso)
    final tailPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.fill;
    final tailPath = Path()
      ..moveTo(225.0, 125.0 + bobY)
      ..lineTo(195.0, 120.0 + bobY)
      ..lineTo(210.0, 135.0 + bobY)
      ..lineTo(190.0, 138.0 + bobY)
      ..lineTo(220.0, 145.0 + bobY)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // 2. Plump White/Cream Torso
    final bodyPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;
    final bodyShadowPaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.fill;

    // Underbelly shadow
    final bodyPath = Path()
      ..moveTo(230.0, 125.0 + bobY)
      ..cubicTo(230.0, 95.0 + bobY, 280.0, 100.0 + bobY, 310.0, 115.0 + bobY)
      ..cubicTo(325.0, 125.0 + bobY, 320.0, 155.0 + bobY, 290.0, 160.0 + bobY)
      ..cubicTo(260.0, 165.0 + bobY, 235.0, 150.0 + bobY, 230.0, 125.0 + bobY)
      ..close();
    canvas.drawPath(bodyPath, bodyShadowPaint);
    canvas.drawCircle(Offset(275.0, 130.0 + bobY), 32.0, bodyPaint);

    // 3. Elegant Curved Neck
    final neckPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round;
    final neckPath = Path()
      ..moveTo(295.0, 120.0 + bobY)
      ..cubicTo(318.0, 105.0 + bobY, 315.0, 65.0 + bobY, 340.0, 52.0 + bobY);
    canvas.drawPath(neckPath, neckPaint);

    // 4. Pelican Head
    final headCenter = Offset(348.0, 48.0 + bobY);
    canvas.drawCircle(headCenter, 18.0, bodyPaint);

    // 5. Gular Pouch (大嘴喉囊) - Dynamic elastic sagging pouch
    final pouchPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD54F), Color(0xFFFFB74D), Color(0xFFFFA726)],
      ).createShader(Rect.fromLTWH(340, 45 + bobY, 120, 70));

    final pouchPath = Path()
      ..moveTo(350.0, 54.0 + bobY)
      ..cubicTo(
        365.0,
        95.0 + bobY + pouchJiggle,
        415.0,
        102.0 + bobY + pouchJiggle,
        450.0,
        52.0 + bobY,
      )
      ..lineTo(350.0, 54.0 + bobY)
      ..close();
    canvas.drawPath(pouchPath, pouchPaint);

    // Pouch elastic texture lines
    final pouchLinePaint = Paint()
      ..color = const Color(0xFFF57C00).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(365, 60 + bobY),
      Offset(380, 85 + bobY + pouchJiggle * 0.7),
      pouchLinePaint,
    );
    canvas.drawLine(
      Offset(388, 60 + bobY),
      Offset(405, 87 + bobY + pouchJiggle * 0.8),
      pouchLinePaint,
    );
    canvas.drawLine(
      Offset(412, 58 + bobY),
      Offset(428, 76 + bobY + pouchJiggle * 0.6),
      pouchLinePaint,
    );

    // 6. Cute Easter Egg: Fish poking head out of the pouch!
    if (options.showFishInPouch) {
      _drawFishInPouch(
        canvas,
        Offset(405.0, 56.0 + bobY + pouchJiggle * 0.4),
        bobY,
      );
    }

    // 7. Pelican Beak (Upper Bill)
    final billPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(345, 38 + bobY, 125, 20));

    final billPath = Path()
      ..moveTo(345.0, 43.0 + bobY)
      ..lineTo(465.0, 47.0 + bobY)
      // Hook tip at end of bill
      ..quadraticBezierTo(472.0, 50.0 + bobY, 468.0, 56.0 + bobY)
      ..lineTo(350.0, 55.0 + bobY)
      ..close();
    canvas.drawPath(billPath, billPaint);

    // Bill center seam
    final billSeam = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(348, 48 + bobY), Offset(466, 50 + bobY), billSeam);

    // 8. Pelican Eye
    final eyeCenter = Offset(345.0, 42.0 + bobY);
    final eyeWhite = Paint()..color = Colors.white;
    canvas.drawCircle(eyeCenter, 5.5, eyeWhite);

    final eyePupil = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(eyeCenter + const Offset(1.5, 0), 3.2, eyePupil);

    final eyeHighlight = Paint()..color = Colors.white;
    canvas.drawCircle(eyeCenter + const Offset(2.2, -1.2), 1.2, eyeHighlight);

    // 9. Accessories: Sunglasses
    if (options.showSunglasses) {
      _drawSunglasses(canvas, eyeCenter);
    }

    // 10. Accessories: Cycling Cap
    if (options.showCap) {
      _drawCyclingCap(canvas, headCenter);
    }

    // 11. Pelican Wing & Arm reaching to handlebar
    _drawWingAndArm(canvas, Offset(265.0, 115.0 + bobY), handlebarGrip, bobY);
  }

  void _drawFishInPouch(Canvas canvas, Offset fishPos, double bobY) {
    // Little curious blue fish peeking out
    final fishPaint = Paint()..color = const Color(0xFF29B6F6);
    final fishBelly = Paint()..color = const Color(0xFFE1F5FE);

    // Fish head poking out tilted upwards
    canvas.save();
    canvas.translate(fishPos.dx, fishPos.dy);
    canvas.rotate(-0.35);

    // Fish body oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 13),
      fishPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 13),
      0,
      math.pi,
      false,
      fishBelly,
    );

    // Fish eye (surprised round eye)
    canvas.drawCircle(const Offset(4, -2), 3.0, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(5, -2), 1.6, Paint()..color = Colors.black);

    canvas.restore();

    // Little water bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(fishPos + const Offset(14, -10), 2.5, bubblePaint);
    canvas.drawCircle(fishPos + const Offset(19, -17), 1.5, bubblePaint);
  }

  void _drawSunglasses(Canvas canvas, Offset eyeCenter) {
    final framePaint = Paint()..color = const Color(0xFF1E272C);
    final lensPaint = Paint()
      ..shader =
          const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
          ).createShader(
            Rect.fromLTWH(eyeCenter.dx - 10, eyeCenter.dy - 6, 26, 14),
          );

    // Sunglass frame
    final lensPath = Path()
      ..moveTo(eyeCenter.dx - 8, eyeCenter.dy - 6)
      ..lineTo(eyeCenter.dx + 16, eyeCenter.dy - 5)
      ..quadraticBezierTo(
        eyeCenter.dx + 18,
        eyeCenter.dy + 8,
        eyeCenter.dx + 8,
        eyeCenter.dy + 8,
      )
      ..quadraticBezierTo(
        eyeCenter.dx - 10,
        eyeCenter.dy + 7,
        eyeCenter.dx - 8,
        eyeCenter.dy - 6,
      )
      ..close();

    canvas.drawPath(lensPath, lensPaint);

    final rimPaint = Paint()
      ..color = framePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(lensPath, rimPaint);

    // Strap behind head
    canvas.drawLine(
      Offset(eyeCenter.dx - 8, eyeCenter.dy - 4),
      Offset(eyeCenter.dx - 22, eyeCenter.dy - 1),
      rimPaint,
    );
  }

  void _drawCyclingCap(Canvas canvas, Offset headCenter) {
    final capPaint = Paint()..color = const Color(0xFFD32F2F);
    final brimPaint = Paint()..color = const Color(0xFFB71C1C);

    // Dome of cycling cap
    final capPath = Path()
      ..moveTo(headCenter.dx - 18, headCenter.dy - 4)
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy - 25,
        headCenter.dx + 16,
        headCenter.dy - 10,
      )
      ..lineTo(headCenter.dx - 18, headCenter.dy - 4)
      ..close();
    canvas.drawPath(capPath, capPaint);

    // Flipped-up front visor / brim
    final brimPath = Path()
      ..moveTo(headCenter.dx + 14, headCenter.dy - 12)
      ..quadraticBezierTo(
        headCenter.dx + 26,
        headCenter.dy - 22,
        headCenter.dx + 30,
        headCenter.dy - 16,
      )
      ..lineTo(headCenter.dx + 15, headCenter.dy - 8)
      ..close();
    canvas.drawPath(brimPath, brimPaint);

    // Cap racing stripe
    final stripePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(headCenter.dx - 14, headCenter.dy - 7),
      Offset(headCenter.dx + 14, headCenter.dy - 13),
      stripePaint,
    );
  }

  void _drawWingAndArm(
    Canvas canvas,
    Offset shoulder,
    Offset grip,
    double bobY,
  ) {
    // Folded wing side plumage
    final wingBasePaint = Paint()..color = const Color(0xFFECEFF1);
    final wingHighlight = Paint()..color = const Color(0xFFFAFAFA);

    final wingPath = Path()
      ..moveTo(shoulder.dx - 20, shoulder.dy + 8)
      ..quadraticBezierTo(
        shoulder.dx,
        shoulder.dy - 10,
        shoulder.dx + 35,
        shoulder.dy + 15,
      )
      ..quadraticBezierTo(
        shoulder.dx + 20,
        shoulder.dy + 35,
        shoulder.dx - 15,
        shoulder.dy + 25,
      )
      ..close();
    canvas.drawPath(wingPath, wingBasePaint);

    // Wing arm extending towards handlebar grip
    final armPaint = Paint()
      ..color = wingHighlight.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final armPath = Path()
      ..moveTo(shoulder.dx + 22, shoulder.dy + 10)
      ..quadraticBezierTo(shoulder.dx + 70, shoulder.dy + 15, grip.dx, grip.dy);
    canvas.drawPath(armPath, armPaint);

    // Wing-tip feathers gripping the handlebar
    final featherPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(
      grip - const Offset(2, 4),
      grip + const Offset(6, 4),
      featherPaint,
    );
    canvas.drawLine(
      grip - const Offset(4, 1),
      grip + const Offset(5, 7),
      featherPaint,
    );
  }

  // --- 12. Speed Lines ---
  void _drawSpeedLines(Canvas canvas, Rect bounds, double t, double speed) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final lines = [
      {'y': 100.0, 'len': 65.0, 'speed': 1.4, 'offset': 0.1},
      {'y': 140.0, 'len': 85.0, 'speed': 1.8, 'offset': 0.4},
      {'y': 175.0, 'len': 50.0, 'speed': 1.2, 'offset': 0.7},
      {'y': 220.0, 'len': 95.0, 'speed': 2.0, 'offset': 0.25},
      {'y': 250.0, 'len': 70.0, 'speed': 1.6, 'offset': 0.85},
    ];

    for (final line in lines) {
      final y = line['y'] as double;
      final len = line['len'] as double;
      final s = line['speed'] as double;
      final offset = line['offset'] as double;

      final progress = (t * speed * s + offset) % 1.0;
      final x = refWidth - progress * (refWidth + 150);

      canvas.drawLine(Offset(x, y), Offset(x + len, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PelicanBicyclePainter oldDelegate) {
    return oldDelegate.options.animationValue != options.animationValue ||
        oldDelegate.options.speedFactor != options.speedFactor ||
        oldDelegate.options.timeOfDay != options.timeOfDay ||
        oldDelegate.options.showSunglasses != options.showSunglasses ||
        oldDelegate.options.showCap != options.showCap ||
        oldDelegate.options.showFishInPouch != options.showFishInPouch ||
        oldDelegate.options.showSpeedLines != options.showSpeedLines ||
        oldDelegate.options.showDust != options.showDust ||
        oldDelegate.options.bikeFrameColor != options.bikeFrameColor;
  }
}
