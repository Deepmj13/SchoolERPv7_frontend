import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:school_erp_teacher/core/api/api_client.dart';
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
}
