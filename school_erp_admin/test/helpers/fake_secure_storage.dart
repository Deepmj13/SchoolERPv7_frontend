/// In-memory implementation of FlutterSecureStorage for testing.
class FakeFlutterSecureStorage {
  final _store = <String, String>{};

  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  Future<String?> read({required String key}) async {
    return _store[key];
  }

  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}
