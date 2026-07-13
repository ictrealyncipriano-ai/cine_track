import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../models/admin/activity_log.dart';

class ActivityLogProvider extends ChangeNotifier {
  final ApiService _api;

  ActivityLogProvider(this._api);

  List<ActivityLog> _logs = [];
  int _totalLogs = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  String? _error;
  List<String> _actionTypes = [];

  List<ActivityLog> get logs => _logs;
  int get totalLogs => _totalLogs;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get actionTypes => _actionTypes;

  Future<void> fetchLogs({
    int page = 1,
    String? action,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
    notifyListeners();
    try {
      final q = <String, String>{
        'page': page.toString(),
        'per_page': '30',
      };
      if (action != null && action.isNotEmpty) q['action'] = action;
      if (search != null && search.isNotEmpty) q['search'] = search;
      final qs = ApiService.buildQueryString(q);
      final data = await _api.get('${ApiEndpoints.activity}?$qs');
      _logs = (data['logs'] as List<dynamic>?)
              ?.map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _totalLogs = data['total'] as int? ?? 0;
      _actionTypes = List<String>.from(data['action_types'] ?? []);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
