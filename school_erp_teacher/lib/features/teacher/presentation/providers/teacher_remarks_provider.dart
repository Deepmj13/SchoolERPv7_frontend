import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/data/teacher_repository.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

class RemarksState {
  final List<TeacherClass> classes;
  final TeacherClass? selectedClass;
  final List<Student> students;
  final Student? selectedStudent;
  final List<StudentRemark> studentRemarks;
  final List<StudentRemark> allRemarks;
  final bool isLoadingClasses;
  final bool isLoadingStudents;
  final bool isLoadingRemarks;
  final bool isLoadingAllRemarks;
  final bool isSubmitting;
  final String remarkType;
  final String? remarkCategory;
  final String? errorMessage;
  final String? successMessage;

  RemarksState({
    this.classes = const [],
    this.selectedClass,
    this.students = const [],
    this.selectedStudent,
    this.studentRemarks = const [],
    this.allRemarks = const [],
    this.isLoadingClasses = false,
    this.isLoadingStudents = false,
    this.isLoadingRemarks = false,
    this.isLoadingAllRemarks = false,
    this.isSubmitting = false,
    this.remarkType = 'praise',
    this.remarkCategory,
    this.errorMessage,
    this.successMessage,
  });

  RemarksState copyWith({
    List<TeacherClass>? classes,
    TeacherClass? Function()? selectedClass,
    List<Student>? students,
    Student? Function()? selectedStudent,
    List<StudentRemark>? studentRemarks,
    List<StudentRemark>? allRemarks,
    bool? isLoadingClasses,
    bool? isLoadingStudents,
    bool? isLoadingRemarks,
    bool? isLoadingAllRemarks,
    bool? isSubmitting,
    String? remarkType,
    String? Function()? remarkCategory,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) =>
      RemarksState(
        classes: classes ?? this.classes,
        selectedClass: selectedClass != null ? selectedClass() : this.selectedClass,
        students: students ?? this.students,
        selectedStudent: selectedStudent != null ? selectedStudent() : this.selectedStudent,
        studentRemarks: studentRemarks ?? this.studentRemarks,
        allRemarks: allRemarks ?? this.allRemarks,
        isLoadingClasses: isLoadingClasses ?? this.isLoadingClasses,
        isLoadingStudents: isLoadingStudents ?? this.isLoadingStudents,
        isLoadingRemarks: isLoadingRemarks ?? this.isLoadingRemarks,
        isLoadingAllRemarks: isLoadingAllRemarks ?? this.isLoadingAllRemarks,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        remarkType: remarkType ?? this.remarkType,
        remarkCategory: remarkCategory != null ? remarkCategory() : this.remarkCategory,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
        successMessage: successMessage != null ? successMessage() : this.successMessage,
      );
}

class RemarksStateNotifier extends StateNotifier<RemarksState> {
  final TeacherRepository _repo;
  final String _teacherId;

  RemarksStateNotifier(this._repo, this._teacherId) : super(RemarksState()) {
    _loadClasses();
    loadAllRemarks();
  }

  Future<void> _loadClasses() async {
    state = state.copyWith(isLoadingClasses: true, errorMessage: () => null);
    try {
      final classes = await _repo.getTeacherClasses(_teacherId);
      state = state.copyWith(classes: classes, isLoadingClasses: false);
    } catch (e) {
      state = state.copyWith(isLoadingClasses: false, errorMessage: () => 'Failed to load classes: $e');
    }
  }

  Future<void> loadAllRemarks() async {
    state = state.copyWith(isLoadingAllRemarks: true);
    try {
      final remarks = await _repo.getTeacherRemarks(_teacherId);
      state = state.copyWith(allRemarks: remarks, isLoadingAllRemarks: false);
    } catch (e) {
      state = state.copyWith(isLoadingAllRemarks: false, errorMessage: () => 'Failed to load all remarks: $e');
    }
  }

