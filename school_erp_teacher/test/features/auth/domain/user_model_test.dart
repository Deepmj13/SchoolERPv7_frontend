import 'package:flutter_test/flutter_test.dart';
import 'package:school_erp_teacher/features/auth/domain/user_model.dart';

void main() {
  group('UserModel', () {
    final validJson = {
      'token': 'test-token-123',
      'role': 'teacher',
      'userId': 'user-1',
      'teacherId': 'teacher-1',
      'studentId': null,
    };

    test('fromJson creates UserModel with teacher role', () {
      final user = UserModel.fromJson(validJson);
      expect(user.token, 'test-token-123');
      expect(user.role, 'teacher');
      expect(user.userId, 'user-1');
      expect(user.teacherId, 'teacher-1');
      expect(user.studentId, isNull);
    });

    test('isTeacher returns true for teacher role', () {
      final user = UserModel.fromJson(validJson);
      expect(user.isTeacher, isTrue);
    });

    test('isTeacher returns false for non-teacher role', () {
      final json = {...validJson, 'role': 'student'};
      final user = UserModel.fromJson(json);
      expect(user.isTeacher, isFalse);
    });

    test('toJson round-trips correctly', () {
      final user = UserModel.fromJson(validJson);
      final json = user.toJson();
      expect(json['token'], 'test-token-123');
      expect(json['role'], 'teacher');
      expect(json['userId'], 'user-1');
      expect(json['teacherId'], 'teacher-1');
      expect(json['studentId'], isNull);
    });

    test('fromJson handles null teacherId', () {
      final json = {...validJson, 'teacherId': null};
      final user = UserModel.fromJson(json);
      expect(user.teacherId, isNull);
    });
  });
}
