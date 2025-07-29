// This file provides utility functions for currency formatting and number handling.
// It ensures consistent currency display across the app and handles different locales.
// This demonstrates proper utility function organization and internationalization support.

import 'package:intl/intl.dart';

/// Utility class for currency formatting and number handling.
/// Provides consistent currency display across different locales and formats.
class CurrencyUtils {
  // Private constructor to prevent instantiation (utility class)
  CurrencyUtils._();

  /// Formats a currency amount with proper locale-specific formatting.
  /// Uses the device's locale to determine currency symbol and formatting.
  ///
  /// Example:
  /// - US: $1,234.56
  /// - EU: €1.234,56
  /// - UK: £1,234.56
  static String formatCurrency(double amount) {
    // Use NumberFormat.simpleCurrency to get locale-appropriate formatting
    final formatter = NumberFormat.simpleCurrency();
    return formatter.format(amount);
  }

  /// Formats a currency amount with abbreviated notation for large numbers.
  /// Useful for displaying large amounts in a compact format.
  ///
  /// Examples:
  /// - 1,234 → $1.23K
  /// - 1,234,567 → $1.23M
  /// - 1,234,567,890 → $1.23B
  static String formatAbbreviatedCurrency(double amount) {
    if (amount.abs() < 1000) {
      // For amounts less than 1000, use regular formatting
      return formatCurrency(amount);
    } else if (amount.abs() < 1000000) {
      // For thousands, format as K
      final thousands = amount / 1000;
      return '${formatCurrency(thousands)}K';
    } else if (amount.abs() < 1000000000) {
      // For millions, format as M
      final millions = amount / 1000000;
      return '${formatCurrency(millions)}M';
    } else {
      // For billions, format as B
      final billions = amount / 1000000000;
      return '${formatCurrency(billions)}B';
    }
  }

  /// Formats a percentage value with proper decimal places.
  /// Ensures consistent percentage display across the app.
  ///
  /// Example: 0.1234 → "12.34%"
  static String formatPercentage(double value) {
    // Convert decimal to percentage and format with 2 decimal places
    final percentage = value * 100;
    return '${percentage.toStringAsFixed(2)}%';
  }

  /// Parses a string to a double, handling common currency formatting.
  /// Removes currency symbols and formatting characters before parsing.
  ///
  /// Returns null if the string cannot be parsed as a valid number.
  static double? parseCurrency(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Remove common currency symbols and formatting characters
    final cleaned = value
        .replaceAll(
            RegExp(r'[^\d.-]'), '') // Keep only digits, dots, and minus signs
        .trim();

    if (cleaned.isEmpty) {
      return null;
    }

    // Try to parse the cleaned string
    final parsed = double.tryParse(cleaned);
    return parsed;
  }

  /// Validates if a string represents a valid currency amount.
  /// Checks for proper number format and reasonable range.
  ///
  /// Returns true if the string is a valid currency amount.
  static bool isValidCurrency(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final amount = parseCurrency(value);
    if (amount == null) {
      return false;
    }

    // Check for reasonable range (not too large or negative)
    if (amount < 0 || amount > 1000000000) {
      // 1 billion max
      return false;
    }

    return true;
  }

  /// Formats a number with thousands separators for better readability.
  /// Uses locale-appropriate separators (comma for US, dot for EU, etc.).
  ///
  /// Example: 1234567 → "1,234,567"
  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(number);
  }

  /// Formats a number with a specific number of decimal places.
  /// Useful for displaying precise values like percentages or ratios.
  ///
  /// Example: formatDecimal(3.14159, 2) → "3.14"
  static String formatDecimal(double number, int decimalPlaces) {
    return number.toStringAsFixed(decimalPlaces);
  }

  /// Converts a number to a human-readable string with appropriate units.
  /// Useful for displaying file sizes, distances, or other measurements.
  ///
  /// Examples:
  /// - 1024 → "1.0 KB"
  /// - 1048576 → "1.0 MB"
  /// - 1073741824 → "1.0 GB"
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Rounds a number to a specified number of decimal places.
  /// Useful for financial calculations where precision is important.
  ///
  /// Example: roundToDecimal(3.14159, 2) → 3.14
  static double roundToDecimal(double number, int decimalPlaces) {
    final factor = 10.0 * decimalPlaces;
    return (number * factor).round() / factor;
  }

  /// Calculates the percentage change between two values.
  /// Useful for showing growth or decline in financial data.
  ///
  /// Example: calculatePercentageChange(100, 120) → 20.0
  static double calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) {
      return newValue > 0 ? 100.0 : 0.0;
    }
    return ((newValue - oldValue) / oldValue) * 100;
  }

  /// Formats a range of values (min to max) in a readable format.
  /// Useful for displaying price ranges or data ranges.
  ///
  /// Example: formatRange(10.5, 25.75) → "$10.50 - $25.75"
  static String formatRange(double min, double max) {
    return '${formatCurrency(min)} - ${formatCurrency(max)}';
  }

  /// Checks if a number is within a specified range.
  /// Useful for validation and boundary checking.
  ///
  /// Returns true if the number is within the inclusive range.
  static bool isInRange(double number, double min, double max) {
    return number >= min && number <= max;
  }

  /// Clamps a number to a specified range.
  /// Ensures the number stays within valid bounds.
  ///
  /// Example: clamp(15, 0, 10) → 10
  static double clamp(double number, double min, double max) {
    if (number < min) return min;
    if (number > max) return max;
    return number;
  }
}
