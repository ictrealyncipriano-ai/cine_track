class AppConfig {
  static const String tmdbApiKey = '6e7c39152f79deae9cf6c4160eb245fa';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static String get apiBaseUrl {
    const local = 'http://localhost/cine_track/api';
    const production = String.fromEnvironment('API_BASE_URL', defaultValue: local);
    return production;
  }

  static const List<Map<String, String>> streamingSources = [
    {'name': 'API Player',    'url': 'https://apiplayer.ru/embed/movie/{id}'},
    {'name': 'VidLink',       'url': 'https://vidlink.pro/movie/{id}'},
  ];

  static String streamUrl(int movieId, int sourceIndex) {
    return '$apiBaseUrl/proxy/embed.php?source=$sourceIndex&tmdb=$movieId';
  }
}
