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

  static const String dashboardStats = '$apiPrefix/admin/dashboard/stats';
  static const String schoolProfile = '$apiPrefix/admin/school';

  static const String students = '$apiPrefix/students';
  static String student(String id) => '$apiPrefix/students/$id';
  static String activateStudent(String id) =>
      '$apiPrefix/students/$id/activate';
  static const String studentsPromote = '$apiPrefix/students/promote';

  static const String teachers = '$apiPrefix/teachers';
  static String teacher(String id) => '$apiPrefix/teachers/$id';
  static String teacherClasses(String id) => '$apiPrefix/teachers/$id/classes';
  static String teacherSubjects(String id) => '$apiPrefix/teachers/$id/subjects';
  static String teacherTimetable(String id) => '$apiPrefix/teachers/$id/timetable';

  static const String classes = '$apiPrefix/classes';
  static String classById(String id) => '$apiPrefix/classes/$id';
  static String classStudents(String id) => '$apiPrefix/classes/$id/students';
  static String classTimetable(String id) => '$apiPrefix/classes/$id/timetable';

  static const String attendanceMark = '$apiPrefix/attendance/mark';
  static const String attendance = '$apiPrefix/attendance';
  static String attendanceRecord(String id) => '$apiPrefix/attendance/$id';
  static String studentAttendance(String id) =>
      '$apiPrefix/attendance/student/$id';

  static const String subjects = '$apiPrefix/subjects';
  static const String subjectsByClass = '$apiPrefix/subjects/by-class';
  static String assignSubject(String id) => '$apiPrefix/subjects/$id/assign';

  static const String exams = '$apiPrefix/exams';
  static String exam(String id) => '$apiPrefix/exams/$id';
  static String examClasses(String examId) => '$apiPrefix/exams/$examId/classes';
  static String publishExam(String id) => '$apiPrefix/exams/$id/publish';

  static const String timetable = '$apiPrefix/timetable';
  static String timetableEntry(String id) => '$apiPrefix/timetable/$id';

  static const String proxyAssign = '$apiPrefix/proxy/assign';
  static String proxyRespond(String id) => '$apiPrefix/proxy/$id/respond';
  static String proxyCancel(String id) => '$apiPrefix/proxy/$id';
  static String proxyTodayForClass(String classId) =>
      '$apiPrefix/proxy/today?classId=$classId';
  static String proxyAvailable(String timetableId) =>
      '$apiPrefix/proxy/available?timetableId=$timetableId';
  static const String proxyAdminAll = '$apiPrefix/proxy/admin/all';

  static const String feeStructures = '$apiPrefix/fees/structures';
  static const String feesPending = '$apiPrefix/fees/pending';
  static const String feesPayments = '$apiPrefix/fees/payments';
  static String studentFees(String id) => '$apiPrefix/fees/student/$id';
  static const String feePosts = '$apiPrefix/fees/posts';
  static String feePost(String id) => '$apiPrefix/fees/posts/$id';
  static const String feesUnpaid = '$apiPrefix/fees/unpaid';

  static const String announcements = '$apiPrefix/announcements';
  static String announcement(String id) => '$apiPrefix/announcements/$id';

  static const String reportStudentStrength = '$apiPrefix/reports/student-strength';
  static const String reportAttendance = '$apiPrefix/reports/attendance';
  static const String reportFeeCollection = '$apiPrefix/reports/fee-collection';
  static const String reportTeacherWorkload = '$apiPrefix/reports/teacher-workload';
  static const String reportAdmissions = '$apiPrefix/reports/admissions';

  static const String gradingSystems = '$apiPrefix/grading';
  static String gradingSystem(String id) => '$apiPrefix/grading/$id';
  static const String gradingFindGrade = '$apiPrefix/grading/find-grade';

  static String examSubjects(String examId) => '$apiPrefix/exams/$examId/subjects';
  static String examSubject(String examId, String subjectId) =>
      '$apiPrefix/exams/$examId/subjects/$subjectId';

  static const String staff = '$apiPrefix/staff';
  static String staffMember(String id) => '$apiPrefix/staff/$id';
  static const String staffDepartments = '$apiPrefix/staff/departments';

  static const String holidays = '$apiPrefix/holidays';
  static String holiday(String id) => '$apiPrefix/holidays/$id';

  static const String resultsBulk = '$apiPrefix/results/bulk';
  static const String results = '$apiPrefix/results';
  static String studentResults(String id) => '$apiPrefix/results/student/$id';
}
