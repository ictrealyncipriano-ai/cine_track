import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _isLoading = false;

  AuthService(this._api);

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _api.getToken();
      if (token == null) {
        _user = null;
        return;
      }

      try {
        final data = await _api.get('/auth/verify.php');
        final userData = data['user'];
        if (data['valid'] == true && userData is Map<String, dynamic>) {
          _user = User.fromJson(userData);
        } else {
          _user = null;
          if (data['valid'] != true) await _api.deleteToken();
        }
      } catch (_) {
        _user = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    if (kIsWeb) return {'platform': 'web'};
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await DeviceInfoPlugin().androidInfo;
        return {
          'platform': 'android',
          'model': info.model,
          'os_version': info.version.release,
        };
      }
    } catch (_) {
      // Fall through to unknown
    }
    return {'platform': 'unknown'};
  }

  Future<String?> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final deviceInfo = await _getDeviceInfo();
      final data = await _api.post('/auth/login.php', {
        'email': email,
        'password': password,
        'remember_me': rememberMe,
        'device_info': deviceInfo,
      });
      await _api.saveToken(data['token'] as String);
      _user = User.fromJson(data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : <String, dynamic>{});
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get emailVerified => _user?.emailVerified ?? false;

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
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/auth/register.php', {
        'name': name,
        'username': username,
        'email': email,
        'phone': phone ?? '',
        'date_of_birth': dateOfBirth ?? '',
        'country': country ?? '',
        'marketing_opt_in': marketingOptIn,
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

  Future<Map<String, dynamic>> revokeAllSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.post('/auth/sessions.php', {'action': 'revoke_all'});
      return data;
    } catch (e) {
      return {'error': e.toString()};
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

  Future<String?> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? country,
    bool? marketingOptIn,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.post('/auth/profile.php', {
        'action': 'update_profile',
        'name': name,
        'email': email,
        'phone': phone,
        'date_of_birth': dateOfBirth,
        'country': country,
        'marketing_opt_in': marketingOptIn,
      });
      _user = User.fromJson(data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : <String, dynamic>{});
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

  Future<String?> uploadAvatar(String base64Image, String mimeType) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.post('/auth/avatar.php', {
        'image': base64Image,
        'mime': mimeType,
      });
      _user = _user?.copyWith(avatarUrl: data['avatar_url'] as String?);
      notifyListeners();
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
