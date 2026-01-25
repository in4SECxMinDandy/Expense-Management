import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SpendWise iOS Design System
/// Apple-inspired, Minimalist, Purple Theme with Advanced Animations
class AppTheme {
  // === COLOR PALETTE ===
  // Primary Colors (Purple Theme)
  static const Color primaryPurple = Color(0xFF9C27B0); // Tím chủ đạo
  static const Color lightPurple = Color(0xFFE1BEE7); // Tím nhạt
  static const Color darkPurple = Color(0xFF7B1FA2); // Tím đậm
  static const Color deepPurple = Color(0xFF6A1B9A); // Tím rất đậm
  static const Color softPurple = Color(0xFFF3E5F5); // Tím rất nhạt

  // Gradient Colors
  static const Color gradientStart = Color(0xFFAB47BC);
  static const Color gradientEnd = Color(0xFF7B1FA2);
  static const Color gradientStartDark = Color(0xFFCE93D8);
  static const Color gradientEndDark = Color(0xFF9C27B0);

  // Functional Colors (iOS Style)
  static const Color incomeGreen = Color(0xFF34C759); // iOS Green
  static const Color expenseRed = Color(0xFFFF3B30); // iOS Red
  static const Color warningOrange = Color(0xFFFF9500); // iOS Orange
  static const Color infoBlue = Color(0xFF007AFF); // iOS Blue
  static const Color accentTeal = Color(0xFF5AC8FA); // iOS Teal

  // Neutral Colors - Light Mode
  static const Color lightBackground = Color(0xFFF2F2F7); // iOS System Grey 6
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF9F9F9);
  static const Color lightDivider = Color(0xFFE5E5EA);

  // Neutral Colors - Dark Mode
  static const Color darkBackground = Color(0xFF000000); // Pure Black for OLED
  static const Color darkBackgroundElevated = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF1C1C1E); // iOS System Grey 6 Dark
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);
  static const Color darkDivider = Color(0xFF38383A);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textTertiaryLight = Color(0xFFC7C7CC);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textTertiaryDark = Color(0xFF48484A);

  // Glass Effect Colors
  static const Color glassLight = Color(0xCCFFFFFF); // 80% white
  static const Color glassDark = Color(0x80000000); // 50% black
  static const Color glassOverlayLight = Color(0x40FFFFFF);
  static const Color glassOverlayDark = Color(0x40000000);

  // === TYPOGRAPHY (SF Pro / Inter style) ===
  static const String fontFamily = 'Inter';

  static const TextStyle headingXL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headingL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle headingM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static const TextStyle headingS = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static const TextStyle bodyL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.4,
    height: 1.5,
  );

  static const TextStyle bodyM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.5,
  );

  static const TextStyle bodyS = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  // === SPACING & SHAPES ===
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;

  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusXXL = 32;

  // === SHADOWS (Soft, Apple-like) ===
  static List<BoxShadow> get shadowXS => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowS => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowM => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowL => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get purpleShadow => [
    BoxShadow(
      color: primaryPurple.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // === ANIMATIONS ===
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration themeTransition = Duration(milliseconds: 400);

  static const Curve animCurve = Curves.easeInOutCubicEmphasized;
  static const Curve animCurveBounce = Curves.elasticOut;
  static const Curve animCurveSmooth = Curves.easeOutCubic;

  // === GRADIENTS ===
  static LinearGradient get purpleGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static LinearGradient get purpleGradientDark => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStartDark, gradientEndDark],
  );

  static LinearGradient get incomeGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [incomeGreen.withValues(alpha: 0.8), incomeGreen],
  );

  static LinearGradient get expenseGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [expenseRed.withValues(alpha: 0.8), expenseRed],
  );

  // === THEMES ===
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: primaryPurple,
    colorScheme: ColorScheme.light(
      primary: primaryPurple,
      primaryContainer: softPurple,
      secondary: lightPurple,
      secondaryContainer: softPurple,
      surface: lightSurface,
      surfaceContainerHighest: lightSurfaceSecondary,
      error: expenseRed,
      onPrimary: Colors.white,
      onSecondary: darkPurple,
      onSurface: textPrimaryLight,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: lightSurface.withValues(alpha: 0.9),
      selectedItemColor: primaryPurple,
      unselectedItemColor: textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: const CircleBorder(),
      extendedTextStyle: bodyM.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: bodyM.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryPurple,
        textStyle: bodyM.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      hintStyle: bodyM.copyWith(color: textSecondaryLight),
    ),
    dividerTheme: const DividerThemeData(
      color: lightDivider,
      thickness: 0.5,
      space: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
      ),
      dragHandleColor: textTertiaryLight,
      dragHandleSize: Size(36, 4),
      showDragHandle: true,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: lightPurple,
    colorScheme: ColorScheme.dark(
      primary: lightPurple,
      primaryContainer: darkPurple,
      secondary: primaryPurple,
      secondaryContainer: deepPurple,
      surface: darkSurface,
      surfaceContainerHighest: darkSurfaceElevated,
      error: expenseRed,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: textPrimaryDark,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface.withValues(alpha: 0.9),
      selectedItemColor: lightPurple,
      unselectedItemColor: textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightPurple,
      foregroundColor: Colors.black,
      elevation: 8,
      shape: const CircleBorder(),
      extendedTextStyle: bodyM.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPurple,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: bodyM.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightPurple,
        textStyle: bodyM.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: lightPurple, width: 2),
      ),
      hintStyle: bodyM.copyWith(color: textSecondaryDark),
    ),
    dividerTheme: const DividerThemeData(
      color: darkDivider,
      thickness: 0.5,
      space: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
      ),
      dragHandleColor: textTertiaryDark,
      dragHandleSize: Size(36, 4),
      showDragHandle: true,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // === HELPER METHODS ===
  static Color getTextPrimary(bool isDark) =>
      isDark ? textPrimaryDark : textPrimaryLight;

  static Color getTextSecondary(bool isDark) =>
      isDark ? textSecondaryDark : textSecondaryLight;

  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;

  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color getPrimary(bool isDark) => isDark ? lightPurple : primaryPurple;

  static LinearGradient getPurpleGradient(bool isDark) =>
      isDark ? purpleGradientDark : purpleGradient;
}
