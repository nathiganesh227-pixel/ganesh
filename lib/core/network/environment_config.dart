/// Environment configuration for PLAZA API
enum AppEnvironment {
  dev,
  staging,
  prod,
}

class EnvironmentConfig {
  static AppEnvironment _current = AppEnvironment.dev;

  static AppEnvironment get current => _current;

  static void setEnvironment(AppEnvironment env) {
    _current = env;
  }

  static const String _envOverrideUrl = String.fromEnvironment('PLAZA_API_URL');

  static String get baseUrl {
    if (_envOverrideUrl.isNotEmpty) {
      return _envOverrideUrl;
    }
    switch (_current) {
      case AppEnvironment.dev:
        return 'http://127.0.0.1:3000/api/v1';
      case AppEnvironment.staging:
        return 'https://staging-api.plaza.app/api/v1';
      case AppEnvironment.prod:
        return 'https://api.plaza.app/api/v1';
    }
  }

  static bool useMockData = false;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
