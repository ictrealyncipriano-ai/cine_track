import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../models/admin/dashboard_stats.dart';
import '../../models/admin/analytics.dart';
import '../../models/admin/admin_review.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api;

  DashboardProvider(this._api);

  DashboardStats? _dashboardStats;
  List<Map<String, dynamic>> _recentActivity = [];
  List<AdminReview> _pendingReviewsList = [];
  List<Map<String, dynamic>> _topMovies = [];
  Analytics? _analytics;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  List<AdminReview> get pendingReviewsList => _pendingReviewsList;
  List<Map<String, dynamic>> get topMovies => _topMovies;
  Analytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get(ApiEndpoints.dashboard);
      _dashboardStats = DashboardStats.fromJson(
          Map<String, dynamic>.from(data['stats'] ?? {}));
      _recentActivity =
          List<Map<String, dynamic>>.from(data['recent_activity'] ?? []);
      _pendingReviewsList = (data['pending_reviews_list'] as List<dynamic>?)
              ?.map((e) => AdminReview.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
      _topMovies = List<Map<String, dynamic>>.from(data['top_movies'] ?? []);
      _analytics = Analytics.fromJson(
          Map<String, dynamic>.from(data['analytics'] ?? {}));
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
