import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:school_erp_admin/core/logging/app_logger.dart';
import 'package:school_erp_admin/core/storage/storage_interface.dart';
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
  final StorageInterface _storage;
  VoidCallback? onUnauthorized;

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _refreshTimeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

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

  Future<dynamic> get(String path,
      {Map<String, String>? queryParams, Duration? timeout}) {
    return _request('GET', path,
        queryParams: queryParams, timeout: timeout);
  }

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, Duration? timeout}) {
    return _request('POST', path, body: body, timeout: timeout);
  }

  Future<dynamic> put(String path,
      {Map<String, dynamic>? body, Duration? timeout}) {
    return _request('PUT', path, body: body, timeout: timeout);
  }

  Future<dynamic> patch(String path,
      {Map<String, dynamic>? body, Duration? timeout}) {
    return _request('PATCH', path, body: body, timeout: timeout);
  }

  Future<dynamic> delete(String path, {Duration? timeout}) {
    return _request('DELETE', path, timeout: timeout);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Duration? timeout,
    int retryCount = 0,
  }) async {
    timeout ??= _defaultTimeout;
    AppLogger.api.fine('$method $path (retry=$retryCount)');

    try {
      final uri = Uri.parse('${Endpoints.baseUrl}$path')
          .replace(queryParameters: queryParams);
      final headers = await _headers();

      http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(timeout);
        case 'POST':
          response = await _client
              .post(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(timeout);
        case 'PUT':
          response = await _client
              .put(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(timeout);
        case 'PATCH':
          response = await _client
              .patch(uri,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null)
              .timeout(timeout);
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(timeout);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 401 && retryCount == 0) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _request(method, path,
              body: body,
              queryParams: queryParams,
              timeout: timeout,
              retryCount: retryCount + 1);
        }
        await _storage.clear();
        onUnauthorized?.call();
        throw ApiException(
            401, 'Session expired. Please login again.');
      }

      if (_isTransientStatusCode(response.statusCode) &&
          retryCount < _maxRetries) {
        await _backoffDelay(retryCount);
        return _request(method, path,
            body: body,
            queryParams: queryParams,
            timeout: timeout,
            retryCount: retryCount + 1);
      }

      final result = _processResponse(response);
      AppLogger.api.fine('$method $path -> ${response.statusCode}');
      return result;
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await _backoffDelay(retryCount);
        return _request(method, path,
            body: body,
            queryParams: queryParams,
            timeout: timeout,
            retryCount: retryCount + 1);
      }
      AppLogger.api.warning('$method $path timed out (retry=$retryCount)');
      throw ApiException(0, 'Request timed out. Please try again.');
    } on SocketException {
      AppLogger.api.warning('$method $path network error (retry=$retryCount)');
      if (retryCount < _maxRetries) {
        await _backoffDelay(retryCount);
        return _request(method, path,
            body: body,
            queryParams: queryParams,
            timeout: timeout,
            retryCount: retryCount + 1);
      }
      throw ApiException(
          0, 'No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      AppLogger.api.warning('$method $path client error: ${e.message} (retry=$retryCount)');
      if (retryCount < _maxRetries) {
        await _backoffDelay(retryCount);
        return _request(method, path,
            body: body,
            queryParams: queryParams,
            timeout: timeout,
            retryCount: retryCount + 1);
      }
      throw ApiException(0, 'Connection error: ${e.message}');
    }
  }

  /// Returns true for status codes that may succeed on retry (server errors).
  bool _isTransientStatusCode(int statusCode) {
    return statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        statusCode == 429;
  }

  /// Exponential backoff with jitter: 2^retry * 1s base + random 0-500ms
  Future<void> _backoffDelay(int retryCount) {
    final baseMs = (pow(2, retryCount) * 1000).toInt();
    final jitter = Random().nextInt(501);
    return Future.delayed(Duration(milliseconds: baseMs + jitter));
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message;
    if (body is Map) {
      message = body['error'] as String? ?? 'Unknown error';
      final details = body['details'];
      if (details is List && details.isNotEmpty) {
        final detailMessages = details.map((d) {
          final field = d['field'] ?? '';
          final msg = d['message'] ?? '';
          return field.isNotEmpty ? '$field: $msg' : msg;
        }).join('\n');
        message = '$message\n$detailMessages';
      }
    } else {
      message = 'Unknown error';
    }
    throw ApiException(response.statusCode, message);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return false;

      final uri = Uri.parse('${Endpoints.baseUrl}${Endpoints.refresh}');
      final response = await _client
          .post(uri, headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(_refreshTimeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final body = jsonDecode(response.body);
        if (body is Map) {
          final newToken = body['token'] as String?;
          if (newToken != null && newToken.isNotEmpty) {
            await _storage.saveToken(newToken);
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>> download(String path,
      {Map<String, String>? queryParams, Duration? timeout}) async {
    timeout ??= const Duration(seconds: 60);
    try {
      final uri = Uri.parse('${Endpoints.baseUrl}$path')
          .replace(queryParameters: queryParams);
      final headers = await _headers();
      headers.remove('Content-Type');
      final response = await _client
          .get(uri, headers: headers)
          .timeout(timeout);
      if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final newHeaders = await _headers();
          newHeaders.remove('Content-Type');
          final retry = await _client
              .get(uri, headers: newHeaders)
              .timeout(timeout);
          if (retry.statusCode == 200) return retry.bodyBytes.toList();
        }
        await _storage.clear();
        onUnauthorized?.call();
        throw ApiException(401, 'Session expired. Please login again.');
      }
      if (response.statusCode != 200) {
        throw ApiException(response.statusCode, 'Download failed');
      }
      return response.bodyBytes.toList();
    } on TimeoutException {
      throw ApiException(0, 'Download timed out');
    } on SocketException {
      throw ApiException(0, 'No internet connection');
    }
  }

  void dispose() {
    _client.close();
  }
}
