import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/auth/session_manager.dart';

void main() {
  group('RegistrationPhase.fromBackendString', () {
    test('maps canonical SCREAMING_SNAKE_CASE phases', () {
      expect(
        RegistrationPhase.fromBackendString('PENDING_PROFILE_SETUP'),
        RegistrationPhase.pendingProfileSetup,
      );
      expect(
        RegistrationPhase.fromBackendString('PENDING_PHOTO_SETUP'),
        RegistrationPhase.pendingPhotoSetup,
      );
      expect(
        RegistrationPhase.fromBackendString('PENDING_ID_VERIFICATION'),
        RegistrationPhase.pendingIdVerification,
      );
      expect(
        RegistrationPhase.fromBackendString('PENDING_NOTIFICATION_PERMISSION'),
        RegistrationPhase.pendingNotificationPermission,
      );
      expect(
        RegistrationPhase.fromBackendString('COMPLETE'),
        RegistrationPhase.complete,
      );
    });

    test(
      'folds legacy email-verification strings to pendingProfileSetup',
      () {
        // The live backend has no email-verification gate (OTP is verified
        // before account creation), so these legacy strings are remapped to
        // the first real onboarding gate. See session_manager.dart:30-37.
        for (final legacy in const [
          'PENDING_EMAIL_VERIFICATION',
          'email_pending',
          'otp_verified',
          'otp_pending',
          'registered',
          'email_verified',
        ]) {
          expect(
            RegistrationPhase.fromBackendString(legacy),
            RegistrationPhase.pendingProfileSetup,
            reason: '"$legacy" should fold to pendingProfileSetup',
          );
        }
      },
    );

    test('maps lowercase progression aliases', () {
      expect(
        RegistrationPhase.fromBackendString('profile_completed'),
        RegistrationPhase.pendingPhotoSetup,
      );
      expect(
        RegistrationPhase.fromBackendString('id_pre_verified'),
        RegistrationPhase.pendingIdVerification,
      );
      expect(
        RegistrationPhase.fromBackendString('verified'),
        RegistrationPhase.complete,
      );
      expect(
        RegistrationPhase.fromBackendString('VERIFIED'),
        RegistrationPhase.complete,
      );
    });

    test('returns complete for unknown strings (does NOT throw)', () {
      // Pins actual behavior: the docstring claims it throws ArgumentError,
      // but the `_ => complete` default means unknown values fold to complete.
      // Do not "fix" the function to match the docstring without updating this.
      expect(
        RegistrationPhase.fromBackendString('TOTALLY_UNKNOWN_PHASE'),
        RegistrationPhase.complete,
      );
      expect(
        RegistrationPhase.fromBackendString(''),
        RegistrationPhase.complete,
      );
      expect(
        () => RegistrationPhase.fromBackendString('whatever'),
        returnsNormally,
      );
    });

    test('is case-sensitive — wrong casing falls through to complete', () {
      // Only the exact spellings in the switch match; everything else hits the
      // default arm. This documents that, e.g., 'complete' (lowercase) is not
      // a recognised key and therefore also resolves to complete-by-default.
      expect(
        RegistrationPhase.fromBackendString('pending_profile_setup'),
        RegistrationPhase.complete,
      );
    });
  });
}
