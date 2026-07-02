import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('getToken error: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('saveToken error: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      debugPrint('deleteToken error: $e');
    }
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
    try {
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Server is taking too long. Please check your connection and try again.');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Server is taking too long. Please check your connection and try again.');
    }
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
      } on FormatException {
        throw Exception('Request failed with status ${response.statusCode}: ${response.body}');
      }
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } on FormatException {
      throw Exception('${response.statusCode}: ${response.body}');
    }
  }
}
