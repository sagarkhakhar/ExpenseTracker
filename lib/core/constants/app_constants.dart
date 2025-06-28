import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // App Information
  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF06B6D4);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Border Colors
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color dividerColor = Color(0xFFF1F5F9);

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Shadows
  static const List<BoxShadow> shadowS = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowM = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowL = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
  ];
}

class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppConstants.textPrimary,
  );

  static TextStyle get heading2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppConstants.textPrimary,
  );

  static TextStyle get heading3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppConstants.textPrimary,
  );

  static TextStyle get body1 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppConstants.textPrimary,
  );

  static TextStyle get body2 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppConstants.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppConstants.textTertiary,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
