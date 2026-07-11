import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final selectedClassProvider = StateProvider<ClassModel?>((ref) => null);

final timetableEntriesProvider = FutureProvider<List<TimetableEntry>>((ref) {
  final selectedClass = ref.watch(selectedClassProvider);
  final classId = selectedClass?.id;
  if (classId == null) return Future.value([]);
  final repo = ref.watch(adminRepositoryProvider);
  final now = DateTime.now();
  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return repo.getClassTimetable(classId, date: todayStr).timeout(const Duration(seconds: 15));
});

class TimetableController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TimetableController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> createEntry(Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.createTimetableEntry(body);
      _ref.invalidate(timetableEntriesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateEntry(String id, Map<String, dynamic> body) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.updateTimetableEntry(id, body);
      _ref.invalidate(timetableEntriesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(adminRepositoryProvider);
      await repo.deleteTimetableEntry(id);
      _ref.invalidate(timetableEntriesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final timetableControllerProvider =
    StateNotifierProvider<TimetableController, AsyncValue<void>>((ref) {
  return TimetableController(ref);
});
