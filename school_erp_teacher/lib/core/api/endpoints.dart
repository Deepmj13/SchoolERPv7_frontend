class Endpoints {
  Endpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://renderbackned.onrender.com',
  );
  static const String apiPrefix = '/api/v1';

  static const String login = '$apiPrefix/auth/login';
  static const String refresh = '$apiPrefix/auth/refresh';
  static const String changePassword = '$apiPrefix/auth/change-password';

  static const String classes = '$apiPrefix/classes';
  static String classById(String id) => '$apiPrefix/classes/$id';
  static String classStudents(String id) => '$apiPrefix/classes/$id/students';
  static String classTimetable(String id) =>
      '$apiPrefix/classes/$id/timetable';

  static String teacherClasses(String id) => '$apiPrefix/teachers/$id/classes';
  static String teacherClassTeacherClass(String id) =>
      '$apiPrefix/teachers/$id/class-teacher-class';
  static String teacherProfile(String id) => '$apiPrefix/teachers/$id';

  static const String attendanceMark = '$apiPrefix/attendance/mark';
  static const String attendance = '$apiPrefix/attendance';
  static String attendanceRecord(String id) => '$apiPrefix/attendance/$id';
  static String studentAttendance(String id) =>
      '$apiPrefix/attendance/student/$id';

  static const String exams = '$apiPrefix/exams';
  static const String subjects = '$apiPrefix/subjects';
  static const String marksBulk = '$apiPrefix/results/bulk';
  static const String results = '$apiPrefix/results';
  static String resultsByExam(String examId, String subjectId, {String? classId}) =>
      '$apiPrefix/results?examId=$examId&subjectId=$subjectId${classId != null ? '&classId=$classId' : ''}';

  static const String announcements = '$apiPrefix/announcements';
  static String announcement(String id) => '$apiPrefix/announcements/$id';
  static String teacherAnnouncements(String id) =>
      '$apiPrefix/announcements/teacher/$id';

  static const String assignments = '$apiPrefix/assignments';
  static String assignment(String id) => '$apiPrefix/assignments/$id';
  static String assignmentSubmissions(String id) =>
      '$apiPrefix/assignments/$id/submissions';

  static const String timetable = '$apiPrefix/timetable';
  static String timetableEntry(String id) => '$apiPrefix/timetable/$id';

  static const String remarks = '$apiPrefix/remarks';
  static String teacherRemarks(String id) => '$apiPrefix/remarks/teacher/$id';
  static String teacherRemarksForStudent(String teacherId, String studentId) =>
      '$apiPrefix/remarks/teacher/$teacherId/student/$studentId';
}
