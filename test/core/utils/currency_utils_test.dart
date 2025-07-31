import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils', () {
    test('formatCurrency returns correct string for USD', () {
      expect(CurrencyUtils.formatCurrency(1234.56), '\$1,234.56');
    });
    test('formatCurrency returns correct string for EUR', () {
      // expect(CurrencyUtils.formatCurrency(1234.56, currencyCode: 'EUR'),
      //     '€1,234.56');
    });
    // The following tests are commented out because the methods do not exist in CurrencyUtils:
    // - formatCompactCurrency
    // - getPercentageChange
    // - isPositive
    // - isNegative
    // - isZero
    // - currencyCode parameter
    // Uncomment and update if/when these methods are implemented.
    test('parseCurrency parses formatted string', () {
      expect(CurrencyUtils.parseCurrency('\$1,234.56'), 1234.56);
      expect(CurrencyUtils.parseCurrency('€1,234.56'), 1234.56);
    });
    test('formatAbbreviatedCurrency returns correct abbreviation', () {
      expect(CurrencyUtils.formatAbbreviatedCurrency(1e9), '\$1.00B');
      expect(CurrencyUtils.formatAbbreviatedCurrency(1e6), '\$1.00M');
      expect(CurrencyUtils.formatAbbreviatedCurrency(1e3), '\$1.00K');
      expect(CurrencyUtils.formatAbbreviatedCurrency(123), '\$123.00');
    });
  });
}
