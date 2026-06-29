import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_interface.dart';

final storageServiceProvider = Provider<StorageInterface>((ref) {
  throw UnimplementedError('StorageService must be provided at app level');
});

class StorageService implements StorageInterface {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_profile';
  static const String _themeKey = 'theme_mode';

  final FlutterSecureStorage _secureStorage;

  StorageService(this._secureStorage);

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _secureStorage.write(key: _userKey, value: jsonEncode(user));
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final data = await _secureStorage.read(key: _userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  @override
  Future<void> saveThemeMode(String mode) async {
    await _secureStorage.write(key: _themeKey, value: mode);
  }

  @override
  Future<String?> getThemeMode() async {
    return _secureStorage.read(key: _themeKey);
  }

  @override
  Future<void> clear() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }
}
