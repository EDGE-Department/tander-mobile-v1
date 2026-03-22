enum AppEnvironment { dev, staging, production }

final class EnvConfig {
  const EnvConfig._();

  static AppEnvironment _current = AppEnvironment.dev;

  static AppEnvironment get current => _current;

  static void initialize(AppEnvironment environment) {
    _current = environment;
  }

  static String get apiBaseUrl => switch (_current) {
        AppEnvironment.dev => 'http://10.0.2.2:8080',
        AppEnvironment.staging => 'https://staging-api.tander.app',
        AppEnvironment.production => 'https://api.tander.app',
      };

  static String get wsUrl => switch (_current) {
        AppEnvironment.dev => 'ws://10.0.2.2:8080/ws',
        AppEnvironment.staging => 'wss://staging-api.tander.app/ws',
        AppEnvironment.production => 'wss://api.tander.app/ws',
      };

  static bool get isDebug => _current == AppEnvironment.dev;

  static bool get isProduction => _current == AppEnvironment.production;
}
