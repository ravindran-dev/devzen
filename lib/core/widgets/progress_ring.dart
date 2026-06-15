import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color? inactiveColor;
  final Widget? centerWidget;

  const ProgressRing({
    Key? key,
    required this.value,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.activeColor = AppColors.blueAccent,
    this.inactiveColor,
    this.centerWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              value: value,
              strokeWidth: strokeWidth,
              activeColor: activeColor,
              inactiveColor: inactiveColor ?? AppColors.glassBorder,
            ),
          ),
          if (centerWidget != null) centerWidget!,
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;

  _ProgressRingPainter({
    required this.value,
    required this.strokeWidth,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    final progressPaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gradient outline
    final rect = Rect.fromCircle(center: center, radius: radius);
    progressPaint.shader = LinearGradient(
      colors: [activeColor, activeColor.withOpacity(0.5)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);

    final double sweepAngle = 2 * pi * value;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
