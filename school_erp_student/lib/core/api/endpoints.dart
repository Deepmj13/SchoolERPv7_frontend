class Endpoints {
  Endpoints._();

  static const String baseUrl = 'https://renderbackned.onrender.com';
  static const String apiPrefix = '/api';

  static const String login = '$apiPrefix/auth/login';
  static const String refresh = '$apiPrefix/auth/refresh';
  static const String changePassword = '$apiPrefix/auth/change-password';

  static String studentProfile(String id) => '$apiPrefix/students/$id';
  static String studentAttendance(String id) =>
      '$apiPrefix/attendance/student/$id';
  static String studentResults(String id) => '$apiPrefix/results/student/$id';
  static String studentFees(String id) => '$apiPrefix/fees/student/$id';

  static const String assignments = '$apiPrefix/assignments';
  static String assignment(String id) => '$apiPrefix/assignments/$id';

  static const String timetable = '$apiPrefix/timetable';

  static const String notices = '$apiPrefix/announcements';
  static String notice(String id) => '$apiPrefix/announcements/$id';

  static const String classes = '$apiPrefix/classes';
  static String classById(String id) => '$apiPrefix/classes/$id';
  static String classTimetable(String id) => '$apiPrefix/classes/$id/timetable';
}