  Future<void> selectClass(TeacherClass cls) async {
    state = state.copyWith(
      selectedClass: () => cls,
      selectedStudent: () => null,
      students: [],
      studentRemarks: [],
      isLoadingStudents: true,
    );
    try {
      final students = await _repo.getClassStudents(cls.classId);
      state = state.copyWith(students: students, isLoadingStudents: false);
    } catch (e) {
      state = state.copyWith(isLoadingStudents: false, errorMessage: () => 'Failed to load students: $e');
    }
  }

  Future<void> selectStudent(Student student) async {
    state = state.copyWith(
      selectedStudent: () => student,
      studentRemarks: [],
      remarkType: 'praise',
      remarkCategory: null,
      isLoadingRemarks: true,
    );
    try {
      final remarks = await _repo.getRemarksForStudent(_teacherId, student.id);
      state = state.copyWith(studentRemarks: remarks, isLoadingRemarks: false);
    } catch (e) {
      state = state.copyWith(isLoadingRemarks: false, errorMessage: () => 'Failed to load remarks: $e');
    }
  }

  void clearStudent() {
    state = state.copyWith(
      selectedStudent: () => null,
      studentRemarks: [],
      remarkType: 'praise',
      remarkCategory: null,
    );
  }

  void setRemarkType(String type) {
    state = state.copyWith(remarkType: type);
  }

  void setRemarkCategory(String? category) {
    state = state.copyWith(remarkCategory: () => category);
  }

  Future<void> submitRemark(String message) async {
    if (state.selectedStudent == null || message.trim().isEmpty) return;
    state = state.copyWith(isSubmitting: true, errorMessage: () => null, successMessage: () => null);
    try {
      await _repo.createRemark(
        state.selectedStudent!.id,
        state.remarkType,
        state.remarkCategory,
        message.trim(),
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: () => 'Remark submitted successfully',
      );
      final remarks = await _repo.getRemarksForStudent(_teacherId, state.selectedStudent!.id);
      final allRemarks = await _repo.getTeacherRemarks(_teacherId);
      state = state.copyWith(studentRemarks: remarks, allRemarks: allRemarks);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: () => 'Failed to submit remark: $e');
    }
  }

  Future<void> refresh() async {
    _loadClasses();
    loadAllRemarks();
  }

  Future<void> refreshRemarks() async {
    if (state.selectedStudent == null) return;
    state = state.copyWith(isLoadingRemarks: true);
    try {
      final remarks = await _repo.getRemarksForStudent(_teacherId, state.selectedStudent!.id);
      state = state.copyWith(studentRemarks: remarks, isLoadingRemarks: false);
    } catch (e) {
      state = state.copyWith(isLoadingRemarks: false, errorMessage: () => 'Failed to refresh remarks: $e');
    }
  }

  Future<void> editRemark(String id, String type, String? category, String message) async {
    try {
      final updated = await _repo.updateRemark(id, type: type, category: category, message: message);
      final remarks = state.studentRemarks.map((r) => r.id == id ? updated : r).toList();
      final all = state.allRemarks.map((r) => r.id == id ? updated : r).toList();
      state = state.copyWith(studentRemarks: remarks, allRemarks: all, successMessage: () => 'Remark updated');
    } catch (e) {
      state = state.copyWith(errorMessage: () => 'Failed to update remark: $e');
    }
  }

  Future<void> deleteRemark(String id) async {
    try {
      await _repo.deleteRemark(id);
      final remarks = state.studentRemarks.where((r) => r.id != id).toList();
      final all = state.allRemarks.where((r) => r.id != id).toList();
      state = state.copyWith(studentRemarks: remarks, allRemarks: all, successMessage: () => 'Remark deleted');
    } catch (e) {
      state = state.copyWith(errorMessage: () => 'Failed to delete remark: $e');
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: () => null, successMessage: () => null);
  }
}

final remarksStateProvider = StateNotifierProvider<RemarksStateNotifier, RemarksState>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  return RemarksStateNotifier(repo, teacherId);
});
