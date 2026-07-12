import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.canvas,
        secondary: AppColors.primary,
        onSecondary: AppColors.canvas,
        error: AppColors.error,
        surface: AppColors.canvas,
        onSurface: AppColors.ink,
      ),
      
      // Card Theme (1px Hairline Border, 18px Rounding, No Shadows)
      cardTheme: CardThemeData(
        color: AppColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),

      // Typographic Hierarchy (SF Pro System Standards)
      textTheme: const TextTheme(
        // Hero Display (56px, Weight 600, Tracking -0.28px)
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.28,
          height: 1.07,
        ),
        // Display Lg (40px, Weight 600)
        displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: 0,
          height: 1.10,
        ),
        // Lead (28px, Weight 400)
        titleLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          letterSpacing: 0.196,
          height: 1.14,
        ),
        // Tagline (21px, Weight 600)
        titleMedium: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: 0.231,
          height: 1.19,
        ),
        // Body (17px, Weight 400, Tracking -0.374px)
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          letterSpacing: -0.374,
          height: 1.47,
        ),
        // Caption (14px, Weight 400, Tracking -0.224px)
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: -0.224,
          height: 1.43,
        ),
        // Fine Print (12px, Weight 400)
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: -0.12,
          height: 1.0,
        ),
      ),

      // Input Decoration Theme (Frosted/Parchment Inputs, 8px Rounding, Shadowless)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvasParchment,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14, letterSpacing: -0.224),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14, letterSpacing: -0.224),
      ),

      // Button Themes (Capsules, Shadowless)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.canvas,
          elevation: 0,
          minimumSize: const Size(double.infinity, 44),
          shape: const StadiumBorder(), // Pill radius (9999px)
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.374,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const StadiumBorder(), // Pill radius (9999px)
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.374,
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.231,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryOnDark,
      scaffoldBackgroundColor: AppColors.surfaceTile3,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryOnDark,
        onPrimary: AppColors.surfaceBlack,
        secondary: AppColors.primaryOnDark,
        onSecondary: AppColors.surfaceBlack,
        error: AppColors.error,
        surface: AppColors.surfaceTile1,
        onSurface: AppColors.textPrimaryDark,
      ),
      
      // Card Theme (1px Dark Border, 18px Rounding, No Shadows)
      cardTheme: CardThemeData(
        color: AppColors.surfaceTile1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF333335), width: 1),
        ),
      ),

      // Typographic Hierarchy (SF Pro System Standards)
      textTheme: const TextTheme(
        // Hero Display
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.28,
          height: 1.07,
        ),
        // Display Lg
        displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: 0,
          height: 1.10,
        ),
        // Lead
        titleLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimaryDark,
          letterSpacing: 0.196,
          height: 1.14,
        ),
        // Tagline
        titleMedium: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          letterSpacing: 0.231,
          height: 1.19,
        ),
        // Body
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.374,
          height: 1.47,
        ),
        // Caption
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
          letterSpacing: -0.224,
          height: 1.43,
        ),
        // Fine Print
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
          letterSpacing: -0.12,
          height: 1.0,
        ),
      ),

      // Input Decoration Theme (Dark Slate Inputs, 8px Rounding, Shadowless)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceTile1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryOnDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, letterSpacing: -0.224),
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, letterSpacing: -0.224),
      ),

      // Button Themes (Capsules, Shadowless)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOnDark,
          foregroundColor: AppColors.surfaceBlack,
          elevation: 0,
          minimumSize: const Size(double.infinity, 44),
          shape: const StadiumBorder(), // Pill radius (9999px)
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.374,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOnDark,
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppColors.primaryOnDark, width: 1.5),
          shape: const StadiumBorder(), // Pill radius (9999px)
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.374,
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.231,
        ),
      ),
    );
  }
}
