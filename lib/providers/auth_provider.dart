import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  bool _isGuest = false;

  AuthProvider(this._authService) {
    _authService.addListener(_onAuthChange);
    _loadGuestPref();
    unawaited(_authService.checkAuth());
  }

  Future<void> _loadGuestPref() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('guest_mode') ?? false;
    notifyListeners();
  }

  User? get user => _authService.user;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _authService.isLoading;
  bool get isGuest => _isGuest;
  bool get emailVerified => _authService.emailVerified;

  Future<void> checkAuth() async {
    await _authService.checkAuth();
  }

  void _onAuthChange() {
    if (_authService.isAuthenticated) {
      _isGuest = false;
    }
    notifyListeners();
  }

  Future<void> enterGuestMode() async {
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', true);
    notifyListeners();
  }

  Future<void> exitGuestMode() async {
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_mode');
    notifyListeners();
  }

  Future<String?> login(String email, String password, {bool rememberMe = true}) async {
    return _authService.login(email, password, rememberMe: rememberMe);
  }

  Future<String?> register({
    required String name,
    required String username,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? country,
    bool marketingOptIn = false,
    required String password,
    required String confirmPassword,
  }) async {
    return _authService.register(
      name: name,
      username: username,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      country: country,
      marketingOptIn: marketingOptIn,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<Map<String, dynamic>> getSessions() async {
    return _authService.getSessions();
  }

  Future<String?> revokeSession(int sessionId) async {
    return _authService.revokeSession(sessionId);
  }

  Future<String?> forgotPassword(String email) async {
    return _authService.forgotPassword(email);
  }

  Future<String?> resetPassword(String email, String token, String password, String confirmPassword) async {
    return _authService.resetPassword(email, token, password, confirmPassword);
  }

  Future<String?> resendVerification(String email) async {
    return _authService.resendVerification(email);
  }

  Future<String?> verifyEmailCode(String email, String code) async {
    return _authService.verifyEmailCode(email, code);
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? country,
    bool? marketingOptIn,
  }) async {
    return _authService.updateProfile(
      name: name,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      country: country,
      marketingOptIn: marketingOptIn,
    );
  }

  Future<String?> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    return _authService.changePassword(currentPassword, newPassword, confirmPassword);
  }

  Future<String?> uploadAvatar(String base64Image, String mimeType) async {
    return _authService.uploadAvatar(base64Image, mimeType);
  }

  Future<String?> deleteAccount(String password) async {
    return _authService.deleteAccount(password);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChange);
    super.dispose();
  }
}
