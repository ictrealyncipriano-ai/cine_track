import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _api;
  final AuthService _authService;
  final List<Movie> _favorites = [];

  FavoritesProvider(this._api, this._authService) {
    _authService.addListener(_onAuthChanged);
  }

  List<Movie> get favorites => List.unmodifiable(_favorites);
  bool get isEmpty => _favorites.isEmpty;

  bool isLoading = true;

  void _onAuthChanged() {
    if (_authService.isAuthenticated) {
      fetchFavorites();
    } else {
      _favorites.clear();
      isLoading = true;
      notifyListeners();
    }
  }

  Future<void> fetchFavorites() async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/favorites/list.php');
      final list = data['favorites'] as List<dynamic>;
      _favorites.clear();
      for (final item in list) {
        _favorites.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
    } catch (_) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Movie movie) async {
    final exists = _favorites.any((m) => m.id == movie.id);
    if (exists) {
      _favorites.removeWhere((m) => m.id == movie.id);
      await _api.post('/favorites/remove.php', {'movie_id': movie.id});
    } else {
      _favorites.add(movie);
      await _api.post('/favorites/add.php', movie.toJson());
    }
    notifyListeners();
  }

  bool isFavorite(int movieId) => _favorites.any((m) => m.id == movieId);

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
