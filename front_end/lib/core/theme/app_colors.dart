import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Base
  static const Color primaryDark = Color(0xFF0F101A);
  static const Color secondaryDark = Color(0xFF1A1C2C);
  static const Color tertiaryDark = Color(0xFF23243A);

  // Primary Accents (Pink/Red Gradients)
  static const Color pinkPrimary = Color(0xFFFF2E78);
  static const Color pinkSecondary = Color(0xFFFF4C75);
  static const Color redAccent = Color(0xFFFF3344);

  // Secondary Accents (Purple Gradients)
  static const Color purplePrimary = Color(0xFF8A5AFF);
  static const Color purpleSecondary = Color(0xFFC047FF);
  static const Color purplePink = Color(0xFFFF2A68);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFC4C4C4);
  static const Color mediumGray = Color(0xFF7A7A8C);
  static const Color darkGray = Color(0xFF2A2B3D);

  // Alert Colors
  static const Color emergencyRed = Color(0xFFFF1744);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color infoBlue = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pinkPrimary, purplePrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [pinkPrimary, pinkSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purplePrimary, purpleSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1C2C), Color(0xFF23243A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Chart Gradient
  static LinearGradient chartGradient = LinearGradient(
    colors: [
      pinkPrimary.withAlpha(144),
      purplePrimary.withAlpha(48),
      Colors.transparent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
