import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final Gradient? borderGradient;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0,
    this.padding = const EdgeInsets.all(20.0),
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.borderGradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? AppColors.glassBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderGradient != null
                  ? null
                  : Border.all(
                      color: borderColor ?? AppColors.glassBorder,
                      width: 1.2,
                    ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
