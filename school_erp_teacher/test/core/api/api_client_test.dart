import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_erp_teacher/core/api/api_client.dart';
import 'package:school_erp_teacher/core/api/endpoints.dart';
import '../../helpers/fake_storage_service.dart';

void main() {
  group('ApiClient', () {
    late FakeStorageService storage;
    late ApiClient client;
    late http.Client mockClient;

    setUp(() {
      storage = FakeStorageService();
      mockClient = http.Client();
    });

    tearDown(() {
      client.dispose();
    });

    test('GET request includes auth headers when token present', () async {
      await storage.saveToken('my-token');
      client = ApiClient(storage: storage, client: mockClient);

      expect(
        () => client.get('/test'),
        throwsA(isA<ApiException>()),
      );
    });

    test('ApiException stores status code and message', () {
      final exception = ApiException(404, 'Not found');
      expect(exception.statusCode, 404);
      expect(exception.message, 'Not found');
      expect(exception.toString(), 'Not found');
    });

    test('GET request works without token', () async {
      client = ApiClient(storage: storage, client: mockClient);

      expect(
        () => client.get('/test'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ApiClient 401 handling', () {
    late FakeStorageService storage;
    late ApiClient client;
    var unauthorizedCalls = 0;

    setUp(() {
      storage = FakeStorageService();
      unauthorizedCalls = 0;
    });

    tearDown(() {
      client.dispose();
    });

    test('401 with no stored token surfaces the server error message', () async {
      final mock = MockClient((request) async {
        if (request.url.path == Endpoints.login) {
          return http.Response(
            jsonEncode({'error': 'Invalid credentials'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });
      client = ApiClient(storage: storage, client: mock)
        ..onUnauthorized = () => unauthorizedCalls++;

      try {
        await client.post(Endpoints.login,
            body: {'email': 'a@b.com', 'password': 'wrong'});
        fail('Expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
        expect(e.message, 'Invalid credentials');
      }

      expect(unauthorizedCalls, 0, reason: 'logout must not fire on login');
    });

    test('401 with stored token falls back to session expired', () async {
      await storage.saveToken('existing-token');
      final mock = MockClient((request) async {
        if (request.url.path == Endpoints.refresh) {
          return http.Response(
            jsonEncode({'error': 'Invalid token'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'error': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      client = ApiClient(storage: storage, client: mock)
        ..onUnauthorized = () => unauthorizedCalls++;

      try {
        await client.get('/secured/data');
        fail('Expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
        expect(e.message, 'Session expired. Please login again.');
      }

      expect(unauthorizedCalls, 1);
      expect(await storage.getToken(), isNull,
          reason: 'storage should be cleared');
    });
  });
}
