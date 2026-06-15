import 'package:flutter/material.dart';

class AppColors {
  // Primary dark background
  static const Color background = Color(0xFF0B0F14);
  
  // Panels/Surface base colors
  static const Color surface = Color(0xFF121820);
  static const Color surfaceLight = Color(0xFF1B232E);
  
  // Accents
  static const Color blueAccent = Color(0xFF007AFF);
  static const Color purpleAccent = Color(0xFF9D4EDD);
  static const Color greenAccent = Color(0xFF2ECC71);
  static const Color orangeAccent = Color(0xFFF39C12);
  static const Color redAccent = Color(0xFFE74C3C);
  
  // Typography
  static const Color textPrimary = Color(0xFFF8F9FA);
  static const Color textSecondary = Color(0xFF8E9AA8);
  static const Color textMuted = Color(0xFF5A6876);
  
  // Glassmorphic Opacities
  static Color glassBg = Colors.white.withOpacity(0.08);
  static Color glassBorder = Colors.white.withOpacity(0.12);
  static Color glassHighlight = Colors.white.withOpacity(0.18);
  
  // Ambient glow gradients
  static const List<Color> blueGlowGradient = [
    Color(0x33007AFF),
    Colors.transparent,
  ];
  static const List<Color> purpleGlowGradient = [
    Color(0x339D4EDD),
    Colors.transparent,
  ];
}
