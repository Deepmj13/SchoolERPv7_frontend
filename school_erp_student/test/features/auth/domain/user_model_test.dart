import 'package:flutter_test/flutter_test.dart';
import 'package:school_erp_student/features/auth/domain/user_model.dart';

void main() {
  group('UserModel', () {
    final validJson = {
      'token': 'test-token-456',
      'role': 'student',
      'userId': 'user-2',
      'teacherId': null,
      'studentId': 'student-1',
    };

    test('fromJson creates UserModel with student role', () {
      final user = UserModel.fromJson(validJson);
      expect(user.token, 'test-token-456');
      expect(user.role, 'student');
      expect(user.userId, 'user-2');
      expect(user.studentId, 'student-1');
      expect(user.teacherId, isNull);
    });

    test('isStudent returns true for student role', () {
      final user = UserModel.fromJson(validJson);
      expect(user.isStudent, isTrue);
    });

    test('isStudent returns false for non-student role', () {
      final json = {...validJson, 'role': 'teacher'};
      final user = UserModel.fromJson(json);
      expect(user.isStudent, isFalse);
    });

    test('toJson round-trips correctly', () {
      final user = UserModel.fromJson(validJson);
      final json = user.toJson();
      expect(json['token'], 'test-token-456');
      expect(json['role'], 'student');
      expect(json['userId'], 'user-2');
      expect(json['studentId'], 'student-1');
    });

    test('fromJson handles null studentId', () {
      final json = {...validJson, 'studentId': null};
      final user = UserModel.fromJson(json);
      expect(user.studentId, isNull);
    });
  });
}
