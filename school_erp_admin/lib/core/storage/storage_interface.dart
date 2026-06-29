abstract class StorageInterface {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveUser(Map<String, dynamic> user);
  Future<Map<String, dynamic>?> getUser();
  Future<void> saveThemeMode(String mode);
  Future<String?> getThemeMode();
  Future<void> clear();
}
