import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../models/admin/admin_review.dart';

class ReviewModerationProvider extends ChangeNotifier {
  final ApiService _api;

  ReviewModerationProvider(this._api);

  List<AdminReview> _reviews = [];
  int _totalReviews = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'pending';

  List<AdminReview> get reviews => _reviews;
  int get totalReviews => _totalReviews;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  Future<void> fetchReviews({String status = 'pending', int page = 1}) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
    _currentFilter = status;
    notifyListeners();
    try {
      final q = <String, String>{
        'page': page.toString(),
        'per_page': '20',
        'status': status,
      };
      final qs = ApiService.buildQueryString(q);
      final data = await _api.get('${ApiEndpoints.reviews}?$qs');
      _reviews = (data['reviews'] as List<dynamic>?)
              ?.map((e) => AdminReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      _totalReviews = data['total'] as int? ?? 0;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> moderateReview(int reviewId, String action,
      {String? note}) async {
    await _api.post(ApiEndpoints.moderateReview, {
      'review_id': reviewId.toString(),
      'action': action,
      'moderation_note': note,
    });
    await fetchReviews(status: _currentFilter, page: _currentPage);
  }

  Future<void> bulkModerateReviews(List<int> reviewIds, String action,
      {String? note}) async {
    await _api.post(ApiEndpoints.bulkModerateReview, {
      'review_ids': reviewIds.map((e) => e.toString()).toList(),
      'action': action,
      'moderation_note': note,
    });
    await fetchReviews(status: _currentFilter, page: _currentPage);
  }

  Future<void> deleteReview(int reviewId) async {
    await _api.post(ApiEndpoints.deleteReview, {
      'review_id': reviewId.toString(),
    });
    await fetchReviews(status: _currentFilter, page: _currentPage);
  }
}
