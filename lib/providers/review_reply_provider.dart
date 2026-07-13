import 'package:flutter/foundation.dart';
import '../models/review_reply.dart';
import '../services/api_endpoints.dart';
import '../services/api_service.dart';

class ReviewReplyProvider extends ChangeNotifier {
  final ApiService _api;

  ReviewReplyProvider(this._api);

  final Map<int, List<ReviewReply>> _repliesByReview = {};
  final Set<int> _expandedReviews = {};
  final bool _isLoading = false;
  String? _error;

  Map<int, List<ReviewReply>> get repliesByReview => _repliesByReview;
  Set<int> get expandedReviews => _expandedReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isExpanded(int reviewId) => _expandedReviews.contains(reviewId);

  void toggleExpanded(int reviewId) {
    if (_expandedReviews.contains(reviewId)) {
      _expandedReviews.remove(reviewId);
    } else {
      _expandedReviews.add(reviewId);
      if (!_repliesByReview.containsKey(reviewId)) {
        fetchReplies(reviewId);
      }
    }
    notifyListeners();
  }

  Future<void> fetchReplies(int reviewId) async {
    try {
      final data = await _api.get('${ApiEndpoints.reviewReplies}?review_id=$reviewId');
      _repliesByReview[reviewId] = (data['replies'] as List<dynamic>?)
              ?.map((e) => ReviewReply.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> addReply(int reviewId, String body) async {
    try {
      await _api.post(ApiEndpoints.reviewReply, {'review_id': reviewId, 'body': body});
      await fetchReplies(reviewId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteReply(int replyId) async {
    try {
      await _api.post(ApiEndpoints.deleteReviewReply, {'id': replyId});
      for (final reviewId in _repliesByReview.keys) {
        _repliesByReview[reviewId]?.removeWhere((r) => r.id == replyId);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
