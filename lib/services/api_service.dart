import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _headers();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final response = await http.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    final request = http.Request('DELETE', uri);
    request.headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      try {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        throw Exception(data['error'] ?? 'Request failed');
      } catch (e) {
        if (e is Exception && e is! FormatException) rethrow;
        throw Exception('Request failed with status ${response.statusCode}: ${response.body}');
      }
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      throw Exception('${response.statusCode}: ${response.body}');
    }
  }
}
