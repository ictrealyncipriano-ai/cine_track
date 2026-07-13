import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../models/admin/admin_movie.dart';

class MovieManagementProvider extends ChangeNotifier {
  final ApiService _api;

  MovieManagementProvider(this._api);

  List<AdminMovie> _movies = [];
  int _totalMovies = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  String? _error;

  List<AdminMovie> get movies => _movies;
  int get totalMovies => _totalMovies;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMovies({
    int page = 1,
    String sortBy = 'interactions',
    String sortOrder = 'desc',
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
    notifyListeners();
    try {
      final q = <String, String>{
        'page': page.toString(),
        'per_page': '20',
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      if (search != null && search.isNotEmpty) q['search'] = search;
      final qs = ApiService.buildQueryString(q);
      final data = await _api.get('${ApiEndpoints.movies}?$qs');
      _movies = (data['movies'] as List<dynamic>?)
              ?.map((e) => AdminMovie.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _totalMovies = data['total'] as int? ?? 0;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> searchTmdb(String query, {int page = 1}) async {
    final q = <String, String>{
      'q': query,
      'page': page.toString(),
    };
    final qs = ApiService.buildQueryString(q);
    final data = await _api.get('${ApiEndpoints.movieSearchTmdb}?$qs');
    return data;
  }

  Future<Map<String, dynamic>> addMovie({
    required int tmdbId,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? releaseDate,
    String? genres,
    int? runtime,
    String? status,
    bool? featured,
  }) async {
    final body = <String, dynamic>{
      'tmdb_id': tmdbId,
    };
    if (title != null) body['title'] = title;
    if (overview != null) body['overview'] = overview;
    if (posterPath != null) body['poster_path'] = posterPath;
    if (backdropPath != null) body['backdrop_path'] = backdropPath;
    if (releaseDate != null) body['release_date'] = releaseDate;
    if (genres != null) body['genres'] = genres;
    if (runtime != null) body['runtime'] = runtime;
    if (status != null) body['status'] = status;
    if (featured != null) body['featured'] = featured;
    final data = await _api.post(ApiEndpoints.movieAdd, body);
    await fetchMovies(page: _currentPage);
    return data;
  }

  Future<void> updateMovie(int movieId, Map<String, dynamic> updates) async {
    updates['id'] = movieId;
    await _api.post(ApiEndpoints.movieUpdate, updates);
    await fetchMovies(page: _currentPage);
  }

  Future<void> deleteMovie(int movieId) async {
    await _api.post(ApiEndpoints.movieDelete, {'id': movieId.toString()});
    await fetchMovies(page: _currentPage);
  }

  Future<void> toggleFeatured(int movieId, bool featured) async {
    await _api.post(ApiEndpoints.movieUpdate, {
      'id': movieId.toString(),
      'featured': featured ? 1 : 0,
    });
    await fetchMovies(page: _currentPage);
  }
}
