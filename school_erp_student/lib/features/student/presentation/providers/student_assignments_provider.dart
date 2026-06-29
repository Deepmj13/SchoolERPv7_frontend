import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_repository_provider.dart';

final studentAssignmentsProvider =
    FutureProvider.autoDispose<List<Assignment>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final assignments = await repo.getAssignments();
  return assignments;
});

final studentNoticesProvider =
    FutureProvider.autoDispose<List<Notice>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final notices = await repo.getNotices();
  return notices;
});
