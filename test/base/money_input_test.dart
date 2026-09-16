import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// Money fields are the one place in this app where a parsing slip is
/// invisible and permanent: a bare `double.tryParse('1,000') ?? 0` records
/// zero collected against a real invoice and nobody finds out until the
/// account is reconciled. These tests pin both halves of the contract — what
/// can be typed, and how it is read back.

/// Run [formatter] over [keystrokes] one character at a time, the way a real
/// field receives them. Typing the finished string in one go is a different
/// code path and would not catch a formatter that eats a keystroke.
String _type(TextInputFormatter formatter, String keystrokes) {
  var value = TextEditingValue.empty;
  for (final ch in keystrokes.split('')) {
    final next = TextEditingValue(
      text: value.text + ch,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    value = formatter.formatEditUpdate(value, next);
  }
  return value.text;
}

void main() {
  group('BFormatter.parseAmount', () {
    test('reads a plain number', () {
      expect(BFormatter.parseAmount('1000'), 1000);
      expect(BFormatter.parseAmount('37759.82'), 37759.82);
    });

    test('reads a grouped number, which is what the field displays', () {
      expect(BFormatter.parseAmount('1,000'), 1000);
      expect(BFormatter.parseAmount('37,759.82'), 37759.82);
    });

    test('reads a number carrying a peso sign or spaces', () {
      expect(BFormatter.parseAmount('₱ 1,000.50'), 1000.50);
      expect(BFormatter.parseAmount('  250  '), 250);
    });

    test('is zero for nothing at all', () {
      expect(BFormatter.parseAmount(''), 0);
      expect(BFormatter.parseAmount(null), 0);
      expect(BFormatter.parseAmount('   '), 0);
      expect(BFormatter.parseAmount('abc'), 0);
      expect(BFormatter.parseAmount('.'), 0);
    });

    test('a leading decimal point is centavos, not zero', () {
      expect(BFormatter.parseAmount('.5'), 0.5);
    });

    test('an extra decimal point does not move the decimal place', () {
      // The magnitude is what matters here: 12.345 would be a tenfold error
      // on a field where one stray keystroke is easy.
      expect(BFormatter.parseAmount('12.34.5'), 12.34);
      expect(BFormatter.parseAmount('1.2.3.4'), 1.2);
    });

    test('round-trips what formatPesoCurrency produced', () {
      for (final amount in [0.0, 1.05, 250.0, 37759.82, 1234567.89]) {
        expect(
          BFormatter.parseAmount(BFormatter.formatPesoCurrency(amount)),
          closeTo(amount, 0.001),
          reason: 'the displayed figure must read back as itself',
        );
      }
    });
  });

  group('ThousandsSeparatorInputFormatter', () {
    test('groups digits as they are typed', () {
      expect(_type(ThousandsSeparatorInputFormatter(), '1000'), '1,000');
      expect(
          _type(ThousandsSeparatorInputFormatter(), '3775982'), '3,775,982');
    });

    test('centavos can actually be typed', () {
      // The point used to be swallowed the instant it was typed, because the
      // formatter only emitted it once there were digits after it — so no
      // amount on these screens could carry centavos.
      expect(_type(ThousandsSeparatorInputFormatter(), '12.'), '12.');
      expect(_type(ThousandsSeparatorInputFormatter(), '37759.82'),
          '37,759.82');
    });

    test('letters and symbols cannot be entered', () {
      expect(_type(ThousandsSeparatorInputFormatter(), r'₱1a2b3'), '123');
    });

    test('a second decimal point is dropped rather than shifting the value',
        () {
      expect(_type(ThousandsSeparatorInputFormatter(), '12.34.5'), '12.34');
    });

    test('stops at two decimal places', () {
      expect(_type(ThousandsSeparatorInputFormatter(), '12.3456'), '12.34');
    });

    test('everything it accepts, parseAmount reads back', () {
      for (final keystrokes in ['1000', '37759.82', '0.05', '1234567.89']) {
        final displayed = _type(ThousandsSeparatorInputFormatter(), keystrokes);
        expect(
          BFormatter.parseAmount(displayed),
          double.parse(keystrokes),
          reason: 'typed $keystrokes, displayed $displayed',
        );
      }
    });
  });
}
