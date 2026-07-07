import 'package:school_erp_admin/core/api/api_client.dart';
import 'package:school_erp_admin/core/api/endpoints.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';

class AdminRepository {
  final ApiClient _api;

  AdminRepository(this._api);

  Future<DashboardStats> getDashboardStats() async {
    try {
      final data = await _api.get(Endpoints.dashboardStats);
      return DashboardStats.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse dashboard statistics: $e');
    }
  }

  Future<List<Student>> getStudents() async {
    try {
      final raw = await _api.get(Endpoints.students);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => Student.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse student data: $e');
    }
  }

  Future<PaginatedResponse<Student>> getStudentsPage({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      final data = await _api.get(Endpoints.students, queryParams: params);
      return PaginatedResponse.fromJson(data, Student.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse student data: $e');
    }
  }

  Future<Student> createStudent(Map<String, dynamic> body) async {
    try {
      final data = await _api.post(Endpoints.students, body: body);
      return Student.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create student: $e');
    }
  }

  Future<Student> updateStudent(String id, Map<String, dynamic> body) async {
    try {
      final data = await _api.put(Endpoints.student(id), body: body);
      return Student.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to update student: $e');
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _api.delete(Endpoints.student(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to delete student: $e');
    }
  }

  Future<List<Teacher>> getTeachers() async {
    try {
      final raw = await _api.get(Endpoints.teachers);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => Teacher.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse teacher data: $e');
    }
  }

  Future<PaginatedResponse<Teacher>> getTeachersPage({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      final data = await _api.get(Endpoints.teachers, queryParams: params);
      return PaginatedResponse.fromJson(data, Teacher.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse teacher data: $e');
    }
  }

  Future<Teacher> createTeacher(Map<String, dynamic> body) async {
    try {
      final data = await _api.post(Endpoints.teachers, body: body);
      return Teacher.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create teacher: $e');
    }
  }

  Future<Teacher> updateTeacher(String id, Map<String, dynamic> body) async {
    try {
      final data = await _api.put(Endpoints.teacher(id), body: body);
      return Teacher.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to update teacher: $e');
    }
  }

  Future<void> deleteTeacher(String id) async {
    try {
      await _api.delete(Endpoints.teacher(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to delete teacher: $e');
    }
  }

  Future<List<TeacherAssignment>> getTeacherAssignments(String id) async {
    try {
      final data = await _api.get(Endpoints.teacherClasses(id));
      return (data as List).map((e) => TeacherAssignment.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse teacher assignments: $e');
    }
  }

  Future<List<Subject>> getSubjects() async {
    try {
      final raw = await _api.get(Endpoints.subjects);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => Subject.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse subjects: $e');
    }
  }

  Future<void> assignSubjectToTeacher(
      String subjectId, String teacherId, String classId) async {
    try {
      await _api.post(Endpoints.assignSubject(subjectId), body: {
        'teacher_id': teacherId,
        'class_id': classId,
      });
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to assign subject: $e');
    }
  }

  Future<List<ClassModel>> getClasses() async {
    try {
      final raw = await _api.get(Endpoints.classes);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => ClassModel.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse class data: $e');
    }
  }

  Future<PaginatedResponse<ClassModel>> getClassesPage({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      final data = await _api.get(Endpoints.classes, queryParams: params);
      return PaginatedResponse.fromJson(data, ClassModel.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse class data: $e');
    }
  }

  Future<ClassModel> createClass(Map<String, dynamic> body) async {
    try {
      final data = await _api.post(Endpoints.classes, body: body);
      return ClassModel.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create class: $e');
    }
  }

  Future<ClassModel> updateClass(String id, Map<String, dynamic> body) async {
    try {
      final data = await _api.put(Endpoints.classById(id), body: body);
      return ClassModel.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to update class: $e');
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      await _api.delete(Endpoints.classById(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to delete class: $e');
    }
  }

  Future<List<Student>> getClassStudents(String id) async {
    try {
      final data = await _api.get(Endpoints.classStudents(id));
      return (data as List).map((e) => Student.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse class roster: $e');
    }
  }

  Future<List<Announcement>> getAnnouncements({String? classId}) async {
    try {
      final raw = await _api.get(
        Endpoints.announcements,
        queryParams: classId != null ? {'classId': classId} : null,
      );
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => Announcement.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse announcements: $e');
    }
  }

  Future<PaginatedResponse<Announcement>> getAnnouncementsPage({
    int page = 1,
    int limit = 20,
    String? search,
    String? classId,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (classId != null) params['classId'] = classId;
      final data = await _api.get(Endpoints.announcements, queryParams: params);
      return PaginatedResponse.fromJson(data, Announcement.fromJson);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse announcements: $e');
    }
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> body) async {
    try {
      final data = await _api.post(Endpoints.announcements, body: body);
      return Announcement.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create announcement: $e');
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _api.delete(Endpoints.announcement(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to delete announcement: $e');
    }
  }

  Future<Announcement> updateAnnouncement(
      String id, Map<String, dynamic> body) async {
    try {
      final data =
          await _api.put(Endpoints.announcement(id), body: body);
      return Announcement.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to update announcement: $e');
    }
  }

  Future<Subject> createSubject(String name) async {
    try {
      final data = await _api.post(Endpoints.subjects, body: {'name': name});
      return Subject.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create subject: $e');
    }
  }

  Future<void> activateStudent(String id) async {
    try {
      await _api.patch(Endpoints.activateStudent(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to activate/deactivate student: $e');
    }
  }

  Future<List<Exam>> getExams() async {
    try {
      final raw = await _api.get(Endpoints.exams);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => Exam.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse exams: $e');
    }
  }

  Future<Exam> createExam(Map<String, dynamic> body) async {
    try {
      final data = await _api.post(Endpoints.exams, body: body);
      return Exam.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create exam: $e');
    }
  }

  Future<Exam> publishExam(String id, bool isPublished) async {
    try {
      final data = await _api.patch(Endpoints.publishExam(id),
          body: {'is_published': isPublished});
      return Exam.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to publish exam: $e');
    }
  }

  Future<void> deleteExam(String id) async {
    try {
      await _api.delete(Endpoints.exam(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to delete exam: $e');
    }
  }

  Future<List<TimetableEntry>> getClassTimetable(String classId) async {
    try {
      final data = await _api.get(Endpoints.classTimetable(classId));
      return (data as List).map((e) => TimetableEntry.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse timetable: $e');
    }
  }

  Future<void> createTimetableEntry(Map<String, dynamic> body) async {
    try {
      await _api.post(Endpoints.timetable, body: body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create timetable entry: $e');
    }
  }

  Future<void> updateTimetableEntry(
      String id, Map<String, dynamic> body) async {
    try {
      await _api.put(Endpoints.timetableEntry(id), body: body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to update timetable entry: $e');
    }
  }

  Future<void> deleteTimetableEntry(String id) async {
    try {
      await _api.delete(Endpoints.timetableEntry(id));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to delete timetable entry: $e');
    }
  }

  Future<List<FeeStructure>> getFeeStructures() async {
    try {
      final raw = await _api.get(Endpoints.feeStructures);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => FeeStructure.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse fee structures: $e');
    }
  }

  Future<FeeStructure> createFeeStructure(Map<String, dynamic> body) async {
    try {
      final data = await _api.post(Endpoints.feeStructures, body: body);
      return FeeStructure.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create fee structure: $e');
    }
  }

  Future<List<FeePayment>> getPendingFees() async {
    try {
      final raw = await _api.get(Endpoints.feesPending);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => FeePayment.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse pending fees: $e');
    }
  }

  Future<List<UnpaidFeeItem>> getUnpaidFees({String? classId, String? paymentFilter}) async {
    try {
      final params = <String, String>{};
      if (classId != null && classId.isNotEmpty) params['class_id'] = classId;
      if (paymentFilter != null && paymentFilter.isNotEmpty) params['payment_filter'] = paymentFilter;
      final raw = await _api.get(
        Endpoints.feesUnpaid,
        queryParams: params.isNotEmpty ? params : null,
      );
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => UnpaidFeeItem.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse unpaid fees: $e');
    }
  }

  Future<void> recordFeePayment(Map<String, dynamic> body) async {
    try {
      await _api.post(Endpoints.feesPayments, body: body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to record payment: $e');
    }
  }

  Future<Map<String, dynamic>> createFeePost(Map<String, dynamic> body) async {
    try {
      final data = await _api.post(Endpoints.feePosts, body: body);
      return data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to create fee post: $e');
    }
  }

  Future<List<FeePost>> getFeePosts() async {
    try {
      final raw = await _api.get(Endpoints.feePosts);
      final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
      return list.map((e) => FeePost.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to load fee posts: $e');
    }
  }

  Future<FeePost> getFeePost(String id) async {
    try {
      final data = await _api.get(Endpoints.feePost(id));
      return FeePost.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to load fee post: $e');
    }
  }

  Future<List<AttendanceRecord>> getAttendance(
      String classId, String date) async {
    try {
      final data = await _api.get(
        Endpoints.attendance,
        queryParams: {'classId': classId, 'date': date},
      );
      return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Failed to parse attendance data: $e');
    }
  }
}
