import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Action & Interactive Accent
  static const Color primary = Color(0xFF0066CC); // Action Blue
  static const Color primaryFocus = Color(0xFF0071E3); // Focus Blue
  static const Color primaryOnDark = Color(0xFF2997FF); // Sky Link Blue
  
  // Light Surfaces
  static const Color canvas = Color(0xFFFFFFFF); // Pure White
  static const Color canvasParchment = Color(0xFFF5F5F7); // Parchment Off-White
  static const Color surfacePearl = Color(0xFFFAFAFC); // Pearl Button Capsule
  static const Color hairline = Color(0xFFE0E0E0); // Hairline Card Border
  static const Color borderSoft = Color(0x0A000000); // 4% Alpha Black Divider

  // Dark Surfaces (Near-Black Tiles)
  static const Color surfaceTile1 = Color(0xFF272729); // Near-Black Tile 1
  static const Color surfaceTile2 = Color(0xFF2A2A2C); // Near-Black Tile 2
  static const Color surfaceTile3 = Color(0xFF252527); // Near-Black Tile 3
  static const Color surfaceBlack = Color(0xFF000000); // Pure Black (Void)

  // Typography - Light Mode
  static const Color ink = Color(0xFF1D1D1F); // Near-Black Ink
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF7A7A7A); // Ink Muted 48
  static const Color textLight = Color(0xFF7A7A7A);

  // Typography - Dark Mode
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // White
  static const Color textSecondaryDark = Color(0xFFCCCCCC); // Body Muted
  static const Color inkMuted80 = Color(0xFF333333); // Softer Black

  // Feedback status colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}
