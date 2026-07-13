import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final ApiService _api;

  AnalyticsProvider(this._api);

  String _range = '14d';
  String _granularity = 'day';

  bool _isLoadingOverview = false;
  bool _isLoadingTrends = false;
  String? _error;

  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _registrations = [];
  List<Map<String, dynamic>> _reviewsPerDay = [];
  List<Map<String, dynamic>> _reviewStatuses = [];
  List<Map<String, dynamic>> _moderationTime = [];
  List<Map<String, dynamic>> _topMovies = [];

  String get range => _range;
  String get granularity => _granularity;
  bool get isLoading => _isLoadingOverview || _isLoadingTrends;
  String? get error => _error;
  Map<String, dynamic>? get overview => _overview;
  List<Map<String, dynamic>> get registrations => _registrations;
  List<Map<String, dynamic>> get reviewsPerDay => _reviewsPerDay;
  List<Map<String, dynamic>> get reviewStatuses => _reviewStatuses;
  List<Map<String, dynamic>> get moderationTime => _moderationTime;
  List<Map<String, dynamic>> get topMovies => _topMovies;

  void setRange(String range) {
    _range = range;
    _granularity = range == '90d' ? 'week' : 'day';
    notifyListeners();
    fetchAll();
  }

  Future<void> fetchAll() async {
    _isLoadingOverview = true;
    _isLoadingTrends = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.get('${ApiEndpoints.analyticsOverview}?range=$_range'),
        _api.get('${ApiEndpoints.analyticsTrends}?range=$_range&granularity=$_granularity'),
      ]);
      _overview = results[0];
      final trends = results[1];
      _registrations = (trends['registrations'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
      _reviewsPerDay = (trends['reviews_per_day'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
      _reviewStatuses = (trends['review_statuses'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
      _moderationTime = (trends['moderation_time'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
      _topMovies = (trends['top_movies'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
    } catch (e) {
      _error = e.toString();
    }
    _isLoadingOverview = false;
    _isLoadingTrends = false;
    notifyListeners();
  }

  String get exportUrl => '${ApiEndpoints.analyticsExport}?type=reviews&range=$_range';
}
