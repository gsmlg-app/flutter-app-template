import 'package:flutter/material.dart';
import 'pelican_bicycle_painter.dart';

/// Interactive widget that hosts the animated pelican riding a bicycle.
class PelicanBicycleWidget extends StatefulWidget {
  final double speedFactor;
  final bool isPlaying;
  final PelicanRideTimeOfDay timeOfDay;
  final bool showSunglasses;
  final bool showCap;
  final bool showFishInPouch;
  final bool showSpeedLines;
  final bool showDust;
  final Color? bikeFrameColor;
  final double? height;
  final double? width;

  const PelicanBicycleWidget({
    super.key,
    this.speedFactor = 1.0,
    this.isPlaying = true,
    this.timeOfDay = PelicanRideTimeOfDay.day,
    this.showSunglasses = true,
    this.showCap = true,
    this.showFishInPouch = true,
    this.showSpeedLines = true,
    this.showDust = true,
    this.bikeFrameColor,
    this.height,
    this.width,
  });

  @override
  State<PelicanBicycleWidget> createState() => _PelicanBicycleWidgetState();
}

class _PelicanBicycleWidgetState extends State<PelicanBicycleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PelicanBicycleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: AspectRatio(
        aspectRatio:
            PelicanBicyclePainter.refWidth / PelicanBicyclePainter.refHeight,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: PelicanBicyclePainter(
                options: PelicanBicyclePainterOptions(
                  animationValue: _controller.value,
                  speedFactor: widget.speedFactor,
                  timeOfDay: widget.timeOfDay,
                  showSunglasses: widget.showSunglasses,
                  showCap: widget.showCap,
                  showFishInPouch: widget.showFishInPouch,
                  showSpeedLines: widget.showSpeedLines,
                  showDust: widget.showDust,
                  bikeFrameColor: widget.bikeFrameColor,
                ),
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}
