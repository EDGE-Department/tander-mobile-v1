enum AppEnvironment { dev, staging, production }

final class EnvConfig {
  const EnvConfig._();

  static AppEnvironment _current = AppEnvironment.dev;

  static AppEnvironment get current => _current;

  static void initialize(AppEnvironment environment) {
    _current = environment;
  }

  static String get apiBaseUrl => switch (_current) {
        AppEnvironment.dev => 'https://api.tanderconnect.com',
        AppEnvironment.staging => 'https://api.tanderconnect.com',
        AppEnvironment.production => 'https://api.tanderconnect.com',
      };

  static String get wsUrl => switch (_current) {
        AppEnvironment.dev => 'wss://api.tanderconnect.com/ws',
        AppEnvironment.staging => 'wss://api.tanderconnect.com/ws',
        AppEnvironment.production => 'wss://api.tanderconnect.com/ws',
      };

  static bool get isDebug => _current == AppEnvironment.dev;

  static bool get isProduction => _current == AppEnvironment.production;
}
