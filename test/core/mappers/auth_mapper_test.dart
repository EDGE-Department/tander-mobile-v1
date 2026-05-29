import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/mappers/auth_mapper.dart';

void main() {
  group('AuthMapper.mapToAuthSession', () {
    test('maps a complete /user/me payload', () {
      final session = AuthMapper.mapToAuthSession(const {
        'userId': 'uuid-abc',
        'email': 'lola@example.com',
        'username': 'lola',
        'registrationPhase': 'COMPLETE',
        'isEmailVerified': true,
        'isIdVerified': true,
        'profilePhotoUrl': 'https://cdn/x.jpg',
      });

      expect(session.userId, 'uuid-abc');
      expect(session.email, 'lola@example.com');
      expect(session.username, 'lola');
      expect(session.registrationPhase, RegistrationPhase.complete);
      expect(session.isEmailVerified, isTrue);
      expect(session.isIdVerified, isTrue);
      expect(session.profilePhotoUrl, 'https://cdn/x.jpg');
    });

    test('prefers canonical userId over legacy numeric id', () {
      final session = AuthMapper.mapToAuthSession(const {
        'userId': 'the-uuid',
        'id': 12345,
      });
      expect(session.userId, 'the-uuid');
    });

    test('falls back to legacy id and stringifies it', () {
      final session = AuthMapper.mapToAuthSession(const {'id': 12345});
      expect(session.userId, '12345');
    });

    test('throws FormatException when no id is present', () {
      expect(
        () => AuthMapper.mapToAuthSession(const {'email': 'x@y.com'}),
        throwsFormatException,
      );
    });

    test('applies safe defaults for absent optional fields', () {
      // Missing email/username become empty strings (not null); a valid token
      // implies prior email verification, so isEmailVerified defaults true.
      final session = AuthMapper.mapToAuthSession(const {'userId': 'u'});

      expect(session.email, '');
      expect(session.username, '');
      expect(session.isEmailVerified, isTrue);
      expect(session.isIdVerified, isFalse);
      expect(session.profilePhotoUrl, isNull);
      // No explicit phase + profileCompleted defaulting true => complete.
      expect(session.registrationPhase, RegistrationPhase.complete);
    });

    test(
      'derives pendingProfileSetup when profileCompleted is false and no phase',
      () {
        final session = AuthMapper.mapToAuthSession(const {
          'userId': 'u',
          'profileCompleted': false,
        });
        expect(
          session.registrationPhase,
          RegistrationPhase.pendingProfileSetup,
        );
      },
    );

    test('an explicit phase overrides profileCompleted derivation', () {
      final session = AuthMapper.mapToAuthSession(const {
        'userId': 'u',
        'profileCompleted': false,
        'registrationPhase': 'PENDING_ID_VERIFICATION',
      });
      expect(
        session.registrationPhase,
        RegistrationPhase.pendingIdVerification,
      );
    });

    test('empty-string email/username collapse to empty defaults', () {
      final session = AuthMapper.mapToAuthSession(const {
        'userId': 'u',
        'email': '',
        'username': '',
      });
      expect(session.email, '');
      expect(session.username, '');
    });

    // Note: _deriveRegistrationPhase wraps fromBackendString in a
    // `catch (ArgumentError)`, but fromBackendString never throws (unknown
    // strings fold to complete). That catch is therefore unreachable defensive
    // code and is intentionally not exercised here.
  });
}
