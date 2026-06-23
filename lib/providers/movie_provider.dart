import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';

class MovieProvider extends ChangeNotifier {
  final TmdbService _tmdbService;

  List<Movie> _trending = [];
  List<Movie> _nowPlaying = [];
  List<Movie> _topRated = [];
  List<Movie> _searchResults = [];
  List<Genre> _genres = [];
  List<Movie> _genreMovies = [];
  int? _selectedGenreId;
  bool _isLoading = false;
  String? _error;

  MovieProvider(this._tmdbService);

  List<Movie> get trending => _trending;
  List<Movie> get nowPlaying => _nowPlaying;
  List<Movie> get topRated => _topRated;
  List<Movie> get searchResults => _searchResults;
  List<Genre> get genres => _genres;
  List<Movie> get genreMovies => _genreMovies;
  int? get selectedGenreId => _selectedGenreId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTrending() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trending = await _tmdbService.getTrending();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNowPlaying() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nowPlaying = await _tmdbService.getNowPlaying();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTopRated() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _topRated = await _tmdbService.getTopRated();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Movie> fetchMovieDetails(int movieId) async {
    return _tmdbService.getMovieDetails(movieId);
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _tmdbService.searchMovies(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
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

  Future<void> discoverByGenre(int genreId) async {
    _selectedGenreId = genreId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _genreMovies = await _tmdbService.discoverByGenre(genreId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearGenreFilter() {
    _selectedGenreId = null;
    _genreMovies = [];
    _error = null;
    notifyListeners();
  }
}
