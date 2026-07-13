import 'package:flutter/foundation.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';

class AdminSettingsProvider extends ChangeNotifier {
  final ApiService _api;

  AdminSettingsProvider(this._api);

  Map<String, dynamic> _settings = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;

  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get(ApiEndpoints.settings);
      final list = data['settings'] as List<dynamic>? ?? [];
      _settings = {for (final s in list) s['key'] as String: s['value']};
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _api.post(ApiEndpoints.settingsUpdate, {'settings': {key: value}});
      _settings[key] = value;
      _successMessage = 'Setting updated';
    } catch (e) {
      _error = e.toString();
    }
    _isSaving = false;
    notifyListeners();
  }

  Future<void> saveSettings(Map<String, dynamic> updated) async {
    _isSaving = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      await _api.post(ApiEndpoints.settingsUpdate, {'settings': updated});
      _settings.addAll(updated);
      _successMessage = 'Settings saved';
    } catch (e) {
      _error = e.toString();
    }
    _isSaving = false;
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
