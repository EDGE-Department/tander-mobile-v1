import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/shared/utils/validators.dart';

void main() {
  group('Validators.firstName / lastName', () {
    test('rejects null, empty, and whitespace-only', () {
      expect(Validators.firstName(null), isNotNull);
      expect(Validators.firstName(''), isNotNull);
      expect(Validators.firstName('   '), isNotNull);
    });

    test('rejects single-character names', () {
      expect(Validators.firstName('A'), isNotNull);
    });

    test('rejects digits and disallowed symbols', () {
      expect(Validators.firstName('Jo3'), isNotNull);
      expect(Validators.lastName('Smith@'), isNotNull);
    });

    test('accepts accented, hyphenated, and apostrophe names', () {
      // The regex permits apostrophes even though the error copy omits them —
      // pin the real behavior so a copy/regex change is deliberate.
      expect(Validators.firstName('José'), isNull);
      expect(Validators.lastName("O'Brien"), isNull);
      expect(Validators.lastName('Dela-Cruz'), isNull);
      expect(Validators.firstName('Ma. Concepcion'), isNull);
    });

    test('trims before length check', () {
      expect(Validators.firstName('  Al  '), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects null/empty and malformed addresses', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a@b.c'), isNotNull); // TLD needs 2+ chars
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('lola@example.com'), isNull);
      expect(Validators.email('a.b+tag@sub.domain.co'), isNull);
    });

    test('does NOT trim — leading whitespace is invalid', () {
      // Unlike firstName/lastName, email is not trimmed. Pin this so a future
      // "add trim" change is a conscious decision.
      expect(Validators.email(' lola@example.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('rejects null/empty', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('rejects under 8 characters (boundary)', () {
      expect(Validators.password('Abc1234'), isNotNull); // 7
      expect(Validators.password('Abcd1234'), isNull); // 8
    });

    test('requires an uppercase letter and a digit', () {
      expect(Validators.password('lowercase1'), isNotNull); // no uppercase
      expect(Validators.password('NoDigitsHere'), isNotNull); // no digit
    });

    test('accepts a compliant password', () {
      expect(Validators.password('Sunshine9'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects null/empty', () {
      expect(Validators.confirmPassword(null, 'x'), isNotNull);
      expect(Validators.confirmPassword('', 'x'), isNotNull);
    });

    test('rejects a mismatch and accepts an exact match', () {
      expect(Validators.confirmPassword('abc', 'abd'), isNotNull);
      expect(Validators.confirmPassword('Secret1A', 'Secret1A'), isNull);
    });
  });

  group('Validators.otp', () {
    test('rejects null/empty', () {
      expect(Validators.otp(null), isNotNull);
      expect(Validators.otp(''), isNotNull);
    });

    test('rejects wrong length and non-digits', () {
      expect(Validators.otp('12345'), isNotNull); // 5
      expect(Validators.otp('1234567'), isNotNull); // 7
      expect(Validators.otp('12345a'), isNotNull); // non-digit
    });

    test('accepts exactly six digits', () {
      expect(Validators.otp('123456'), isNull);
    });
  });
}
