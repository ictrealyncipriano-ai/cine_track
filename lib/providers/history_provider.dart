import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class HistoryProvider extends ChangeNotifier {
  final ApiService _api;
  final AuthService _authService;
  final List<Movie> _history = [];

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _total = 0;
  String _sortBy = 'recent';

  HistoryProvider(this._api, this._authService) {
    _authService.addListener(_onAuthChanged);
  }

  List<Movie> get history => List.unmodifiable(_history);
  List<Movie> get recentlyWatched =>
      _history.length > 10 ? _history.sublist(0, 10) : List.unmodifiable(_history);
  int get totalCount => _total;
  bool get isEmpty => _history.isEmpty;
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
      return 'History entry not found.';
    }
    return 'Something went wrong. Please try again.';
  }

  bool _fetching = false;

  void _onAuthChanged() {
    if (_authService.isAuthenticated) {
      _page = 1;
      _hasMore = true;
      _total = 0;
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      if (!_fetching) {
        _fetching = true;
        fetchHistory().then((_) => _fetching = false);
      }
    } else {
      _history.clear();
      _page = 1;
      _hasMore = true;
      _total = 0;
      errorMessage = null;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory({String? sortBy}) async {
    if (sortBy != null) _sortBy = sortBy;
    _page = 1;
    _hasMore = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.get('/history/list.php?page=1&per_page=10&sort_by=$_sortBy');
      final list = data['history'] as List<dynamic>;
      _total = data['total'] as int? ?? list.length;
      _history.clear();
      for (final item in list) {
        _history.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
      _hasMore = _history.length < _total;
    } catch (e) {
      errorMessage = _friendlyError(e);
      debugPrint('fetchHistory error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _page++;
    notifyListeners();

    try {
      final data = await _api.get('/history/list.php?page=$_page&per_page=20&sort_by=$_sortBy');
      final list = data['history'] as List<dynamic>;
      _total = data['total'] as int? ?? 0;
      for (final item in list) {
        _history.add(Movie.fromBackendJson(item as Map<String, dynamic>));
      }
      _hasMore = _history.length < _total;
    } catch (e) {
      _page--;
      errorMessage = _friendlyError(e);
      debugPrint('loadMoreHistory error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> addToHistory(Movie movie) async {
    try {
      await _api.post('/history/add.php', movie.toJson());
    } catch (e) {
      debugPrint('addToHistory error: $e');
    }
  }

  Future<void> removeFromHistory(int movieId) async {
    try {
      await _api.post('/history/delete.php', {'movie_id': movieId});
      _history.removeWhere((m) => m.id == movieId);
      _total = _total > 0 ? _total - 1 : 0;
      _hasMore = _history.length < _total;
      notifyListeners();
    } catch (e) {
      errorMessage = _friendlyError(e);
      debugPrint('removeFromHistory error: $e');
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await _api.post('/history/clear.php', {});
      _history.clear();
      _page = 1;
      _hasMore = true;
      _total = 0;
      notifyListeners();
    } catch (e) {
      errorMessage = _friendlyError(e);
      debugPrint('clearHistory error: $e');
      notifyListeners();
    }
  }

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
