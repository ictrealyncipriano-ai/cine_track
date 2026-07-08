import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/movie.dart';
import '../models/trailer_video.dart';

class TmdbService {
  final http.Client _client;

  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  String get _apiKey => AppConfig.tmdbApiKey;

  Future<List<Movie>> _fetchMovies(String endpoint,
      {int page = 1, Map<String, String>? extraParams}) async {
    final params = <String, String>{
      'api_key': _apiKey,
      'language': 'en-US',
      'page': page.toString(),
      ...?extraParams,
    };

    final uri = Uri.parse('${AppConfig.tmdbBaseUrl}$endpoint')
        .replace(queryParameters: params);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('TMDB API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> getTrending({int page = 1}) =>
      _fetchMovies('/trending/movie/week', page: page);

  Future<List<Movie>> getNowPlaying({int page = 1}) =>
      _fetchMovies('/movie/now_playing', page: page);

  Future<List<Movie>> getTopRated({int page = 1}) =>
      _fetchMovies('/movie/top_rated', page: page);

  Future<List<Movie>> getUpcoming({int page = 1}) =>
      _fetchMovies('/movie/upcoming', page: page);

  Future<List<Movie>> getPopular({int page = 1}) =>
      _fetchMovies('/movie/popular', page: page);

  Future<List<Movie>> searchMovies(String query, {int page = 1, int? genreId, int? year, String? sortBy}) =>
      _fetchMovies('/search/movie', page: page, extraParams: {
        'query': query,
        if (genreId != null) 'with_genres': genreId.toString(),
        if (year != null) 'year': year.toString(),
        'sort_by': ?sortBy,
      });

  Future<List<Genre>> getGenres() async {
    final params = <String, String>{
      'api_key': _apiKey,
      'language': 'en-US',
    };

    final uri = Uri.parse('${AppConfig.tmdbBaseUrl}/genre/movie/list')
        .replace(queryParameters: params);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('TMDB API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>;
    return genres
        .map((g) => Genre.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> discoverByGenre(int genreId, {int page = 1}) =>
      _fetchMovies('/discover/movie', page: page, extraParams: {
        'with_genres': genreId.toString(),
        'sort_by': 'vote_average.desc',
        'vote_count.gte': '50',
      });

  Future<Movie> getMovieDetails(int movieId) async {
    final params = <String, String>{
      'api_key': _apiKey,
      'language': 'en-US',
      'append_to_response': 'credits',
    };

    final uri = Uri.parse('${AppConfig.tmdbBaseUrl}/movie/$movieId')
        .replace(queryParameters: params);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('TMDB API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Movie.fromJson(data);
  }

  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    final params = <String, String>{
      'api_key': _apiKey,
      'language': 'en-US',
    };

    final uri = Uri.parse('${AppConfig.tmdbBaseUrl}/movie/$movieId/credits')
        .replace(queryParameters: params);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('TMDB API error: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Movie>> getSimilarMovies(int movieId, {int page = 1}) =>
      _fetchMovies('/movie/$movieId/similar', page: page);

  Future<List<Movie>> getRecommendations(int movieId, {int page = 1}) =>
      _fetchMovies('/movie/$movieId/recommendations', page: page);

  Future<List<TrailerVideo>> getMovieVideos(int movieId) async {
    final params = <String, String>{
      'api_key': _apiKey,
      'language': 'en-US',
    };

    final uri = Uri.parse('${AppConfig.tmdbBaseUrl}/movie/$movieId/videos')
        .replace(queryParameters: params);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('TMDB API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results
        .map((e) => TrailerVideo.fromJson(e as Map<String, dynamic>))
        .where((v) => v.isPlayable)
        .toList();
  }
}
