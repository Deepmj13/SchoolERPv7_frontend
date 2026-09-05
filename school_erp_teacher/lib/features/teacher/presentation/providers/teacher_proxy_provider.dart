import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

class ProxyController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ProxyController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> assignProxy(
      String timetableId, String proxyTeacherId, String? reason,
      {String? date}) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(teacherRepositoryProvider);
      await repo.assignProxy(timetableId, proxyTeacherId, reason, date: date);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableTeachers(
      String timetableId, {String? date}) async {
    final repo = _ref.read(teacherRepositoryProvider);
    return repo.getAvailableTeachers(timetableId, date: date);
  }
}

final proxyControllerProvider =
    StateNotifierProvider<ProxyController, AsyncValue<void>>((ref) {
  return ProxyController(ref);
});
