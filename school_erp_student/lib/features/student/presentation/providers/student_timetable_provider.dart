import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/logging/app_logger.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_repository_provider.dart';

final studentTimetableProvider =
    FutureProvider.autoDispose<List<TimetableEntry>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final studentId = authState.user?.studentId ?? '';

  if (studentId.isEmpty) {
    AppLogger.api.warning('studentTimetableProvider: studentId is empty');
    return [];
  }

  String? classId;
  try {
    final profile = await repo.getProfile(studentId);
    classId = profile.classId;
  } catch (e) {
    AppLogger.api.warning('studentTimetableProvider: profile fetch failed: $e');
  }

  if (classId == null) return [];

  try {
    final entries = await repo.getTimetable(classId);
    return entries;
  } catch (e) {
    AppLogger.api.warning('studentTimetableProvider: timetable fetch failed: $e');
    return [];
  }
});
