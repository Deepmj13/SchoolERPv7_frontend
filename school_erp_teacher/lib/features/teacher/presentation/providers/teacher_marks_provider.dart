import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/features/teacher/data/teacher_repository.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

class MarksState {
  final List<TeacherClass> teacherClasses;
  final TeacherClass? selectedClass;
  final List<Exam> exams;
  final Exam? selectedExam;
  final Subject? selectedSubject;
  final List<Student> students;
  final Map<String, double> marks;
  final double totalMarks;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final List<Map<String, dynamic>> previousResults;
  final bool isLoadingPrevious;

  MarksState({
    this.teacherClasses = const [],
    this.selectedClass,
    this.exams = const [],
    this.selectedExam,
    this.selectedSubject,
    this.students = const [],
    this.marks = const {},
    this.totalMarks = 100,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.previousResults = const [],
    this.isLoadingPrevious = false,
  });

  MarksState copyWith({
    List<TeacherClass>? teacherClasses,
    TeacherClass? selectedClass,
    List<Exam>? exams,
    Exam? selectedExam,
    Subject? selectedSubject,
    List<Student>? students,
    Map<String, double>? marks,
    double? totalMarks,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    List<Map<String, dynamic>>? previousResults,
    bool? isLoadingPrevious,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      MarksState(
        teacherClasses: teacherClasses ?? this.teacherClasses,
        selectedClass: selectedClass ?? this.selectedClass,
        exams: exams ?? this.exams,
        selectedExam: selectedExam ?? this.selectedExam,
        selectedSubject: selectedSubject ?? this.selectedSubject,
        students: students ?? this.students,
        marks: marks ?? this.marks,
        totalMarks: totalMarks ?? this.totalMarks,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        successMessage:
            clearSuccess ? null : (successMessage ?? this.successMessage),
        previousResults: previousResults ?? this.previousResults,
        isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
      );
}

class MarksStateNotifier extends StateNotifier<MarksState> {
  final TeacherRepository _repo;

  MarksStateNotifier(this._repo) : super(MarksState());

  Future<void> loadInitialData(String teacherId) async {
    try {
      final classes = await _repo.getTeacherClasses(teacherId);
      final exams = await _repo.getExams();
      state = state.copyWith(
        teacherClasses: classes,
        exams: exams,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load data: $e');
    }
  }

  Future<void> selectClass(TeacherClass cls) async {
    state = state.copyWith(
      selectedClass: cls,
      selectedSubject: Subject(id: cls.subjectId, name: cls.subjectName),
      previousResults: [],
    );
    await _loadStudents();
    await loadPreviousResults();
  }

  void selectExam(Exam exam) {
    state = state.copyWith(selectedExam: exam, previousResults: []);
    _tryLoadPrevious();
  }

  void _tryLoadPrevious() {
    if (state.selectedExam != null &&
        state.selectedSubject != null &&
        state.selectedClass != null) {
      loadPreviousResults();
    }
  }

  Future<void> _loadStudents() async {
    if (state.selectedClass == null) return;
    try {
      final students =
          await _repo.getClassStudents(state.selectedClass!.classId);
      final marks = <String, double>{};
      for (final s in students) {
        marks[s.id] = 0;
      }
      state = state.copyWith(students: students, marks: marks);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load students: $e');
    }
  }

  Future<void> loadPreviousResults() async {
    if (state.selectedExam == null ||
        state.selectedSubject == null ||
        state.selectedClass == null) {
      return;
    }
    state = state.copyWith(isLoadingPrevious: true);
    try {
      final results = await _repo.getResults(
        state.selectedExam!.id,
        state.selectedSubject!.id,
        state.selectedClass!.classId,
      );
      double? newTotalMarks;
      final marks = Map<String, double>.from(state.marks);
      for (final r in results) {
        final studentId = r['student_id'] as String?;
        final marksObtained = r['marks_obtained'];
        final totalMarksVal = r['total_marks'];
        if (studentId != null && marks.containsKey(studentId)) {
          final mark = (marksObtained is num) ? marksObtained.toDouble() : 0.0;
          marks[studentId] = mark;
          if (totalMarksVal != null && newTotalMarks == null) {
            newTotalMarks = (totalMarksVal is num) ? totalMarksVal.toDouble() : state.totalMarks;
          }
        }
      }
      state = state.copyWith(
        previousResults: results,
        isLoadingPrevious: false,
        marks: marks,
        totalMarks: newTotalMarks ?? state.totalMarks,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPrevious: false,
        errorMessage: 'Failed to load previous results: $e',
      );
    }
  }

  void setMark(String studentId, double value) {
    final marks = Map<String, double>.from(state.marks);
    marks[studentId] = value;
    state = state.copyWith(marks: marks);
  }

  void setTotalMarks(double value) {
    state = state.copyWith(totalMarks: value);
  }

  Future<void> submitMarks() async {
    if (state.selectedExam == null || state.selectedSubject == null) {
      state = state.copyWith(
        errorMessage: 'Please select exam and subject',
      );
      return;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final marks = state.marks.entries
          .map((e) => {
                'studentId': e.key,
                'marksObtained': e.value,
              })
          .toList();
      await _repo.bulkEnterMarks(
        state.selectedExam!.id,
        state.selectedSubject!.id,
        marks,
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Marks submitted successfully!',
      );
      await loadPreviousResults();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit marks: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final marksStateProvider =
    StateNotifierProvider<MarksStateNotifier, MarksState>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  return MarksStateNotifier(repo);
});
