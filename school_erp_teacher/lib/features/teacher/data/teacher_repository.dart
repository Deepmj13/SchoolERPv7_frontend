import 'package:school_erp_teacher/core/api/api_client.dart';
import 'package:school_erp_teacher/core/api/endpoints.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';

class TeacherRepository {
  final ApiClient _api;

  TeacherRepository(this._api);

  Future<List<TeacherClass>> getTeacherClasses(String teacherId) async {
    final data = await _api.get(Endpoints.teacherClasses(teacherId));
    return (data as List)
        .map((e) => TeacherClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClassModel>> getClasses() async {
    final raw = await _api.get(Endpoints.classes);
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Student>> getClassStudents(String classId) async {
    final data = await _api.get(Endpoints.classStudents(classId));
    return (data as List)
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAttendance(
      String classId, String date, List<Map<String, dynamic>> records) async {
    await _api.post(Endpoints.attendanceMark, body: {
      'classId': classId,
      'date': date,
      'records': records,
    });
  }

  Future<List<AttendanceRecord>> getAttendance(
      String classId, String date) async {
    final data = await _api.get(Endpoints.attendance,
        queryParams: {'classId': classId, 'date': date});
    return (data as List)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Exam>> getExams() async {
    final raw = await _api.get(Endpoints.exams);
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => Exam.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Subject>> getSubjects() async {
    final raw = await _api.get(Endpoints.subjects);
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> bulkEnterMarks(
      String examId, String subjectId, List<Map<String, dynamic>> marks) async {
    await _api.post(Endpoints.marksBulk, body: {
      'examId': examId,
      'subjectId': subjectId,
      'marks': marks,
    });
  }

  Future<List<TimetableEntry>> getClassTimetable(String classId) async {
    final data = await _api.get(Endpoints.classTimetable(classId));
    return (data as List)
        .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Announcement>> getTeacherAnnouncements(String teacherId) async {
    final raw = await _api.get(Endpoints.teacherAnnouncements(teacherId));
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Announcement> createAnnouncement(
      String title, String? body, String? classId) async {
    final data = await _api.post(Endpoints.announcements, body: {
      'title': title,
      if (body != null) 'body': body,
      if (classId != null) 'class_id': classId,
    });
    return Announcement.fromJson(data as Map<String, dynamic>);
  }

  Future<ClassModel?> getClassTeacherClass(String teacherId) async {
    final data = await _api.get(Endpoints.teacherClassTeacherClass(teacherId));
    if (data == null) return null;
    return ClassModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getResults(
      String examId, String subjectId, String? classId) async {
    final raw = await _api
        .get(Endpoints.resultsByExam(examId, subjectId, classId: classId));
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Assignment>> getAssignments(String teacherId) async {
    final raw = await _api.get(Endpoints.assignments,
        queryParams: {'teacherId': teacherId});
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Assignment> createAssignment(
      String title, String? description, String? dueDate,
      String classId, String subjectId) async {
    final data = await _api.post(Endpoints.assignments, body: {
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate,
      'class_id': classId,
      'subject_id': subjectId,
    });
    return Assignment.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AssignmentSubmission>> getAssignmentSubmissions(
      String assignmentId) async {
    final data = await _api.get(Endpoints.assignmentSubmissions(assignmentId));
    return (data as List)
        .map((e) => AssignmentSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> bulkUpdateSubmissions(String assignmentId,
      List<Map<String, dynamic>> submissions) async {
    await _api.put(Endpoints.assignmentSubmissions(assignmentId), body: {
      'submissions': submissions,
    });
  }

  Future<List<Announcement>> getNotices() async {
    final raw = await _api.get(Endpoints.announcements);
    final list = raw is Map<String, dynamic> ? raw['data'] as List : raw as List;
    return list
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherProfile> getTeacherProfile(String teacherId) async {
    final data = await _api.get(Endpoints.teacherProfile(teacherId));
    return TeacherProfile.fromJson(data as Map<String, dynamic>);
  }
}
