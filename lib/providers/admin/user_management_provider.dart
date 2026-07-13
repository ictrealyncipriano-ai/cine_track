import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../models/admin/admin_user.dart';

class UserManagementProvider extends ChangeNotifier {
  final ApiService _api;

  UserManagementProvider(this._api);

  List<AdminUser> _users = [];
  int _totalUsers = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  String? _error;

  List<AdminUser> get users => _users;
  int get totalUsers => _totalUsers;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers({
    String? search,
    String? role,
    int page = 1,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
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
      final qs = ApiService.buildQueryString(q);
      final data = await _api.get('${ApiEndpoints.users}?$qs');
      _users = (data['users'] as List<dynamic>?)
              ?.map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _totalUsers = data['total'] as int? ?? 0;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserRole(int userId, String newRole) async {
    await _api.post(ApiEndpoints.updateUserRole, {
      'user_id': userId.toString(),
      'role': newRole,
    });
    await fetchUsers(page: _currentPage);
  }

  Future<void> toggleBanUser(int userId, bool banned) async {
    await _api.post(ApiEndpoints.toggleBan, {
      'user_id': userId.toString(),
      'banned': banned.toString(),
    });
    await fetchUsers(page: _currentPage);
  }

  Future<void> deleteUser(int userId) async {
    await _api.post(ApiEndpoints.deleteUser, {
      'user_id': userId.toString(),
    });
    await fetchUsers(page: _currentPage);
  }
}
