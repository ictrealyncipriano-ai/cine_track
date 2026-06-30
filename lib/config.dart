import 'package:flutter/foundation.dart';

class AppConfig {
  static const String tmdbApiKey = '6e7c39152f79deae9cf6c4160eb245fa';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  /// Sets the API base URL at build time:
  ///   desktop/web:    `flutter build apk --dart-define=API_BASE_URL=http://localhost/cine_track/api`
  ///   android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2/cine_track/api`
  ///   android device: `--dart-define=API_BASE_URL=http://YOUR_PC_IP/cine_track/api`
  ///   production:     `--dart-define=API_BASE_URL=https://cine-track-delta.vercel.app/api`
  static String get apiBaseUrl {
    const local = 'http://localhost/cine_track/api';
    const emulator = 'http://10.0.2.2/cine_track/api';
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const useEmulator = bool.fromEnvironment('ANDROID_EMULATOR', defaultValue: false);
    if (fromEnv.isNotEmpty) return fromEnv;
    if (useEmulator) return emulator;
    return local;
  }

  static const List<Map<String, String>> streamingSources = [
    {'name': 'API Player',    'url': 'https://apiplayer.ru/embed/movie/{id}'},  // unreliable host
    {'name': 'VidLink',       'url': 'https://vidlink.pro/movie/{id}'},
    {'name': 'vidsrcme.su',   'url': 'https://vidsrcme.su/embed/movie/{id}'},
    {'name': 'vidsrcme.ru',   'url': 'https://vidsrcme.ru/embed/movie/{id}'},
  ];

  static String streamUrl(int movieId, int sourceIndex) {
    final platform = kIsWeb ? 'web' : 'mobile';
    return '$apiBaseUrl/proxy/embed.php?source=$sourceIndex&tmdb=$movieId&platform=$platform';
  }
}
