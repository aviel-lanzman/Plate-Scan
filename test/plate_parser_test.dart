import 'package:flutter_test/flutter_test.dart';
import 'package:plate_scan/services/plate_parser.dart';

void main() {
  group('PlateParser.parseLine', () {
    test('reads 7 and 8 digit plates with separators', () {
      expect(PlateParser.parseLine('12-345-67'), '1234567');
      expect(PlateParser.parseLine('123-45-678'), '12345678');
      expect(PlateParser.parseLine('12 345 67'), '1234567');
      expect(PlateParser.parseLine('123.45.678'), '12345678');
      expect(PlateParser.parseLine('1234567'), '1234567');
    });

    test('drops the IL country strip', () {
      expect(PlateParser.parseLine('IL 12-345-67'), '1234567');
      expect(PlateParser.parseLine('IL12-345-67'), '1234567');
      expect(PlateParser.parseLine('1L 123-45-678'), '12345678');
      expect(PlateParser.parseLine('123-45-678 IL'), '12345678');
    });

    test('fixes common OCR letter/digit confusions', () {
      expect(PlateParser.parseLine('I2-345-6O'), '1234560');
      expect(PlateParser.parseLine('12-3S5-67'), '1235567');
    });

    test('rejects text that is not a plate', () {
      expect(PlateParser.parseLine('123456'), isNull); // too short
      expect(PlateParser.parseLine('123456789'), isNull); // too long
      expect(PlateParser.parseLine('HELLO'), isNull);
      expect(PlateParser.parseLine('ISRAEL'), isNull);
      expect(PlateParser.parseLine(''), isNull);
      // Too many substitutions to trust.
      expect(PlateParser.parseLine('IO-SOS-67'), isNull);
    });

    test('extract returns distinct plates across lines', () {
      expect(
        PlateParser.extract([
          'IL',
          '12-345-67',
          'garage',
          '12-345-67',
          '123-45-678',
        ]),
        ['1234567', '12345678'],
      );
    });
  });

  group('formatPlate', () {
    test('formats by length', () {
      expect(formatPlate('1234567'), '12-345-67');
      expect(formatPlate('12345678'), '123-45-678');
      expect(formatPlate('12345'), '12345');
    });
  });

  test('normalizePlate and isValidPlate', () {
    expect(normalizePlate(' 12-345-67 '), '1234567');
    expect(isValidPlate('1234567'), isTrue);
    expect(isValidPlate('123'), isFalse);
    expect(isValidPlate('123456789'), isFalse);
  });

  group('PlateVoter', () {
    test('confirms a plate only after the threshold', () {
      final voter = PlateVoter(window: 6, threshold: 3);
      expect(voter.add(['1234567']), isEmpty);
      expect(voter.add(['1234561']), isEmpty); // misread
      expect(voter.add(['1234567']), isEmpty);
      expect(voter.add(['1234567']), ['1234567']);
    });

    test('forgets frames outside the window', () {
      final voter = PlateVoter(window: 3, threshold: 2);
      voter.add(['1234567']);
      voter.add([]);
      voter.add([]);
      expect(voter.add(['1234567']), isEmpty);
    });

    test('counts a plate once per frame and can confirm several', () {
      final voter = PlateVoter(window: 4, threshold: 2);
      voter.add(['1234567', '1234567', '7654321']);
      expect(
        voter.add(['1234567', '7654321']),
        unorderedEquals(['1234567', '7654321']),
      );
    });

    test('reset clears history', () {
      final voter = PlateVoter(window: 6, threshold: 2)..add(['1234567']);
      voter.reset();
      expect(voter.add(['1234567']), isEmpty);
    });
  });
}
