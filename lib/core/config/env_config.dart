enum AppEnvironment { dev, staging, production }

final class EnvConfig {
  const EnvConfig._();

  // Defaults to production so a stock release/profile build points at the
  // live Azure Container App. Override via `--dart-define=APP_ENV=dev` to
  // hit the host machine through `adb reverse tcp:8080 tcp:8080`.
  static AppEnvironment _current = _envFromString(
    const String.fromEnvironment('APP_ENV', defaultValue: 'production'),
  );

  static AppEnvironment get current => _current;

  static void initialize(AppEnvironment environment) {
    _current = environment;
  }

  static AppEnvironment _envFromString(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
      default:
        return AppEnvironment.production;
    }
  }

  // Production points at the new Java 21 / Spring Boot backend on Azure
  // Container Apps (revision tander-backend--v3c at the time of writing).
  // Dev keeps the old localhost flow — `adb reverse tcp:8080 tcp:8080`
  // forwards the device's 127.0.0.1:8080 to the host machine.
  static String get apiBaseUrl {
    switch (_current) {
      case AppEnvironment.dev:
        return 'http://127.0.0.1:8080';
      case AppEnvironment.staging:
      case AppEnvironment.production:
        return 'https://api.tanderconnect.com';
    }
  }

  static String get wsUrl {
    switch (_current) {
      case AppEnvironment.dev:
        return 'ws://127.0.0.1:8080/ws';
      case AppEnvironment.staging:
      case AppEnvironment.production:
        return 'wss://api.tanderconnect.com/ws';
    }
  }

  static bool get isDebug => _current == AppEnvironment.dev;

  static bool get isProduction => _current == AppEnvironment.production;
}
