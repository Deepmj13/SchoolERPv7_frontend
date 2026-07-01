import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/features/teacher/data/teacher_repository.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

class AssignmentsState {
  final List<Assignment> assignments;
  final Assignment? selectedAssignment;
  final List<AssignmentSubmission> submissions;
  final Map<String, String> statuses;
  final Map<String, String> remarks;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  AssignmentsState({
    this.assignments = const [],
    this.selectedAssignment,
    this.submissions = const [],
    this.statuses = const {},
    this.remarks = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  AssignmentsState copyWith({
    List<Assignment>? assignments,
    Assignment? selectedAssignment,
    List<AssignmentSubmission>? submissions,
    Map<String, String>? statuses,
    Map<String, String>? remarks,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      AssignmentsState(
        assignments: assignments ?? this.assignments,
        selectedAssignment: selectedAssignment ?? this.selectedAssignment,
        submissions: submissions ?? this.submissions,
        statuses: statuses ?? this.statuses,
        remarks: remarks ?? this.remarks,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        successMessage:
            clearSuccess ? null : (successMessage ?? this.successMessage),
      );
}

class AssignmentsStateNotifier extends StateNotifier<AssignmentsState> {
  final TeacherRepository _repo;

  AssignmentsStateNotifier(this._repo) : super(AssignmentsState());

  Future<void> loadAssignments(String teacherId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final assignments = await _repo.getAssignments(teacherId);
      state = state.copyWith(assignments: assignments, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load assignments: $e',
      );
    }
  }

  Future<void> selectAssignment(Assignment assignment) async {
    state = state.copyWith(
      selectedAssignment: assignment,
      submissions: [],
      statuses: {},
      remarks: {},
    );
    await _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    if (state.selectedAssignment == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final submissions = await _repo.getAssignmentSubmissions(
        state.selectedAssignment!.id,
      );
      final statuses = <String, String>{};
      final remarks = <String, String>{};
      for (final s in submissions) {
        statuses[s.studentId] = s.status;
        remarks[s.studentId] = s.remarks ?? '';
      }
      state = state.copyWith(
        submissions: submissions,
        statuses: statuses,
        remarks: remarks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load submissions: $e',
      );
    }
  }

  void setStatus(String studentId, String status) {
    final statuses = Map<String, String>.from(state.statuses);
    statuses[studentId] = status;
    state = state.copyWith(statuses: statuses);
  }

  void setRemarks(String studentId, String remarks) {
    final updated = Map<String, String>.from(state.remarks);
    updated[studentId] = remarks;
    state = state.copyWith(remarks: updated);
  }

  Future<void> saveSubmissions() async {
    if (state.selectedAssignment == null) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final submissions = state.submissions.map((s) {
        return {
          'student_id': s.studentId,
          'status': state.statuses[s.studentId] ?? s.status,
          if ((state.remarks[s.studentId] ?? '').isNotEmpty)
            'remarks': state.remarks[s.studentId],
        };
      }).toList();

      await _repo.bulkUpdateSubmissions(
        state.selectedAssignment!.id,
        submissions,
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Submissions updated successfully!',
      );
      await _loadSubmissions();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save submissions: $e',
      );
    }
  }

  void clearSelection() {
    state = state.copyWith(
      selectedAssignment: null,
      submissions: [],
      statuses: {},
      remarks: {},
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final assignmentsStateProvider =
    StateNotifierProvider<AssignmentsStateNotifier, AssignmentsState>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  return AssignmentsStateNotifier(repo);
});
