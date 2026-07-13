import 'package:flutter/foundation.dart';
import '../models/admin/admin_movie.dart';
import '../models/admin/admin_review.dart';
import '../services/api_endpoints.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api;

  AdminProvider(this._api);

  // ── Dashboard ─────────────────────────────────────────────────

  bool _isLoadingDashboard = false;
  String? _dashboardError;
  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _recentActivity = [];
  List<AdminReview> _pendingReviewsList = [];
  List<Map<String, dynamic>> _topMovies = [];
  Map<String, dynamic>? _analytics;

  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get dashboardError => _dashboardError;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  List<AdminReview> get pendingReviewsList => _pendingReviewsList;
  List<Map<String, dynamic>> get topMovies => _topMovies;
  Map<String, dynamic>? get analytics => _analytics;

  Future<void> fetchDashboard() async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();
    try {
      final data = await _api.get(ApiEndpoints.dashboard);
      _dashboardStats = Map<String, dynamic>.from(data['stats'] ?? {});
      _recentActivity =
          List<Map<String, dynamic>>.from(data['recent_activity'] ?? []);
      _pendingReviewsList = (data['pending_reviews_list'] as List<dynamic>?)
              ?.map((e) => AdminReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _topMovies = List<Map<String, dynamic>>.from(data['top_movies'] ?? []);
      _analytics = Map<String, dynamic>.from(data['analytics'] ?? {});
      _dashboardError = null;
    } catch (e) {
      _dashboardError = e.toString();
    }
    _isLoadingDashboard = false;
    notifyListeners();
  }

  // ── Admin Movies ──────────────────────────────────────────────

  bool _isLoadingAdminMovies = false;
  String? _adminMoviesError;
  List<AdminMovie> _adminMovies = [];
  int _totalAdminMovies = 0;
  int _adminMoviesPage = 1;

  bool get isLoadingAdminMovies => _isLoadingAdminMovies;
  String? get adminMoviesError => _adminMoviesError;
  List<AdminMovie> get adminMovies => _adminMovies;
  int get totalAdminMovies => _totalAdminMovies;
  int get adminMoviesPage => _adminMoviesPage;

  Future<void> fetchAdminMovies({
    int page = 1,
    String sortBy = 'interactions',
    String sortOrder = 'desc',
    String? search,
  }) async {
    _isLoadingAdminMovies = true;
    _adminMoviesError = null;
    _adminMoviesPage = page;
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
      _adminMovies = (data['movies'] as List<dynamic>?)
              ?.map((e) => AdminMovie.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _totalAdminMovies = data['total'] as int? ?? 0;
    } catch (e) {
      _adminMoviesError = e.toString();
    }
    _isLoadingAdminMovies = false;
    notifyListeners();
  }
}
