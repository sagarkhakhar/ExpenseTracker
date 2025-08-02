// This file defines the application's theme configuration and design system.
// It provides consistent styling across the app with support for light and dark modes.
// This demonstrates proper theme management and design system implementation.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants/app_constants.dart';

/// Application theme configuration that provides consistent styling.
/// Supports both light and dark modes with platform-appropriate design.
class AppTheme {
  // Private constructor to prevent instantiation (utility class)
  AppTheme._();

  /// Light theme configuration for the application.
  /// Uses bright colors and high contrast for daytime use.
  static ThemeData get lightTheme {
    return ThemeData(
      // Use Material 3 design system
      useMaterial3: true,

      // Bright color scheme for light mode
      brightness: Brightness.light,

      // Primary color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConstants.primaryColor),
        brightness: Brightness.light,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConstants.surfaceColor),
        foregroundColor: Color(AppConstants.textColorPrimary),
        elevation: AppConstants.shadowS,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w600,
          color: Color(AppConstants.textColorPrimary),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: AppConstants.shadowS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        color: const Color(AppConstants.surfaceColor),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          elevation: AppConstants.shadowS,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.textSizeM,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(AppConstants.primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.textSizeM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppConstants.primaryColor),
          side: const BorderSide(
            color: Color(AppConstants.primaryColor),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.textSizeM,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: AppConstants.shadowM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColor),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: Color(AppConstants.errorColor),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingM,
        ),
        labelStyle: const TextStyle(
          fontSize: AppConstants.textSizeM,
          color: Color(AppConstants.textColorSecondary),
        ),
        hintStyle: const TextStyle(
          fontSize: AppConstants.textSizeM,
          color: Color(AppConstants.textColorSecondary),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppConstants.textSizeXXL,
          fontWeight: FontWeight.bold,
          color: Color(AppConstants.textColorPrimary),
        ),
        displayMedium: TextStyle(
          fontSize: AppConstants.textSizeXL,
          fontWeight: FontWeight.bold,
          color: Color(AppConstants.textColorPrimary),
        ),
        displaySmall: TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.bold,
          color: Color(AppConstants.textColorPrimary),
        ),
        headlineLarge: TextStyle(
          fontSize: AppConstants.textSizeXL,
          fontWeight: FontWeight.w600,
          color: Color(AppConstants.textColorPrimary),
        ),
        headlineMedium: TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w600,
          color: Color(AppConstants.textColorPrimary),
        ),
        headlineSmall: TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.w600,
          color: Color(AppConstants.textColorPrimary),
        ),
        titleLarge: TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w500,
          color: Color(AppConstants.textColorPrimary),
        ),
        titleMedium: TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.w500,
          color: Color(AppConstants.textColorPrimary),
        ),
        titleSmall: TextStyle(
          fontSize: AppConstants.textSizeS,
          fontWeight: FontWeight.w500,
          color: Color(AppConstants.textColorPrimary),
        ),
        bodyLarge: TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.normal,
          color: Color(AppConstants.textColorPrimary),
        ),
        bodyMedium: TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.normal,
          color: Color(AppConstants.textColorPrimary),
        ),
        bodySmall: TextStyle(
          fontSize: AppConstants.textSizeS,
          fontWeight: FontWeight.normal,
          color: Color(AppConstants.textColorSecondary),
        ),
        labelLarge: TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.w500,
          color: Color(AppConstants.textColorPrimary),
        ),
        labelMedium: TextStyle(
          fontSize: AppConstants.textSizeS,
          fontWeight: FontWeight.w500,
          color: Color(AppConstants.textColorPrimary),
        ),
        labelSmall: TextStyle(
          fontSize: AppConstants.textSizeXS,
          fontWeight: FontWeight.w500,
          color: Color(AppConstants.textColorSecondary),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Color(AppConstants.textColorPrimary),
        size: AppConstants.iconSizeM,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: AppConstants.paddingM,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(AppConstants.surfaceColor),
        selectedItemColor: Color(AppConstants.primaryColor),
        unselectedItemColor: Color(AppConstants.textColorSecondary),
        type: BottomNavigationBarType.fixed,
        elevation: AppConstants.shadowM,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: const Color(AppConstants.surfaceColor),
        elevation: AppConstants.shadowL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        titleTextStyle: const TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w600,
          color: Color(AppConstants.textColorPrimary),
        ),
        contentTextStyle: const TextStyle(
          fontSize: AppConstants.textSizeM,
          color: Color(AppConstants.textColorPrimary),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(AppConstants.textColorPrimary),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: AppConstants.textSizeM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(AppConstants.primaryColor),
        labelStyle: const TextStyle(
          fontSize: AppConstants.textSizeS,
          color: Color(AppConstants.textColorPrimary),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }

  /// Dark theme configuration for the application.
  /// Uses dark colors and lower contrast for nighttime use.
  static ThemeData get darkTheme {
    return ThemeData(
      // Use Material 3 design system
      useMaterial3: true,

      // Dark color scheme for dark mode
      brightness: Brightness.dark,

      // Primary color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConstants.primaryColor),
        brightness: Brightness.dark,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: AppConstants.shadowS,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: AppConstants.shadowS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        color: Colors.grey[850],
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          elevation: AppConstants.shadowS,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.textSizeM,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(AppConstants.primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.textSizeM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppConstants.primaryColor),
          side: const BorderSide(
            color: Color(AppConstants.primaryColor),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.textSizeM,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: AppConstants.shadowM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: Colors.grey[600]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: Colors.grey[600]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColor),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: Color(AppConstants.errorColor),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingM,
        ),
        labelStyle: TextStyle(
          fontSize: AppConstants.textSizeM,
          color: Colors.grey[400],
        ),
        hintStyle: TextStyle(
          fontSize: AppConstants.textSizeM,
          color: Colors.grey[400],
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: AppConstants.textSizeXXL,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: const TextStyle(
          fontSize: AppConstants.textSizeXL,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: const TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: const TextStyle(
          fontSize: AppConstants.textSizeXL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: const TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: const TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: const TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: const TextStyle(
          fontSize: AppConstants.textSizeS,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: const TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: const TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontSize: AppConstants.textSizeS,
          fontWeight: FontWeight.normal,
          color: Colors.grey[400],
        ),
        labelLarge: const TextStyle(
          fontSize: AppConstants.textSizeM,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: const TextStyle(
          fontSize: AppConstants.textSizeS,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontSize: AppConstants.textSizeXS,
          fontWeight: FontWeight.w500,
          color: Colors.grey[400],
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: AppConstants.iconSizeM,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[700],
        thickness: 1,
        space: AppConstants.paddingM,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: const Color(AppConstants.primaryColor),
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: AppConstants.shadowM,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.grey[850],
        elevation: AppConstants.shadowL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        titleTextStyle: const TextStyle(
          fontSize: AppConstants.textSizeL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontSize: AppConstants.textSizeM,
          color: Colors.white,
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800],
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: AppConstants.textSizeM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800],
        selectedColor: const Color(AppConstants.primaryColor),
        labelStyle: const TextStyle(
          fontSize: AppConstants.textSizeS,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }

  /// Gets the appropriate theme based on the current brightness.
  /// Automatically selects light or dark theme based on system preference.
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Gets the appropriate Cupertino theme for iOS-style widgets.
  /// Provides consistent iOS styling when using Cupertino widgets.
  static CupertinoThemeData getCupertinoTheme(Brightness brightness) {
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: const Color(AppConstants.primaryColor),
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? CupertinoColors.systemBackground.darkColor
          : CupertinoColors.systemBackground,
      barBackgroundColor: brightness == Brightness.dark
          ? CupertinoColors.systemBackground.darkColor
          : CupertinoColors.systemBackground,
      textTheme: CupertinoTextThemeData(
        primaryColor: const Color(AppConstants.primaryColor),
        textStyle: TextStyle(
          fontSize: AppConstants.textSizeM,
          color: brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
        actionTextStyle: const TextStyle(
          fontSize: AppConstants.textSizeM,
          color: Color(AppConstants.primaryColor),
        ),
        tabLabelTextStyle: TextStyle(
          fontSize: AppConstants.textSizeS,
          color: brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
    );
  }
}
