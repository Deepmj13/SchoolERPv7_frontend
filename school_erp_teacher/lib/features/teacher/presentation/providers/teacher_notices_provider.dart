import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

final teacherNoticesProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getNotices();
});
