import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return {
          'platform': 'android',
          'model': android.model,
          'os_version': android.version.release,
        };
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return {
          'platform': 'ios',
          'model': ios.model,
          'os_version': ios.systemVersion,
        };
      }
    } catch (_) {}
    return {'platform': kIsWeb ? 'web' : 'unknown'};
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
      _user = data['user'];
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _oauthLogin(String provider, String idToken, {String? name}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final deviceInfo = await _getDeviceInfo();
      final data = await _api.post('/auth/oauth.php', {
        'provider': provider,
        'id_token': idToken,
        'name': name ?? '',
        'device_info': deviceInfo,
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

  Future<String?> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
      ).signIn();
      if (googleUser == null) return 'Sign in cancelled';

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) return 'Failed to get Google ID token';

      return _oauthLogin('google', googleAuth.idToken!, name: googleUser.displayName);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (credential.identityToken == null) return 'Failed to get Apple ID token';

      String? name;
      if (credential.givenName != null || credential.familyName != null) {
        name = [credential.givenName, credential.familyName]
            .where((n) => n != null)
            .join(' ');
      }

      return _oauthLogin('apple', credential.identityToken!, name: name);
    } catch (e) {
      return e.toString();
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
