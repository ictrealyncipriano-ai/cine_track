import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _authService.addListener(_onAuthChange);
    unawaited(_authService.checkAuth());
  }

  User? get user => _authService.user;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _authService.isLoading;
  bool get emailVerified => _authService.emailVerified;

  Future<void> checkAuth() async {
    await _authService.checkAuth();
  }

  void _onAuthChange() {
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

  Future<String?> updateProfile(String name, String email) async {
    return _authService.updateProfile(name, email);
  }

  Future<String?> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    return _authService.changePassword(currentPassword, newPassword, confirmPassword);
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
