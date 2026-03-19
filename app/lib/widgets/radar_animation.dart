import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nearby_provider.dart';
import '../utils/app_theme.dart';

class RadarAnimation extends StatefulWidget {
  @override
  _RadarAnimationState createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    // Start animation if scanning is already on
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
          size: const Size(300, 300),
          painter: RadarPainter(
            animationValue: _controller.value,
            progress: isScanning ? _controller.value : 0.0,
          ),
          child: Container(
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryNeon.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.flash_on,
                color: AppTheme.primaryNeon,
                size: 40,
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

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Background circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        maxRadius * (i / 3),
        ringPaint..color = Colors.white.withOpacity(0.05),
      );
    }

    if (progress > 0) {
      // Animated expanding rings
      for (int i = 0; i < 3; i++) {
        final ringValue = (animationValue + (i / 3)) % 1.0;
        final radius = maxRadius * ringValue;
        final opacity = 1.0 - ringValue;

        canvas.drawCircle(
          center,
          radius,
          ringPaint
            ..color = AppTheme.primaryNeon.withValues(alpha: opacity * 0.4)
            ..strokeWidth = 2.0,
        );
      }

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
              AppTheme.primaryNeon.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: [0.1, 0.4],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: maxRadius)),
      );
      
      // The sharp line
      canvas.drawLine(
        Offset.zero,
        Offset(maxRadius, 0),
        Paint()
          ..color = AppTheme.primaryNeon
          ..strokeWidth = 2,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.progress != progress;
  }
}
