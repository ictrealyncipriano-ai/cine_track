import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  AuthService(this._api);

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<void> checkAuth() async {
    final token = await _api.getToken();
    if (token == null) {
      _user = null;
      notifyListeners();
      return;
    }

    try {
      final data = await _api.get('/auth/verify.php');
      if (data['valid'] == true) {
        _user = data['user'];
      } else {
        _user = null;
        await _api.deleteToken();
      }
    } catch (_) {
      _user = null;
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.post('/auth/login.php', {
        'email': email,
        'password': password,
      });
      await _api.saveToken(data['token'] as String);
      _user = data['user'];
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get emailVerified => _user?['email_verified'] == true;

  Future<String?> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/register.php', {
        'name': name,
        'email': email,
        'password': password,
        'confirm_password': password,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout.php', {});
    } catch (_) {
    }
    await _api.deleteToken();
    _user = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.post('/auth/sessions.php', {'action': 'list'});
      return data;
    } catch (e) {
      return {'error': e.toString(), 'sessions': <Map<String, dynamic>>[]};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> revokeSession(int sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/sessions.php', {'action': 'revoke', 'session_id': sessionId});
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/forgot_password.php', {
        'email': email,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword(String email, String token, String password, String confirmPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/reset_password.php', {
        'email': email,
        'token': token,
        'password': password,
        'confirm_password': confirmPassword,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> resendVerification(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/resend_verification.php', {
        'email': email,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> verifyEmailCode(String email, String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/verify_code.php', {
        'email': email,
        'code': code,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile(String name, String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.post('/auth/profile.php', {
        'action': 'update_profile',
        'name': name,
        'email': email,
      });
      _user = data['user'];
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/profile.php', {
        'action': 'change_password',
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteAccount(String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/account.php', {
        'password': password,
      });
      await _api.deleteToken();
      _user = null;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }
}
