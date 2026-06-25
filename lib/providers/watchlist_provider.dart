import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class WatchlistProvider extends ChangeNotifier {
  final ApiService _api;
  final AuthService _authService;
  final List<Movie> _watchlist = [];

  WatchlistProvider(this._api, this._authService) {
    _authService.addListener(_onAuthChanged);
  }

  List<Movie> get watchlist => List.unmodifiable(_watchlist);
  bool get isEmpty => _watchlist.isEmpty;

  bool isLoading = true;
  String? errorMessage;

  void _onAuthChanged() {
    if (_authService.isAuthenticated) {
      fetchWatchlist();
    } else {
      _watchlist.clear();
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWatchlist() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.get('/watchlist/list.php');
      final list = data['watchlist'] as List<dynamic>;
      _watchlist.clear();
      for (final item in list) {
        _watchlist.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
    } catch (e) {
      errorMessage = '$e';
      debugPrint('fetchWatchlist error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleWatchlist(Movie movie) async {
    final exists = _watchlist.any((m) => m.id == movie.id);
    if (exists) {
      _watchlist.removeWhere((m) => m.id == movie.id);
      await _api.post('/watchlist/remove.php', {'movie_id': movie.id});
    } else {
      _watchlist.add(movie);
      await _api.post('/watchlist/add.php', movie.toJson());
    }
    notifyListeners();
  }

  bool isInWatchlist(int movieId) => _watchlist.any((m) => m.id == movieId);

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}
