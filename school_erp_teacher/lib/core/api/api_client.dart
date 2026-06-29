import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_erp_teacher/core/storage/storage_service.dart';
import 'endpoints.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  final StorageService _storage;

  ApiClient({required this._storage, http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${Endpoints.baseUrl}$path')
        .replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${Endpoints.baseUrl}$path');
    final response = await _client.post(uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  Future<dynamic> put(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${Endpoints.baseUrl}$path');
    final response = await _client.put(uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${Endpoints.baseUrl}$path');
    final response = await _client.patch(uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${Endpoints.baseUrl}$path');
    final response = await _client.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    if (response.statusCode == 401) _storage.clear();
    final message = body is Map
        ? (body['error'] as String? ?? 'Unknown error')
        : 'Unknown error';
    throw ApiException(response.statusCode, message);
  }

  void dispose() {
    _client.close();
  }
}
