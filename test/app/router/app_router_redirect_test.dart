import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/app/router/app_router.dart';
import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Regression guards for the redirect guard's two trap-class fixes:
///  - AuthError must NOT be treated as a logout (a transient bootstrap/refresh
///    failure on splash previously force-logged-out a valid session).
///  - Onboarding phases that map to `home` must NOT return `AppRoutes.home`
///    off-splash — that looped (`/` -> `/discover` while the state stays
///    AuthOnboarding) until GoRouter bailed to the 404 screen.
AuthSession _session(RegistrationPhase phase) => AuthSession(
  userId: 'u1',
  registrationPhase: phase,
  isEmailVerified: true,
  isIdVerified: true,
);

void main() {
  group('AuthError is not a logout', () {
    const err = AuthError(exception: NetworkException(message: 'boot failed'));

    test('on splash stays on splash (does NOT force login)', () {
      expect(redirectForTest(err, AppRoutes.splash), isNull);
    });

    test('on a public route stays put', () {
      expect(redirectForTest(err, AppRoutes.login), isNull);
    });

    test('on a protected route goes to splash, never login', () {
      expect(redirectForTest(err, AppRoutes.discover), AppRoutes.splash);
    });
  });

  group('onboarding loop prevention (home-mapped phases)', () {
    final onboarding = AuthOnboarding(
      phase: RegistrationPhase.pendingNotificationPermission,
      session: _session(RegistrationPhase.pendingNotificationPermission),
    );

    test('off-splash returns null (no /home -> /discover -> 404 loop)', () {
      expect(redirectForTest(onboarding, AppRoutes.discover), isNull);
    });

    test('from splash lands on discover (the real tab, not /home)', () {
      expect(redirectForTest(onboarding, AppRoutes.splash), AppRoutes.discover);
    });
  });

  group('onboarding step phases route to their step', () {
    final profileSetup = AuthOnboarding(
      phase: RegistrationPhase.pendingProfileSetup,
      session: _session(RegistrationPhase.pendingProfileSetup),
    );

    test('off the onboarding route routes to profile setup', () {
      expect(
        redirectForTest(profileSetup, AppRoutes.splash),
        AppRoutes.profileSetup,
      );
    });

    test('already on profile setup stays (null)', () {
      expect(redirectForTest(profileSetup, AppRoutes.profileSetup), isNull);
    });
  });

  group('unauthenticated', () {
    const unauth = AuthUnauthenticated();

    test('protected route -> login', () {
      expect(redirectForTest(unauth, AppRoutes.discover), AppRoutes.login);
    });

    test('public route -> null', () {
      expect(redirectForTest(unauth, AppRoutes.login), isNull);
    });
  });

  group('authenticated', () {
    final auth = AuthAuthenticated(
      session: _session(RegistrationPhase.complete),
    );

    test('on splash/public -> discover', () {
      expect(redirectForTest(auth, AppRoutes.splash), AppRoutes.discover);
    });

    test('on a normal route -> null', () {
      expect(redirectForTest(auth, AppRoutes.discover), isNull);
    });
  });
}
