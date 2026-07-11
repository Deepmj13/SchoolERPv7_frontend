import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

final myProxiesProvider =
    FutureProvider.autoDispose<List<ProxyAssignment>>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getMyProxies();
});

final pendingProxiesProvider =
    FutureProvider.autoDispose<List<ProxyAssignment>>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getPendingProxies();
});

class ProxyController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ProxyController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> assignProxy(
      String timetableId, String proxyTeacherId, String? reason) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(teacherRepositoryProvider);
      await repo.assignProxy(timetableId, proxyTeacherId, reason);
      _ref.invalidate(myProxiesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> respondToProxy(String proxyId, String status) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(teacherRepositoryProvider);
      await repo.respondToProxy(proxyId, status);
      _ref.invalidate(myProxiesProvider);
      _ref.invalidate(pendingProxiesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> cancelProxy(String proxyId) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(teacherRepositoryProvider);
      await repo.cancelProxy(proxyId);
      _ref.invalidate(myProxiesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableTeachers(
      String timetableId) async {
    final repo = _ref.read(teacherRepositoryProvider);
    return repo.getAvailableTeachers(timetableId);
  }
}

final proxyControllerProvider =
    StateNotifierProvider<ProxyController, AsyncValue<void>>((ref) {
  return ProxyController(ref);
});
