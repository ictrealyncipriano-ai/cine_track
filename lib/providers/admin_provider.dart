import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Central provider for admin functionality: dashboard stats, user management,
/// review moderation, analytics, and app settings.
class AdminProvider extends ChangeNotifier {
  final ApiService _api;

  AdminProvider(this._api);

  // ── Dashboard ──────────────────────────────────────────────────
  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _pendingReviewsList = [];
  bool _isLoadingDashboard = false;
  String? _dashboardError;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  List<Map<String, dynamic>> get pendingReviewsList => _pendingReviewsList;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get dashboardError => _dashboardError;

  Future<void> fetchDashboard() async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();
    try {
      final data = await _api.get('admin/dashboard.php');
      _dashboardStats = Map<String, dynamic>.from(data['stats'] ?? {});
      _recentActivity = List<Map<String, dynamic>>.from(data['recent_activity'] ?? []);
      _pendingReviewsList = List<Map<String, dynamic>>.from(data['pending_reviews_list'] ?? []);
    } catch (e) {
      _dashboardError = e.toString();
    }
    _isLoadingDashboard = false;
    notifyListeners();
  }

  // ── Users ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _users = [];
  int _totalUsers = 0;
  int _usersPage = 1;
  bool _isLoadingUsers = false;
  String? _usersError;

  List<Map<String, dynamic>> get users => _users;
  int get totalUsers => _totalUsers;
  int get usersPage => _usersPage;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;

  Future<void> fetchUsers({
    String? search,
    String? role,
    int page = 1,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    _isLoadingUsers = true;
    _usersError = null;
    _usersPage = page;
    notifyListeners();
    try {
      final q = <String, String>{
        'page': page.toString(),
        'per_page': '20',
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      if (search != null && search.isNotEmpty) q['search'] = search;
      if (role != null && role.isNotEmpty) q['role'] = role;
      final qs = q.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      final data = await _api.get('admin/users.php?$qs');
      _users = List<Map<String, dynamic>>.from(data['users'] ?? []);
      _totalUsers = data['total'] as int? ?? 0;
    } catch (e) {
      _usersError = e.toString();
    }
    _isLoadingUsers = false;
    notifyListeners();
  }

  Future<void> updateUserRole(int userId, String newRole) async {
    await _api.post('admin/users/update_role.php', {
      'user_id': userId.toString(),
      'role': newRole,
    });
    await fetchUsers(page: _usersPage);
  }

  Future<void> toggleBanUser(int userId, bool banned) async {
    await _api.post('admin/users/toggle_ban.php', {
      'user_id': userId.toString(),
      'banned': banned.toString(),
    });
    await fetchUsers(page: _usersPage);
  }

  Future<void> deleteUser(int userId) async {
    await _api.post('admin/users/delete.php', {
      'user_id': userId.toString(),
    });
    await fetchUsers(page: _usersPage);
  }

  // ── Reviews ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _reviews = [];
  int _totalReviews = 0;
  int _reviewsPage = 1;
  bool _isLoadingReviews = false;
  String? _reviewsError;
  String _reviewFilter = 'pending';

  List<Map<String, dynamic>> get reviews => _reviews;
  int get totalReviews => _totalReviews;
  int get reviewsPage => _reviewsPage;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get reviewsError => _reviewsError;
  String get reviewFilter => _reviewFilter;

  Future<void> fetchReviews({String status = 'pending', int page = 1}) async {
    _isLoadingReviews = true;
    _reviewsError = null;
    _reviewsPage = page;
    _reviewFilter = status;
    notifyListeners();
    try {
      final q = <String, String>{
        'page': page.toString(),
        'per_page': '20',
        'status': status,
      };
      final qs = q.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      final data = await _api.get('admin/reviews.php?$qs');
      _reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
      _totalReviews = data['total'] as int? ?? 0;
    } catch (e) {
      _reviewsError = e.toString();
    }
    _isLoadingReviews = false;
    notifyListeners();
  }

  Future<void> moderateReview(int reviewId, String action, {String? note}) async {
    await _api.post('admin/reviews/moderate.php', {
      'review_id': reviewId.toString(),
      'action': action,
      'moderation_note': ?note,
    });
    await fetchReviews(status: _reviewFilter, page: _reviewsPage);
  }

  Future<void> deleteReview(int reviewId) async {
    await _api.post('admin/reviews/delete.php', {
      'review_id': reviewId.toString(),
    });
    await fetchReviews(status: _reviewFilter, page: _reviewsPage);
  }
}
