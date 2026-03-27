import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nearby_provider.dart';
import '../utils/app_theme.dart';

class RadarAnimation extends StatefulWidget {
  const RadarAnimation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RadarAnimationState createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<NearbyProvider>().isScanning) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isScanning = context.watch<NearbyProvider>().isScanning;
    if (isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!isScanning && _controller.isAnimating) {
      _controller.stop();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(280, 280),
          painter: RadarPainter(
            animationValue: _controller.value,
            progress: isScanning ? _controller.value : 0.0,
          ),
          child: Container(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isScanning
                        ? AppTheme.amber.withValues(alpha: 0.25)
                        : AppTheme.royalBlue.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: isScanning
                      ? AppTheme.amber.withValues(alpha: 0.70)
                      : AppTheme.borderBlue.withValues(alpha: 0.60),
                  width: 2,
                ),
                boxShadow: isScanning
                    ? [
                        BoxShadow(
                          color: AppTheme.amber.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isScanning ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                color: isScanning ? AppTheme.amber : AppTheme.borderBlue,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double animationValue;
  final double progress;

  RadarPainter({required this.animationValue, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // ── Static ring grid
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final fraction = i / 4;
      canvas.drawCircle(
        center,
        maxRadius * fraction,
        ringPaint..color = AppTheme.royalBlue.withValues(alpha: 0.20),
      );
    }

    // ── Cross hairs
    final crossPaint = Paint()
      ..color = AppTheme.royalBlue.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(center.dx, center.dy - maxRadius),
        Offset(center.dx, center.dy + maxRadius),
        crossPaint);
    canvas.drawLine(
        Offset(center.dx - maxRadius, center.dy),
        Offset(center.dx + maxRadius, center.dy),
        crossPaint);

    if (progress > 0) {
      // ── Expanding pulse rings
      for (int i = 0; i < 3; i++) {
        final ringValue = (animationValue + (i / 3)) % 1.0;
        final radius = maxRadius * ringValue;
        final opacity = (1.0 - ringValue).clamp(0.0, 1.0);

        canvas.drawCircle(
          center,
          radius,
          ringPaint
            ..color = AppTheme.royalBlue.withValues(alpha: opacity * 0.50)
            ..strokeWidth = 1.8,
        );
      }

      // ── Sweep gradient
      final angle = animationValue * 2 * pi;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      canvas.drawCircle(
        Offset.zero,
        maxRadius,
        Paint()
          ..shader = SweepGradient(
            colors: [
              AppTheme.amber.withValues(alpha: 0.30),
              AppTheme.royalBlue.withValues(alpha: 0.15),
              Colors.transparent,
            ],
            stops: const [0.0, 0.15, 0.4],
          ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: maxRadius)),
      );

      // ── Sweep arm line
      canvas.drawLine(
        Offset.zero,
        Offset(maxRadius, 0),
        Paint()
          ..color = AppTheme.amber.withValues(alpha: 0.85)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );

      // ── Dot at sweep tip
      canvas.drawCircle(
        Offset(maxRadius * 0.92, 0),
        3.5,
        Paint()..color = AppTheme.amber,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.progress != progress;
  }
}
