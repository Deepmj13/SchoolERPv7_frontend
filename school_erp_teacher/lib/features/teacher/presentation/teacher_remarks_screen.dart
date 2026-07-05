import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/custom_button.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
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
  final bool isLoadingClasses;
  final bool isLoadingStudents;
  final bool isLoadingRemarks;
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
    this.isLoadingClasses = false,
    this.isLoadingStudents = false,
    this.isLoadingRemarks = false,
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
    bool? isLoadingClasses,
    bool? isLoadingStudents,
    bool? isLoadingRemarks,
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
        isLoadingClasses: isLoadingClasses ?? this.isLoadingClasses,
        isLoadingStudents: isLoadingStudents ?? this.isLoadingStudents,
        isLoadingRemarks: isLoadingRemarks ?? this.isLoadingRemarks,
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
  }

  Future<void> _loadClasses() async {
    state = state.copyWith(isLoadingClasses: true, errorMessage: () => null);
    try {
      final classes = await _repo.getTeacherClasses(_teacherId);
      final unique = <String, TeacherClass>{};
      for (final c in classes) {
        unique[c.classId] = c;
      }
      state = state.copyWith(classes: unique.values.toList(), isLoadingClasses: false);
    } catch (e) {
      state = state.copyWith(isLoadingClasses: false, errorMessage: () => 'Failed to load classes: $e');
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
      state = state.copyWith(studentRemarks: remarks);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: () => 'Failed to submit remark: $e');
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

class TeacherRemarksScreen extends ConsumerStatefulWidget {
  const TeacherRemarksScreen({super.key});

  @override
  ConsumerState<TeacherRemarksScreen> createState() => _TeacherRemarksScreenState();
}

class _TeacherRemarksScreenState extends ConsumerState<TeacherRemarksScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remarksStateProvider);

    ref.listen<RemarksState>(remarksStateProvider, (prev, next) {
      if (next.successMessage != null) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success),
        );
        ref.read(remarksStateProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(remarksStateProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Student Remarks')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _classSelector(state),
            const SizedBox(height: 16),
            if (state.selectedClass != null) ...[
              _studentSelector(state),
              const SizedBox(height: 16),
            ],
            if (state.selectedStudent != null) ...[
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _remarkForm(state)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _remarksHistory(state)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _classSelector(RemarksState state) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Class', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (state.isLoadingClasses)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              DropdownButtonFormField<TeacherClass>(
                value: state.selectedClass,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Class'),
                items: state.classes.map((cls) => DropdownMenuItem(
                  value: cls,
                  child: Text(cls.display),
                )).toList(),
                onChanged: (cls) {
                  if (cls != null) ref.read(remarksStateProvider.notifier).selectClass(cls);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _studentSelector(RemarksState state) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Student', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (state.isLoadingStudents)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (state.students.isEmpty)
              Text('No students found', style: Theme.of(context).textTheme.bodyMedium)
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  itemCount: state.students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = state.students[index];
                    final isSelected = state.selectedStudent?.id == student.id;
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isSelected ? AppColors.primary : AppColors.primaryLight,
                        child: Text(
                          student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      title: Text(student.fullName, style: const TextStyle(fontSize: 14)),
                      subtitle: student.rollNumber != null ? Text('Roll: ${student.rollNumber}', style: const TextStyle(fontSize: 12)) : null,
                      onTap: () => ref.read(remarksStateProvider.notifier).selectStudent(student),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _remarkForm(RemarksState state) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Remark', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Praise'),
                    selected: state.remarkType == 'praise',
                    selectedColor: AppColors.success.withValues(alpha: 0.2),
                    onSelected: (_) => ref.read(remarksStateProvider.notifier).setRemarkType('praise'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Complaint'),
                    selected: state.remarkType == 'complaint',
                    selectedColor: AppColors.warning.withValues(alpha: 0.2),
                    onSelected: (_) => ref.read(remarksStateProvider.notifier).setRemarkType('complaint'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: state.remarkCategory,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category (optional)', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 'academics', child: Text('Academics')),
                DropdownMenuItem(value: 'behavior', child: Text('Behavior')),
                DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (val) => ref.read(remarksStateProvider.notifier).setRemarkCategory(val),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Submit Remark',
              loading: state.isSubmitting,
              onPressed: _messageController.text.trim().isEmpty
                  ? null
                  : () => ref.read(remarksStateProvider.notifier).submitRemark(_messageController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remarksHistory(RemarksState state) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remark History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (state.isLoadingRemarks)
              const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            else if (state.studentRemarks.isEmpty)
              Expanded(
                child: Center(
                  child: Text('No remarks yet for this student',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: state.studentRemarks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final remark = state.studentRemarks[index];
                    final isPraise = remark.type == 'praise';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isPraise ? AppColors.success : AppColors.warning)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPraise ? Icons.thumb_up_rounded : Icons.warning_amber_rounded,
                          color: isPraise ? AppColors.success : AppColors.warning,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isPraise ? AppColors.success : AppColors.warning)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPraise ? 'Praise' : 'Complaint',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPraise ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                          if (remark.category != null) ...[
                            const SizedBox(width: 6),
                            Text(remark.category!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(remark.message, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_formatDate(remark.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
