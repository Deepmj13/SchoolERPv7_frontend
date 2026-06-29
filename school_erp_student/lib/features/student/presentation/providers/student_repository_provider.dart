import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/data/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return StudentRepository(api);
});
