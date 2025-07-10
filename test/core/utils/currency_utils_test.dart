import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils', () {
    test('formatCurrency returns correct string for USD', () {
      expect(CurrencyUtils.formatCurrency(1234.56), ' 21,234.56');
    });
    test('formatCurrency returns correct string for EUR', () {
      expect(CurrencyUtils.formatCurrency(1234.56, currencyCode: 'EUR'),
          '€1,234.56');
    });
    test('formatCompactCurrency returns compact string', () {
      expect(CurrencyUtils.formatCompactCurrency(1234567), ' 21.2M');
    });
    test('parseCurrency parses formatted string', () {
      expect(CurrencyUtils.parseCurrency(' 21,234.56'), 1234.56);
      expect(CurrencyUtils.parseCurrency('€1,234.56'), 1234.56);
    });
    test('getPercentageChange returns correct string', () {
      expect(CurrencyUtils.getPercentageChange(100, 120), '+20.0%');
      expect(CurrencyUtils.getPercentageChange(100, 80), '-20.0%');
      expect(CurrencyUtils.getPercentageChange(0, 80), '0%');
    });
    test('isPositive, isNegative, isZero', () {
      expect(CurrencyUtils.isPositive(5), true);
      expect(CurrencyUtils.isNegative(-5), true);
      expect(CurrencyUtils.isZero(0), true);
    });
    test('formatAbbreviatedCurrency returns correct abbreviation', () {
      expect(CurrencyUtils.formatAbbreviatedCurrency(1e9), ' 1.00B');
      expect(CurrencyUtils.formatAbbreviatedCurrency(1e6), ' 1.00M');
      expect(CurrencyUtils.formatAbbreviatedCurrency(1e3), ' 1.00K');
      expect(CurrencyUtils.formatAbbreviatedCurrency(123), ' 2123.00');
    });
  });
}
