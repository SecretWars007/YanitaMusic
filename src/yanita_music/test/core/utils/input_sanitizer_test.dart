import 'package:flutter_test/flutter_test.dart';
import 'package:yanita_music/core/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer', () {
    group('sanitizeText', () {
      test('trims whitespace', () {
        expect(InputSanitizer.sanitizeText('  hello  '), equals('hello'));
      });

      test('removes control characters', () {
        expect(
          InputSanitizer.sanitizeText('hello\x00world'),
          equals('helloworld'),
        );
      });

      test('escapes single quotes for SQL safety', () {
        expect(
          InputSanitizer.sanitizeText("it's"),
          equals("it''s"),
        );
      });

      test('limits to 500 characters', () {
        final longString = 'a' * 600;
        final result = InputSanitizer.sanitizeText(longString);
        expect(result.length, equals(500));
      });

      test('handles empty string', () {
        expect(InputSanitizer.sanitizeText(''), equals(''));
      });
    });

    group('sanitizeTitle', () {
      test('allows valid characters including Spanish', () {
        expect(
          InputSanitizer.sanitizeTitle('Canción de Otoño'),
          equals('Canción de Otoño'),
        );
      });

      test('returns "Sin título" for empty result', () {
        expect(
          InputSanitizer.sanitizeTitle('!!!@@@###'),
          equals('Sin título'),
        );
      });
    });

    group('isSafeForQuery', () {
      test('allows normal text', () {
        expect(InputSanitizer.isSafeForQuery('hello world'), isTrue);
      });

      test('rejects SQL injection patterns', () {
        expect(
          InputSanitizer.isSafeForQuery('; DROP TABLE scores'),
          isFalse,
        );
        expect(
          InputSanitizer.isSafeForQuery('UNION SELECT * FROM'),
          isFalse,
        );
      });

      test('rejects SQL comments', () {
        expect(InputSanitizer.isSafeForQuery('value --'), isFalse);
        expect(InputSanitizer.isSafeForQuery('value /* */'), isFalse);
      });
    });
  });
}
