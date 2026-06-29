import 'package:school_erp_teacher/core/api/api_client.dart';
import 'package:school_erp_teacher/core/api/endpoints.dart';
import 'package:school_erp_teacher/features/auth/domain/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post(Endpoints.login, body: {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _apiClient.post(Endpoints.changePassword, body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }
}
