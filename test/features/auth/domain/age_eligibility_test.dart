import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/domain/age_eligibility.dart';

/// Unit guards for the trap-critical age logic. Pure (no widget/provider
/// scaffolding) so the fail-open + boundary behaviour is tested directly —
/// these are the load-bearing decisions behind the age-verification fix.
void main() {
  group('ageInYears', () {
    final birthDate = DateTime(2000, 6, 15);

    test('the day before the birthday counts the prior year', () {
      expect(ageInYears(birthDate, DateTime(2026, 6, 14)), 25);
    });

    test('on the birthday itself counts inclusively (Nth birthday => N)', () {
      // The critical boundary: a strict > would re-trap an exactly-eligible
      // person whose birthday is today.
      expect(ageInYears(birthDate, DateTime(2026, 6, 15)), 26);
    });

    test('the day after the birthday counts the new year', () {
      expect(ageInYears(birthDate, DateTime(2026, 6, 16)), 26);
    });

    test('a later month in the year counts as having had the birthday', () {
      expect(ageInYears(birthDate, DateTime(2026, 7, 1)), 26);
    });

    test('an earlier month counts the prior year', () {
      expect(ageInYears(birthDate, DateTime(2026, 5, 31)), 25);
    });

    group('Feb-29 birthday evaluated in a non-leap year', () {
      final leapBirthday = DateTime(2004, 2, 29);

      test('Feb-28 (before the notional birthday) counts the prior year', () {
        expect(ageInYears(leapBirthday, DateTime(2026, 2, 28)), 21);
      });

      test('Mar-1 (after the notional birthday) counts the new year', () {
        expect(ageInYears(leapBirthday, DateTime(2026, 3, 1)), 22);
      });
    });
  });

  group('isBirthDateBelowMinimum', () {
    final asOf = DateTime(2026, 6, 15);

    test('FAILS OPEN (false) when the minimum is unknown (null)', () {
      // Even a clearly-young DOB is not blocked when the backend minimum is
      // unknown — the backend ID gate is the real enforcer.
      expect(
        isBirthDateBelowMinimum(
          birthDate: DateTime(2020, 1, 1),
          minimumAge: null,
          asOf: asOf,
        ),
        isFalse,
      );
    });

    test('blocks a DOB below the minimum', () {
      expect(
        isBirthDateBelowMinimum(
          birthDate: DateTime(2007, 6, 15), // age 19 on asOf
          minimumAge: 20,
          asOf: asOf,
        ),
        isTrue,
      );
    });

    test('does NOT block a DOB exactly at the minimum (birthday today)', () {
      expect(
        isBirthDateBelowMinimum(
          birthDate: DateTime(2006, 6, 15), // turns 20 on asOf
          minimumAge: 20,
          asOf: asOf,
        ),
        isFalse,
      );
    });

    test('does NOT block a DOB above the minimum', () {
      expect(
        isBirthDateBelowMinimum(
          birthDate: DateTime(1990, 6, 15),
          minimumAge: 20,
          asOf: asOf,
        ),
        isFalse,
      );
    });
  });

  group('pickerAgeFloor', () {
    test('falls back to the permissive floor (18) when minimum is unknown', () {
      expect(pickerAgeFloor(null), permissivePickerAgeFloor);
      expect(pickerAgeFloor(null), 18);
    });

    test('uses the backend minimum when known', () {
      expect(pickerAgeFloor(20), 20);
      expect(pickerAgeFloor(60), 60);
    });
  });
}
