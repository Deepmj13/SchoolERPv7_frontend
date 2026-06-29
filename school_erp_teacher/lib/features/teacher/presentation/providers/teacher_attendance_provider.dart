import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/features/teacher/data/teacher_repository.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

class AttendanceState {
  final List<TeacherClass> teacherClasses;
  final TeacherClass? selectedClass;
  final DateTime selectedDate;
  final List<Student> students;
  final Map<String, String> statuses;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final List<AttendanceRecord> pastRecords;
  final bool quickMode;

  AttendanceState({
    this.teacherClasses = const [],
    this.selectedClass,
    DateTime? selectedDate,
    this.students = const [],
    this.statuses = const {},
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.pastRecords = const [],
    this.quickMode = false,
  }) : selectedDate = selectedDate ?? DateTime.now();

  AttendanceState copyWith({
    List<TeacherClass>? teacherClasses,
    TeacherClass? selectedClass,
    DateTime? selectedDate,
    List<Student>? students,
    Map<String, String>? statuses,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    List<AttendanceRecord>? pastRecords,
    bool? quickMode,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      AttendanceState(
        teacherClasses: teacherClasses ?? this.teacherClasses,
        selectedClass: selectedClass ?? this.selectedClass,
        selectedDate: selectedDate ?? this.selectedDate,
        students: students ?? this.students,
        statuses: statuses ?? this.statuses,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        successMessage:
            clearSuccess ? null : (successMessage ?? this.successMessage),
        pastRecords: pastRecords ?? this.pastRecords,
        quickMode: quickMode ?? this.quickMode,
      );
}

class AttendanceStateNotifier extends StateNotifier<AttendanceState> {
  final TeacherRepository _repo;

  AttendanceStateNotifier(this._repo) : super(AttendanceState());

  Future<void> loadTeacherClasses(String teacherId) async {
    try {
      final classes = await _repo.getTeacherClasses(teacherId);
      state = state.copyWith(teacherClasses: classes);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load classes: $e');
    }
  }

  Future<void> quickSelectClass(TeacherClass cls) async {
    state = state.copyWith(
      selectedClass: cls,
      quickMode: true,
      successMessage: null,
      errorMessage: null,
    );
    await _loadStudents();
    await _loadTodayRecords();
  }

  Future<void> selectClass(TeacherClass cls) async {
    state = state.copyWith(
      selectedClass: cls,
      quickMode: false,
      successMessage: null,
      errorMessage: null,
    );
    await _loadStudents();
    await _loadTodayRecords();
  }

  Future<void> _loadStudents() async {
    if (state.selectedClass == null) return;
    try {
      final students =
          await _repo.getClassStudents(state.selectedClass!.classId);
      final statuses = <String, String>{};
      for (final s in students) {
        statuses[s.id] = 'present';
      }
      state = state.copyWith(students: students, statuses: statuses);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load students: $e');
    }
  }

  Future<void> _loadTodayRecords() async {
    if (state.selectedClass == null) return;
    try {
      final date =
          '${state.selectedDate.year}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}';
      final records = await _repo.getAttendance(
          state.selectedClass!.classId, date);
      state = state.copyWith(pastRecords: records);
      if (records.isNotEmpty) {
        final statuses = Map<String, String>.from(state.statuses);
        for (final r in records) {
          if (statuses.containsKey(r.studentId)) {
            statuses[r.studentId] = r.status;
          }
        }
        state = state.copyWith(statuses: statuses);
      } else {
        final statuses = <String, String>{};
        for (final s in state.students) {
          statuses[s.id] = 'present';
        }
        state = state.copyWith(statuses: statuses);
      }
    } catch (_) {}
  }

  Future<void> setDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    if (state.selectedClass != null) {
      await _loadTodayRecords();
    }
  }

  void setStatus(String studentId, String status) {
    final statuses = Map<String, String>.from(state.statuses);
    statuses[studentId] = status;
    state = state.copyWith(statuses: statuses);
  }

  Future<void> submitAttendance() async {
    if (state.selectedClass == null) return;
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final records = state.statuses.entries
          .map((e) => {
                'studentId': e.key,
                'status': e.value,
              })
          .toList();
      final date =
          '${state.selectedDate.year}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}';
      await _repo.markAttendance(
          state.selectedClass!.classId, date, records);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Attendance marked successfully!',
      );
      await _loadTodayRecords();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit attendance: $e',
      );
    }
  }

  void clearQuickMode() {
    state = state.copyWith(quickMode: false);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final attendanceStateProvider =
    StateNotifierProvider<AttendanceStateNotifier, AttendanceState>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  return AttendanceStateNotifier(repo);
});
