import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/shared/utils/first_name_extractor.dart';

void main() {
  group('extractFirstName', () {
    test('returns first word from multi-word username', () {
      expect(extractFirstName('Maria Santos'), 'Maria');
    });

    test('returns whole token when username has no space', () {
      expect(extractFirstName('Maria'), 'Maria');
    });

    test('returns "friend" for null', () {
      expect(extractFirstName(null), 'friend');
    });

    test('returns "friend" for empty string', () {
      expect(extractFirstName(''), 'friend');
    });

    test('returns "friend" for whitespace-only input', () {
      expect(extractFirstName('   '), 'friend');
      expect(extractFirstName('\t\n  '), 'friend');
    });

    test('caps at 24 characters', () {
      expect(extractFirstName('a' * 30), 'a' * 24);
    });

    test('handles leading/trailing whitespace', () {
      expect(extractFirstName('  Maria  '), 'Maria');
    });

    test('handles tabs and newlines between tokens', () {
      expect(extractFirstName('Maria\tSantos'), 'Maria');
      expect(extractFirstName('Maria\nSantos'), 'Maria');
    });

    test('preserves hyphenated first names', () {
      expect(extractFirstName('Mary-Elena Santos'), 'Mary-Elena');
    });
  });
}
