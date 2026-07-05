import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/data/student_repository.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_repository_provider.dart';

class RemarksState {
  final List<StudentRemark> remarks;
  final bool isLoading;
  final String? errorMessage;

  RemarksState({this.remarks = const [], this.isLoading = false, this.errorMessage});

  RemarksState copyWith({List<StudentRemark>? remarks, bool? isLoading, String? Function()? errorMessage}) =>
      RemarksState(
        remarks: remarks ?? this.remarks,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      );
}

class RemarksStateNotifier extends StateNotifier<RemarksState> {
  final StudentRepository _repo;
  final String _studentId;

  RemarksStateNotifier(this._repo, this._studentId) : super(RemarksState()) {
    _loadRemarks();
  }

  Future<void> _loadRemarks() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final remarks = await _repo.getRemarks(_studentId);
      state = state.copyWith(remarks: remarks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Failed to load remarks: $e');
    }
  }

  Future<void> markAsRead(String remarkId) async {
    try {
      await _repo.markRemarkRead(remarkId);
      state = state.copyWith(
        remarks: state.remarks.map((r) {
          if (r.id == remarkId) {
            return StudentRemark(
              id: r.id,
              teacherName: r.teacherName,
              type: r.type,
              category: r.category,
              message: r.message,
              isRead: true,
              createdAt: r.createdAt,
            );
          }
          return r;
        }).toList(),
      );
    } catch (_) {}
  }

  Future<void> refresh() => _loadRemarks();
}

final studentRemarksProvider =
    StateNotifierProvider<RemarksStateNotifier, RemarksState>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  final studentId = ref.watch(authStateProvider).user?.studentId ?? '';
  return RemarksStateNotifier(repo, studentId);
});
