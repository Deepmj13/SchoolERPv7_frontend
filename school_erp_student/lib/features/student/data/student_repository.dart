import 'package:school_erp_student/core/api/api_client.dart';
import 'package:school_erp_student/core/api/endpoints.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';

class StudentRepository {
  final ApiClient _api;

  StudentRepository(this._api);

  Future<StudentProfile> getProfile(String studentId) async {
    final data = await _api.get(Endpoints.studentProfile(studentId));
    return StudentProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AttendanceRecord>> getAttendance(String studentId) async {
    final data = await _api.get(Endpoints.studentAttendance(studentId));
    if (data is List) {
      return data
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ResultEntry>> getResults(String studentId) async {
    final data = await _api.get(Endpoints.studentResults(studentId));
    if (data is List) {
      return data
          .map((e) => ResultEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getFees(String studentId) async {
    final data = await _api.get(Endpoints.studentFees(studentId));
    return data as Map<String, dynamic>? ?? {};
  }

  Future<List<Assignment>> getAssignments() async {
    final raw = await _api.get(Endpoints.assignments);
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Notice>> getNotices() async {
    final raw = await _api.get(Endpoints.notices);
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => Notice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimetableEntry>> getTimetable(String classId) async {
    final data = await _api.get(Endpoints.classTimetable(classId));
    if (data is List) {
      return data
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<StudentRemark>> getRemarks(String studentId) async {
    final data = await _api.get(Endpoints.studentRemarks(studentId));
    if (data is List) {
      return data
          .map((e) => StudentRemark.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> markRemarkRead(String remarkId) async {
    await _api.patch(Endpoints.markRemarkRead(remarkId));
  }

  Future<List<Holiday>> getHolidays() async {
    final data = await _api.get(Endpoints.holidays);
    if (data is List) {
      return data
          .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
