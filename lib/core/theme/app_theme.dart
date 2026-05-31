import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0B0F14);
  static const card = Color(0xFF0F1520);
  static const accentStart = Color(0xFF5EEAD4);
  static const accentEnd = Color(0xFF60A5FA);
  static const mutedText = Color(0xFFAAB3C0);
  static const primaryText = Color(0xFFE6EEF6);

  // Premium fintech colors
  static const successGreen = Color(0xFF10B981);
  static const warningOrange = Color(0xFFF59E0B);
  static const errorRed = Color(0xFFEF4444);
  static const neutralGray = Color(0xFF6B7280);

  // Glassmorphism support
  static const glassTint = Color(0xFF1F2937);
}

class AppTheme {
  static TextTheme _fontTextTheme(String fontFamily, TextTheme textTheme) {
    switch (fontFamily) {
      case 'lato':
        return GoogleFonts.latoTextTheme(textTheme);
      case 'creepster':
        return GoogleFonts.creepsterTextTheme(textTheme);
      case 'inter':
      default:
        return GoogleFonts.interTextTheme(textTheme);
    }
  }

  static TextStyle _fontTextStyle(
    String fontFamily, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    switch (fontFamily) {
      case 'lato':
        return GoogleFonts.lato(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      case 'creepster':
        return GoogleFonts.creepster(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      case 'inter':
      default:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
    }
  }

  static ThemeData darkTheme([String fontFamily = 'inter']) {
    final base = _fontTextTheme(
      fontFamily,
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,

      // Color scheme with premium fintech palette
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentStart,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF0D9488),
        onPrimaryContainer: Color(0xFFCCFAF0),
        secondary: AppColors.accentEnd,
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF1E3A8A),
        onSecondaryContainer: Color(0xFFBFDBFE),
        tertiary: AppColors.successGreen,
        onTertiary: Colors.black,
        error: AppColors.errorRed,
        onError: Colors.black,
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFECACA),
        background: AppColors.background,
        onBackground: AppColors.primaryText,
        surface: AppColors.card,
        onSurface: AppColors.primaryText,
        surfaceVariant: Color(0xFF1F2937),
        onSurfaceVariant: AppColors.mutedText,
        outline: Color(0xFF4B5563),
        outlineVariant: Color(0xFF3F4755),
        scrim: Colors.black,
      ),

      // Enhanced text theme
      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        displayMedium: base.displayMedium?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: base.displaySmall?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.titleMedium?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: base.titleSmall?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          color: AppColors.primaryText,
          height: 1.5,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          color: AppColors.mutedText,
          height: 1.5,
        ),
        bodySmall: base.bodySmall?.copyWith(
          color: AppColors.mutedText,
          fontSize: 12,
        ),
        labelLarge: base.labelLarge?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: base.labelMedium?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: base.labelSmall?.copyWith(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w500,
        ),
      ),

      // App bar styling
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _fontTextStyle(
          fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
      ),

      // Card styling
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF1F2937),
            width: 1,
          ),
        ),
      ),

      // Filled button styling
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentStart,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: _fontTextStyle(
            fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      // Outlined button styling
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentStart,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(
            color: AppColors.accentStart,
            width: 2,
          ),
          textStyle: _fontTextStyle(
            fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.accentStart,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF374151),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF374151),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.accentStart,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: 1,
          ),
        ),
        hintStyle: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Chip styling
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.accentStart,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(
          color: Color(0xFF374151),
          width: 1,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.primaryText,
      ),

      // Divider styling
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1F2937),
        thickness: 1,
      ),

      // Dialog styling
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF374151),
            width: 1,
          ),
        ),
      ),
    );
  }

  static ThemeData lightTheme([String fontFamily = 'inter']) {
    return ThemeData.light(useMaterial3: true).copyWith(
      textTheme: _fontTextTheme(
        fontFamily,
        ThemeData.light(useMaterial3: true).textTheme,
      ),
    );
  }
}
