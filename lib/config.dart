import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String tmdbApiKey = '6e7c39152f79deae9cf6c4160eb245fa';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static const String _productionUrl = 'https://cine-track-delta.vercel.app/api';
  static const String _emulatorUrl = 'http://10.0.2.2/cine_track/api';
  static const String _prefsKey = 'api_base_url';

  static String _baseUrl = _productionUrl;
  static String get apiBaseUrl => _baseUrl;

  static Future<void> initialize() async {
    final isEmulator = await _isAndroidEmulator();
    if (isEmulator) {
      _baseUrl = _emulatorUrl;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    }
    debugPrint('AppConfig: isEmulator=$isEmulator → baseUrl=$_baseUrl');
  }

  static Future<void> setApiBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
  }

  static Future<bool> _isAndroidEmulator() async {
    if (kIsWeb) return false;
    return false;
  }

  static const List<Map<String, String>> streamingSources = [
    {'name': 'API Player',    'url': 'https://apiplayer.ru/embed/movie/{id}'},
    {'name': 'VidLink',       'url': 'https://vidlink.pro/movie/{id}'},
    {'name': 'vidsrcme.su',   'url': 'https://vidsrcme.su/embed/movie/{id}'},
    {'name': 'vidsrcme.ru',   'url': 'https://vidsrcme.ru/embed/movie/{id}'},
  ];

  static String streamUrl(int movieId, int sourceIndex) {
    final platform = kIsWeb ? 'web' : 'mobile';
    return '$apiBaseUrl/proxy/embed.php?source=$sourceIndex&tmdb=$movieId&platform=$platform';
  }
}
