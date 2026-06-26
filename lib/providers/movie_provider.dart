import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/cast_member.dart';
import '../services/tmdb_service.dart';

class MovieProvider extends ChangeNotifier {
  final TmdbService _tmdbService;

  List<Movie> _trending = [];
  List<Movie> _nowPlaying = [];
  List<Movie> _topRated = [];
  List<Movie> _upcoming = [];
  List<Movie> _searchResults = [];
  List<Genre> _genres = [];
  List<Movie> _genreMovies = [];
  int? _selectedGenreId;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _trendingPage = 1;
  int _nowPlayingPage = 1;
  int _topRatedPage = 1;
  int _upcomingPage = 1;
  int _searchPage = 1;
  int _genrePage = 1;

  bool _hasMoreTrending = true;
  bool _hasMoreNowPlaying = true;
  bool _hasMoreTopRated = true;
  bool _hasMoreUpcoming = true;
  bool _hasMoreSearch = true;
  bool _hasMoreGenre = true;

  String _currentSearchQuery = '';

  MovieProvider(this._tmdbService);

  List<Movie> get trending => _trending;
  List<Movie> get nowPlaying => _nowPlaying;
  List<Movie> get topRated => _topRated;
  List<Movie> get upcoming => _upcoming;
  List<Movie> get searchResults => _searchResults;
  List<Genre> get genres => _genres;
  List<Movie> get genreMovies => _genreMovies;
  int? get selectedGenreId => _selectedGenreId;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreTrending => _hasMoreTrending;
  bool get hasMoreNowPlaying => _hasMoreNowPlaying;
  bool get hasMoreTopRated => _hasMoreTopRated;
  bool get hasMoreUpcoming => _hasMoreUpcoming;
  bool get hasMoreSearch => _hasMoreSearch;
  bool get hasMoreGenre => _hasMoreGenre;

  Future<void> fetchTrending({bool reset = true}) async {
    if (reset) {
      _trendingPage = 1;
      _hasMoreTrending = true;
    }
    _isLoading = reset;
    _isLoadingMore = !reset;
    _error = null;
    notifyListeners();

    try {
      final results = await _tmdbService.getTrending(page: _trendingPage);
      if (reset) {
        _trending = results;
      } else {
        _trending.addAll(results);
      }
      _hasMoreTrending = results.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchNowPlaying({bool reset = true}) async {
    if (reset) {
      _nowPlayingPage = 1;
      _hasMoreNowPlaying = true;
    }
    _isLoading = reset;
    _isLoadingMore = !reset;
    _error = null;
    notifyListeners();

    try {
      final results = await _tmdbService.getNowPlaying(page: _nowPlayingPage);
      if (reset) {
        _nowPlaying = results;
      } else {
        _nowPlaying.addAll(results);
      }
      _hasMoreNowPlaying = results.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchTopRated({bool reset = true}) async {
    if (reset) {
      _topRatedPage = 1;
      _hasMoreTopRated = true;
    }
    _isLoading = reset;
    _isLoadingMore = !reset;
    _error = null;
    notifyListeners();

    try {
      final results = await _tmdbService.getTopRated(page: _topRatedPage);
      if (reset) {
        _topRated = results;
      } else {
        _topRated.addAll(results);
      }
      _hasMoreTopRated = results.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcoming({bool reset = true}) async {
    if (reset) {
      _upcomingPage = 1;
      _hasMoreUpcoming = true;
    }
    _isLoading = reset;
    _isLoadingMore = !reset;
    _error = null;
    notifyListeners();

    try {
      final results = await _tmdbService.getUpcoming(page: _upcomingPage);
      if (reset) {
        _upcoming = results;
      } else {
        _upcoming.addAll(results);
      }
      _hasMoreUpcoming = results.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTrending() async {
    if (_isLoadingMore || !_hasMoreTrending) return;
    _trendingPage++;
    await fetchTrending(reset: false);
  }

  Future<void> loadMoreNowPlaying() async {
    if (_isLoadingMore || !_hasMoreNowPlaying) return;
    _nowPlayingPage++;
    await fetchNowPlaying(reset: false);
  }

  Future<void> loadMoreTopRated() async {
    if (_isLoadingMore || !_hasMoreTopRated) return;
    _topRatedPage++;
    await fetchTopRated(reset: false);
  }

  Future<void> loadMoreUpcoming() async {
    if (_isLoadingMore || !_hasMoreUpcoming) return;
    _upcomingPage++;
    await fetchUpcoming(reset: false);
  }

  Future<Movie> fetchMovieDetails(int movieId) async {
    return _tmdbService.getMovieDetails(movieId);
  }

  Future<List<CastMember>> fetchMovieCredits(int movieId) async {
    final data = await _tmdbService.getMovieCredits(movieId);
    final cast = data['cast'] as List<dynamic>;
    return cast
        .map((e) => CastMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> fetchSimilarMovies(int movieId) async {
    return _tmdbService.getSimilarMovies(movieId);
  }

  Future<void> search(String query) async {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      _searchResults = [];
      _hasMoreSearch = true;
      _searchPage = 1;
      notifyListeners();
      return;
    }

    _searchPage = 1;
    _hasMoreSearch = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _tmdbService.searchMovies(query);
      _hasMoreSearch = _searchResults.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSearch() async {
    if (_isLoadingMore || !_hasMoreSearch || _currentSearchQuery.isEmpty) return;
    _isLoadingMore = true;
    _searchPage++;
    notifyListeners();

    try {
      final results = await _tmdbService.searchMovies(
        _currentSearchQuery,
        page: _searchPage,
      );
      _searchResults.addAll(results);
      _hasMoreSearch = results.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchGenres() async {
    if (_genres.isNotEmpty) return;

    try {
      _genres = await _tmdbService.getGenres();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> discoverByGenre(int genreId, {bool reset = true}) async {
    if (reset) {
      _genrePage = 1;
      _hasMoreGenre = true;
    }
    _isLoading = reset;
    _isLoadingMore = !reset;
    _error = null;
    notifyListeners();

    try {
      final results = await _tmdbService.discoverByGenre(genreId, page: _genrePage);
      if (reset) {
        _genreMovies = results;
      } else {
        _genreMovies.addAll(results);
      }
      _hasMoreGenre = results.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreGenre() async {
    if (_isLoadingMore || !_hasMoreGenre || _selectedGenreId == null) return;
    _genrePage++;
    await discoverByGenre(_selectedGenreId!, reset: false);
  }

  void clearGenreFilter() {
    _selectedGenreId = null;
    _genreMovies = [];
    _genrePage = 1;
    _hasMoreGenre = true;
    _error = null;
    notifyListeners();
  }
}
