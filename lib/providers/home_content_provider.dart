import 'package:flutter/foundation.dart';
import '../services/api_endpoints.dart';
import '../services/api_service.dart';
import '../models/admin/banner.dart' as banner_model;

class HomeContentProvider extends ChangeNotifier {
  final ApiService _api;

  HomeContentProvider(this._api);

  List<banner_model.AppBanner> _banners = [];
  List<Map<String, dynamic>> _featuredMovies = [];
  bool _isLoading = false;
  String? _error;

  List<banner_model.AppBanner> get banners => _banners;
  List<Map<String, dynamic>> get featuredMovies => _featuredMovies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomeContent() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.publicBanners),
        _api.get(ApiEndpoints.featuredMovies),
      ]);
      _banners = (results[0]['banners'] as List<dynamic>?)
              ?.map((e) => banner_model.AppBanner.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
      _featuredMovies = (results[1]['movies'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
