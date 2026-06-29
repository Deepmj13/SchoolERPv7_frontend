import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/data/student_repository.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_repository_provider.dart';

class AttendancePageState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? errorMessage;

  AttendancePageState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AttendancePageState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? errorMessage,
  }) =>
      AttendancePageState(
        records: records ?? this.records,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class AttendancePageNotifier extends StateNotifier<AttendancePageState> {
  final StudentRepository _repo;

  AttendancePageNotifier(this._repo) : super(AttendancePageState());

  Future<void> loadAttendance(String studentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final records = await _repo.getAttendance(studentId);
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load attendance: $e',
      );
    }
  }
}

final attendancePageProvider =
    StateNotifierProvider<AttendancePageNotifier, AttendancePageState>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return AttendancePageNotifier(repo);
});

final attendanceOverviewProvider =
    FutureProvider<AttendanceSummary>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final studentId = authState.user?.studentId ?? '';

  final records = await repo.getAttendance(studentId);
  final total = records.length;
  final present = records.where((r) => r.status == 'present').length;
  final absent = total - present;

  return AttendanceSummary(
    month: 'Overall',
    total: total,
    present: present,
    absent: absent,
    percentage: total > 0 ? (present / total) * 100 : 0,
  );
});
