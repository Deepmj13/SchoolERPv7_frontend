import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/logging/app_logger.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_repository_provider.dart';

final studentDashboardProvider =
    FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final studentId = authState.user?.studentId ?? '';

  if (studentId.isEmpty) {
    AppLogger.api.warning('studentDashboardProvider: studentId is empty');
  }

  String studentName = '';
  AttendanceSummary? attendanceSummary;

  try {
    final profile = await repo.getProfile(studentId);
    studentName = profile.fullName;
  } catch (e) {
    AppLogger.api.warning('studentDashboardProvider: profile fetch failed: $e');
  }

  try {
    final records = await repo.getAttendance(studentId);
    if (records.isNotEmpty) {
      final total = records.length;
      final present =
          records.where((r) => r.status == 'present').length;
      final absent = total - present;
      attendanceSummary = AttendanceSummary(
        month: '',
        total: total,
        present: present,
        absent: absent,
        percentage: total > 0 ? (present / total) * 100 : 0,
      );
    }
  } catch (e) {
    AppLogger.api.warning('studentDashboardProvider: attendance fetch failed: $e');
  }

  List<Notice> recentNotices = [];
  try {
    final notices = await repo.getNotices();
    recentNotices = notices.take(3).toList();
  } catch (e) {
    AppLogger.api.warning('studentDashboardProvider: notices fetch failed: $e');
  }

  return DashboardData(
    studentName: studentName,
    attendanceSummary: attendanceSummary,
    recentNotices: recentNotices,
  );
});
