import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_repository_provider.dart';

final studentResultsProvider =
    FutureProvider.autoDispose<List<ResultEntry>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final studentId = authState.user?.studentId ?? '';

  final results = await repo.getResults(studentId);
  return results;
});
