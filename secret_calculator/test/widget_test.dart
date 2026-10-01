// Basic unit tests for the calculator's pure display helpers.

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_calculator/pages/homepage.dart';

void main() {
  group('formatString', () {
    test('returns "0" for an empty string', () {
      expect(formatString(''), '0');
    });

    test('replaces * with x and / with the division sign', () {
      expect(formatString('6*7'), '6x7');
      expect(formatString('8/2'), '8÷2');
    });

    test('leaves plain digits, operators and decimals untouched', () {
      expect(formatString('12+3.5'), '12+3.5');
    });
  });
}