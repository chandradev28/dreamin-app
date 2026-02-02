import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dreamin App Theme - TIDAL-Inspired Dark Theme
class AppTheme {
  AppTheme._();

  // Colors
  static const Color backgroundColor = Color(0xFF000000);
  static const Color surfaceColor = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color surfaceLighter = Color(0xFF242424);
  
  static const Color primaryColor = Color(0xFFFFFFFF);
  static const Color secondaryColor = Color(0xFF8C8C8C);
  static const Color tertiaryColor = Color(0xFF5C5C5C);
  
  static const Color accentColor = Color(0xFFFF5555); // Red for hearts/favorites
  static const Color accentColorLight = Color(0xFFFF7777);
  
  static const Color tidalBadge = Color(0xFF00FFFF); // Cyan for TIDAL badge
  static const Color hifiBadge = Color(0xFFFFD700); // Gold for HiFi badge
  static const Color qobuzBadge = Color(0xFF9B59B6); // Purple for Qobuz badge
  
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFFB74D);

  // ============== SOURCE-SPECIFIC THEMES ==============
  
  /// TIDAL Theme - Dark with cyan accents
  static const Color tidalBackground = Color(0xFF000000);
  static const Color tidalSurface = Color(0xFF121212);
  static const Color tidalAccent = Color(0xFF00FFFF);
  
  /// Qobuz Theme - Deep purple/blue
  static const Color qobuzBackground = Color(0xFF0A0A14);
  static const Color qobuzSurface = Color(0xFF14142A);
  static const Color qobuzAccent = Color(0xFF9B59B6);
  
  /// Subsonic/HiFi Theme - Gold accents
  static const Color subsonicBackground = Color(0xFF0A0A0A);
  static const Color subsonicSurface = Color(0xFF161616);
  static const Color subsonicAccent = Color(0xFFFFD700);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF000000),
    ],
  );

  static LinearGradient albumOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.black.withOpacity(0.3),
      Colors.black.withOpacity(0.8),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // Text Styles
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: -1.0,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: -0.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: primaryColor,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryColor,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: secondaryColor,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: secondaryColor,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: tertiaryColor,
  );

  // Theme Data
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: backgroundColor,
      onSecondary: primaryColor,
      onSurface: primaryColor,
      onError: primaryColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: primaryColor),
      titleTextStyle: titleLarge,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
      size: 24,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: surfaceLighter,
      thumbColor: primaryColor,
      trackHeight: 4,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    textTheme: TextTheme(
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
    dividerTheme: const DividerThemeData(
      color: surfaceLighter,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      hintStyle: bodyMedium.copyWith(color: tertiaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: labelLarge.copyWith(color: backgroundColor),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: labelLarge,
      ),
    ),
  );

  // Text Colors (for direct access)
  static const Color textPrimary = primaryColor;
  static const Color textSecondary = secondaryColor;

  // Border Radius
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(24));

  // Radius values (double)
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;
  static const double spacingXXXL = 48;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============== SOURCE GRADIENTS ==============
  
  /// TIDAL gradient - Dark with subtle cyan tint
  static const LinearGradient tidalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A1A1A),
      Color(0xFF000000),
    ],
  );
  
  /// Qobuz gradient - Deep purple-blue
  static const LinearGradient qobuzGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF14142A),
      Color(0xFF0A0A14),
    ],
  );
  
  /// Subsonic gradient - Dark with gold tint
  static const LinearGradient subsonicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF161610),
      Color(0xFF0A0A0A),
    ],
  );
}

/// Source-specific theme colors container
class SourceThemeColors {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color accent;
  final Color accentLight;
  final LinearGradient gradient;

  const SourceThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.accent,
    required this.accentLight,
    required this.gradient,
  });

  /// Default TIDAL theme
  static const SourceThemeColors tidal = SourceThemeColors(
    background: AppTheme.tidalBackground,
    surface: AppTheme.tidalSurface,
    surfaceLight: AppTheme.surfaceLight,
    accent: AppTheme.tidalAccent,
    accentLight: AppTheme.tidalAccent,
    gradient: AppTheme.tidalGradient,
  );

  /// Qobuz theme  
  static const SourceThemeColors qobuz = SourceThemeColors(
    background: AppTheme.qobuzBackground,
    surface: AppTheme.qobuzSurface,
    surfaceLight: Color(0xFF1E1E3A),
    accent: AppTheme.qobuzAccent,
    accentLight: Color(0xFFB370C9),
    gradient: AppTheme.qobuzGradient,
  );

  /// Subsonic/HiFi theme
  static const SourceThemeColors subsonic = SourceThemeColors(
    background: AppTheme.subsonicBackground,
    surface: AppTheme.subsonicSurface,
    surfaceLight: Color(0xFF202020),
    accent: AppTheme.subsonicAccent,
    accentLight: Color(0xFFFFE55C),
    gradient: AppTheme.subsonicGradient,
  );
}
