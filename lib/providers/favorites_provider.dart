import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _api;
  final AuthService _authService;
  final List<Movie> _favorites = [];

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _total = 0;
  String _sortBy = 'recent';

  FavoritesProvider(this._api, this._authService) {
    _authService.addListener(_onAuthChanged);
  }

  List<Movie> get favorites => List.unmodifiable(_favorites);
  bool get isEmpty => _favorites.isEmpty;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool isLoading = true;
  String? errorMessage;

  void _onAuthChanged() {
    if (_authService.isAuthenticated) {
      _page = 1;
      _hasMore = true;
      _total = 0;
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      fetchFavorites();
    } else {
      _favorites.clear();
      _page = 1;
      _hasMore = true;
      _total = 0;
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFavorites({String? sortBy}) async {
    if (sortBy != null) _sortBy = sortBy;
    _page = 1;
    _hasMore = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.get('/favorites/list.php?page=1&per_page=20&sort_by=$_sortBy');
      final list = data['favorites'] as List<dynamic>;
      _total = data['total'] as int? ?? list.length;
      _favorites.clear();
      for (final item in list) {
        _favorites.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
      _hasMore = _favorites.length < _total;
    } catch (e) {
      errorMessage = '$e';
      debugPrint('fetchFavorites error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreFavorites() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _page++;
    notifyListeners();

    try {
      final data = await _api.get('/favorites/list.php?page=$_page&per_page=20&sort_by=$_sortBy');
      final list = data['favorites'] as List<dynamic>;
      _total = data['total'] as int? ?? 0;
      for (final item in list) {
        _favorites.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
      _hasMore = _favorites.length < _total;
    } catch (e) {
      _page--;
      errorMessage = '$e';
      debugPrint('loadMoreFavorites error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Movie movie) async {
    final exists = _favorites.any((m) => m.id == movie.id);
    if (exists) {
      _favorites.removeWhere((m) => m.id == movie.id);
      _total--;
      notifyListeners();
      try {
        await _api.post('/favorites/remove.php', {'movie_id': movie.id});
      } catch (e) {
        _favorites.add(movie);
        _total++;
        errorMessage = 'Failed to remove from favorites';
        notifyListeners();
      }
    } else {
      _favorites.add(movie);
      _total++;
      notifyListeners();
      try {
        await _api.post('/favorites/add.php', movie.toJson());
      } catch (e) {
        _favorites.removeWhere((m) => m.id == movie.id);
        _total--;
        errorMessage = 'Failed to add to favorites';
        notifyListeners();
      }
    }
  }

  bool isFavorite(int movieId) => _favorites.any((m) => m.id == movieId);

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
