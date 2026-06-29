import 'package:flutter_test/flutter_test.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';

void main() {
  group('DashboardStats', () {
    test('fromJson parses correctly', () {
      final json = {
        'totalStudents': 100,
        'totalTeachers': 20,
        'totalClasses': 10,
        'todayAttendancePercentage': 85.5,
      };
      final stats = DashboardStats.fromJson(json);
      expect(stats.totalStudents, 100);
      expect(stats.totalTeachers, 20);
      expect(stats.totalClasses, 10);
      expect(stats.todayAttendancePercentage, 85.5);
    });
  });

  group('Student', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 's1',
        'user_id': 'u1',
        'full_name': 'John Doe',
        'class_id': 'c1',
        'roll_number': '10',
        'is_active': true,
        'class_name': 'Class 5',
        'class_section': 'A',
      };
      final student = Student.fromJson(json);
      expect(student.id, 's1');
      expect(student.fullName, 'John Doe');
      expect(student.isActive, isTrue);
      expect(student.className, 'Class 5');
    });
  });

  group('Teacher', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 't1',
        'user_id': 'u2',
        'full_name': 'Jane Smith',
        'is_active': true,
      };
      final teacher = Teacher.fromJson(json);
      expect(teacher.id, 't1');
      expect(teacher.fullName, 'Jane Smith');
      expect(teacher.isActive, isTrue);
    });
  });

  group('ClassModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'c1',
        'name': 'Class 5',
        'section': 'A',
        'student_count': 30,
      };
      final cls = ClassModel.fromJson(json);
      expect(cls.name, 'Class 5');
      expect(cls.section, 'A');
      expect(cls.studentCount, 30);
    });
  });

  group('Announcement', () {
    test('isSchoolWide is true when classId is null', () {
      final json = {
        'id': 'a1',
        'title': 'Test',
        'created_by': 'admin',
        'created_at': '2024-01-01',
      };
      final a = Announcement.fromJson(json);
      expect(a.isSchoolWide, isTrue);
    });

    test('isSchoolWide is false when classId is set', () {
      final json = {
        'id': 'a2',
        'title': 'Class Notice',
        'class_id': 'c1',
        'created_by': 'admin',
        'created_at': '2024-01-01',
      };
      final a = Announcement.fromJson(json);
      expect(a.isSchoolWide, isFalse);
    });
  });

  group('PaginatedResponse', () {
    test('parses flat array as single page', () {
      final json = [
        {'id': '1', 'full_name': 'A', 'user_id': 'u1', 'is_active': true},
        {'id': '2', 'full_name': 'B', 'user_id': 'u2', 'is_active': false},
      ];
      final result = PaginatedResponse.fromJson(json, Student.fromJson);
      expect(result.items.length, 2);
      expect(result.total, 2);
      expect(result.page, 1);
      expect(result.pages, 1);
    });

    test('parses paginated JSON', () {
      final json = {
        'data': [
          {'id': '1', 'full_name': 'A', 'user_id': 'u1', 'is_active': true},
        ],
        'total': 50,
        'page': 2,
        'pages': 5,
      };
      final result = PaginatedResponse.fromJson(json, Student.fromJson);
      expect(result.items.length, 1);
      expect(result.total, 50);
      expect(result.page, 2);
      expect(result.pages, 5);
    });
  });
}
