import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class WatchlistProvider extends ChangeNotifier {
  final ApiService _api;
  final AuthService _authService;
  final List<Movie> _watchlist = [];

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _total = 0;
  String _sortBy = 'recent';

  WatchlistProvider(this._api, this._authService) {
    _authService.addListener(_onAuthChanged);
  }

  List<Movie> get watchlist => List.unmodifiable(_watchlist);
  int get totalCount => _total;
  bool get isEmpty => _watchlist.isEmpty;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool isLoading = true;
  String? errorMessage;

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('status 500') || msg.contains('Internal server error')) {
      return 'Something went wrong on our end. Please try again.';
    }
    if (msg.contains('Timeout') || msg.contains('taking too long')) {
      return 'Request timed out. Please check your connection.';
    }
    if (msg.contains('status 401') || msg.contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (msg.contains('status 404')) {
      return 'Watchlist not found.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _onAuthChanged() {
    if (_authService.isAuthenticated) {
      _page = 1;
      _hasMore = true;
      _total = 0;
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      fetchWatchlist();
    } else {
      _watchlist.clear();
      _page = 1;
      _hasMore = true;
      _total = 0;
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWatchlist({String? sortBy}) async {
    if (sortBy != null) _sortBy = sortBy;
    _page = 1;
    _hasMore = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.get('/watchlist/list.php?page=1&per_page=20&sort_by=$_sortBy');
      final list = data['watchlist'] as List<dynamic>;
      _total = data['total'] as int? ?? list.length;
      _watchlist.clear();
      for (final item in list) {
        _watchlist.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
      _hasMore = _watchlist.length < _total;
    } catch (e) {
      errorMessage = _friendlyError(e);
      debugPrint('fetchWatchlist error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreWatchlist() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _page++;
    notifyListeners();

    try {
      final data = await _api.get('/watchlist/list.php?page=$_page&per_page=20&sort_by=$_sortBy');
      final list = data['watchlist'] as List<dynamic>;
      _total = data['total'] as int? ?? 0;
      for (final item in list) {
        _watchlist.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
      _hasMore = _watchlist.length < _total;
    } catch (e) {
      _page--;
      errorMessage = _friendlyError(e);
      debugPrint('loadMoreWatchlist error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleWatchlist(Movie movie) async {
    final exists = _watchlist.any((m) => m.id == movie.id);
    if (exists) {
      _watchlist.removeWhere((m) => m.id == movie.id);
      _total--;
      notifyListeners();
      try {
        await _api.post('/watchlist/remove.php', {'movie_id': movie.id});
      } catch (e) {
        _watchlist.add(movie);
        _total++;
        errorMessage = 'Failed to remove from watchlist';
        notifyListeners();
      }
    } else {
      _watchlist.add(movie);
      _total++;
      notifyListeners();
      try {
        await _api.post('/watchlist/add.php', movie.toJson());
      } catch (e) {
        _watchlist.removeWhere((m) => m.id == movie.id);
        _total--;
        errorMessage = 'Failed to add to watchlist';
        notifyListeners();
      }
    }
  }

  bool isInWatchlist(int movieId) => _watchlist.any((m) => m.id == movieId);

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
