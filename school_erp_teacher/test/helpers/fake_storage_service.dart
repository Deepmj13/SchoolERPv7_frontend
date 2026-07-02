import 'package:school_erp_teacher/core/storage/storage_interface.dart';

class FakeStorageService implements StorageInterface {
  final _store = <String, String>{};

  @override
  Future<void> saveToken(String token) async {
    _store['jwt_token'] = token;
  }

  @override
  Future<String?> getToken() async {
    return _store['jwt_token'];
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    _store['user_profile'] = user.toString();
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final data = _store['user_profile'];
    return data != null ? {} : null;
  }

  @override
  Future<void> clear() async {
    _store.remove('jwt_token');
    _store.remove('user_profile');
  }
}
