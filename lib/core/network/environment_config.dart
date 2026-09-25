/// Environment configuration for PLAZA API
enum AppEnvironment {
  dev,
  staging,
  prod,
}

class EnvironmentConfig {
  static const String liveRenderUrl = 'https://plaza-api-o4sh.onrender.com/api/v1';
  static const String localDevUrl = 'http://127.0.0.1:3000/api/v1';

  static const String _envOverrideUrl = String.fromEnvironment('PLAZA_API_URL');
  static const String _envName = String.fromEnvironment('PLAZA_ENV', defaultValue: '');

  static AppEnvironment _current = _resolveInitialEnvironment();
  static String? _runtimeUrlOverride;

  static AppEnvironment _resolveInitialEnvironment() {
    final lower = _envName.trim().toLowerCase();
    if (lower == 'staging') return AppEnvironment.staging;
    if (lower == 'prod' || lower == 'production') return AppEnvironment.prod;
    if (lower == 'dev' || lower == 'development') return AppEnvironment.dev;
    // If PLAZA_API_URL is supplied and points to render, default to staging
    if (_envOverrideUrl.contains('onrender.com')) {
      return AppEnvironment.staging;
    }
    return AppEnvironment.dev;
  }

  static AppEnvironment get current => _current;

  static void setEnvironment(AppEnvironment env) {
    _current = env;
  }

  static void setBaseUrlOverride(String? url) {
    _runtimeUrlOverride = url;
  }

  static void reset() {
    _current = _resolveInitialEnvironment();
    _runtimeUrlOverride = null;
    useMockData = false;
  }

  static String get baseUrl {
    if (_runtimeUrlOverride != null && _runtimeUrlOverride!.isNotEmpty) {
      return _runtimeUrlOverride!;
    }
    if (_envOverrideUrl.isNotEmpty) {
      return _envOverrideUrl;
    }
    switch (_current) {
      case AppEnvironment.dev:
        return localDevUrl;
      case AppEnvironment.staging:
        return liveRenderUrl;
      case AppEnvironment.prod:
        return liveRenderUrl;
    }
  }

  static bool get isLiveRender => baseUrl.contains('onrender.com');

  static bool useMockData = false;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
