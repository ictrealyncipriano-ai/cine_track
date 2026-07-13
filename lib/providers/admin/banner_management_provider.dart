import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../models/admin/banner.dart' as banner_model;

class BannerManagementProvider extends ChangeNotifier {
  final ApiService _api;

  BannerManagementProvider(this._api);

  List<banner_model.AppBanner> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<banner_model.AppBanner> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBanners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get(ApiEndpoints.banners);
      _banners = (data['banners'] as List<dynamic>?)
              ?.map((e) => banner_model.AppBanner.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBanner(banner_model.AppBanner banner) async {
    _error = null;
    try {
      final data = await _api.post(ApiEndpoints.bannerAdd, {
        'title': banner.title,
        'image_url': banner.imageUrl,
        if (banner.linkUrl != null) 'link_url': banner.linkUrl,
        'sort_order': banner.sortOrder,
        'active': banner.active,
      });
      if (data['success'] == true) {
        await fetchBanners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateBanner(banner_model.AppBanner banner) async {
    _error = null;
    try {
      final data = await _api.post(ApiEndpoints.bannerUpdate, banner.toJson());
      if (data['success'] == true) {
        await fetchBanners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteBanner(int id) async {
    _error = null;
    try {
      final data = await _api.post(ApiEndpoints.bannerDelete, {'id': id});
      if (data['success'] == true) {
        _banners.removeWhere((b) => b.id == id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
