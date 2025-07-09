import 'package:intl/intl.dart';

class CurrencyUtils {
  static String formatCurrency(double amount, {String currencyCode = 'USD'}) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCompactCurrency(
    double amount, {
    String currencyCode = 'USD',
  }) {
    final formatter = NumberFormat.compactCurrency(
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      default:
        return '\$';
    }
  }

  static double parseCurrency(String amount) {
    // Remove currency symbols and commas
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleanAmount) ?? 0.0;
  }

  static String getPercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return '0%';

    final change = ((newValue - oldValue) / oldValue) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  static bool isPositive(double amount) {
    return amount > 0;
  }

  static bool isNegative(double amount) {
    return amount < 0;
  }

  static bool isZero(double amount) {
    return amount == 0;
  }

  static String formatAbbreviatedCurrency(double amount) {
    if (amount.abs() >= 1e9) {
      return ' ${(amount / 1e9).toStringAsFixed(2)}B';
    } else if (amount.abs() >= 1e6) {
      return ' ${(amount / 1e6).toStringAsFixed(2)}M';
    } else if (amount.abs() >= 1e3) {
      return ' ${(amount / 1e3).toStringAsFixed(2)}K';
    } else {
      return formatCurrency(amount);
    }
  }
}
