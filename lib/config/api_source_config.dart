/// Central trusted-source configuration.
/// Change versions/URLs here — never in UI screens.
class ApiSourceConfig {
  ApiSourceConfig._();

  static const Duration defaultTimeout = Duration(seconds: 12);
  static const Duration radioTimeout = Duration(seconds: 8);
  static const Duration healthCheckTimeout = Duration(seconds: 6);

  static const ApiEndpoint mp3QuranReciters = ApiEndpoint(
    provider: 'mp3quran',
    baseUrl: 'https://mp3quran.net/api/v3',
    version: 'v3',
    path: '/reciters',
    timeout: defaultTimeout,
    capabilities: ['reciters', 'moshaf', 'server', 'surah_list'],
  );

  static const ApiEndpoint mp3QuranRadios = ApiEndpoint(
    provider: 'mp3quran',
    baseUrl: 'https://mp3quran.net/api/v3',
    version: 'v3',
    path: '/radios',
    timeout: defaultTimeout,
    capabilities: ['radios', 'stream'],
  );

  static const ApiEndpoint mp3QuranRadioJsonFallback = ApiEndpoint(
    provider: 'mp3quran',
    baseUrl: 'https://www.mp3quran.net/api/radio',
    version: 'legacy',
    path: '/radio_ar.json',
    timeout: defaultTimeout,
    capabilities: ['radios', 'stream'],
  );

  static const ApiEndpoint aladhanTimings = ApiEndpoint(
    provider: 'aladhan',
    baseUrl: 'https://api.aladhan.com/v1',
    version: 'v1',
    path: '/timings',
    timeout: defaultTimeout,
    capabilities: ['timings', 'method', 'madhab', 'coordinates'],
  );

  static const ApiEndpoint aladhanCalendar = ApiEndpoint(
    provider: 'aladhan',
    baseUrl: 'https://api.aladhan.com/v1',
    version: 'v1',
    path: '/calendar',
    timeout: Duration(seconds: 20),
    capabilities: ['calendar', '30-day'],
  );

  /// Quran Foundation Content API must be reached via a backend proxy.
  /// Never put client_secret in the Flutter client.
  /// Compile-time: --dart-define=QURAN_FOUNDATION_PROXY_URL=https://your-backend.example/qf
  static String get quranFoundationProxyBaseUrl {
    const fromEnv = String.fromEnvironment('QURAN_FOUNDATION_PROXY_URL');
    return fromEnv.trim();
  }

  static bool get hasQuranFoundationProxy =>
      quranFoundationProxyBaseUrl.isNotEmpty;

  static const ApiEndpoint quranFoundationChapterAudio = ApiEndpoint(
    provider: 'quran_foundation',
    baseUrl: '',
    version: '4.0.0',
    path: '/chapter_recitations',
    timeout: defaultTimeout,
    capabilities: ['timestamps', 'segments'],
  );
}

class ApiEndpoint {
  final String provider;
  final String baseUrl;
  final String version;
  final String path;
  final Duration timeout;
  final List<String> capabilities;

  const ApiEndpoint({
    required this.provider,
    required this.baseUrl,
    required this.version,
    required this.path,
    required this.timeout,
    required this.capabilities,
  });

  Uri uri([Map<String, String>? query]) {
    final parsed = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return parsed;
    return parsed.replace(queryParameters: {
      ...parsed.queryParameters,
      ...query,
    });
  }
}
