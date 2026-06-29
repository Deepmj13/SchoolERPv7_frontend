import 'package:flutter_test/flutter_test.dart';
import 'package:school_erp_admin/features/auth/domain/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates UserModel with admin role', () {
      final json = {
        'token': 'test-token',
        'role': 'admin',
        'userId': 'u1',
      };
      final user = UserModel.fromJson(json);
      expect(user.token, 'test-token');
      expect(user.role, 'admin');
      expect(user.userId, 'u1');
      expect(user.isAdmin, isTrue);
      expect(user.teacherId, isNull);
      expect(user.studentId, isNull);
    });

    test('fromJson creates UserModel with teacher role', () {
      final json = {
        'token': 'token-2',
        'role': 'teacher',
        'userId': 'u2',
        'teacherId': 't1',
      };
      final user = UserModel.fromJson(json);
      expect(user.isAdmin, isFalse);
      expect(user.teacherId, 't1');
    });

    test('toJson round-trips', () {
      final json = {
        'token': 't1',
        'role': 'admin',
        'userId': 'u1',
      };
      final user = UserModel.fromJson(json);
      final output = user.toJson();
      expect(output['token'], 't1');
      expect(output['role'], 'admin');
      expect(output['userId'], 'u1');
    });
  });
}
