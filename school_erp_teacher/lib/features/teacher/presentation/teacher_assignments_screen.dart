import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/custom_button.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_assignments_provider.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

class TeacherAssignmentsScreen extends ConsumerStatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  ConsumerState<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState
    extends ConsumerState<TeacherAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teacherId = ref.read(authStateProvider).user?.teacherId;
      if (teacherId != null) {
        ref.read(assignmentsStateProvider.notifier).loadAssignments(teacherId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AssignmentsState>(assignmentsStateProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(assignmentsStateProvider.notifier).clearMessages();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(assignmentsStateProvider.notifier).clearMessages();
      }
    });

    final state = ref.watch(assignmentsStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.assignments.isEmpty
              ? const Center(child: Text('No assignments yet'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    children: state.assignments
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _assignmentCard(context, a),
                            ))
                        .toList(),
                  ),
                ),
    );
  }

  Widget _assignmentCard(BuildContext context, Assignment assignment) {
    return GlassCard(
      onTap: () => context.go('/teacher/assignments/${assignment.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(assignment.title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.class_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(assignment.classDisplay,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.book_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(assignment.subjectName,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          if (assignment.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Due: ${assignment.dueDate}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _CreateAssignmentSheet(),
    );
  }
}

class _CreateAssignmentSheet extends ConsumerStatefulWidget {
  const _CreateAssignmentSheet();

  @override
  ConsumerState<_CreateAssignmentSheet> createState() =>
      _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState
    extends ConsumerState<_CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TeacherClass? _selectedClass;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = ref.read(authStateProvider).user?.teacherId ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Create Assignment',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<TeacherClass>>(
              future: ref
                  .read(teacherRepositoryProvider)
                  .getTeacherClasses(teacherId),
              builder: (context, snapshot) {
                final classes = snapshot.data ?? <TeacherClass>[];
                return DropdownButtonFormField<TeacherClass>(
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: classes
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.display),
                          ))
                      .toList(),
                  onChanged: (cls) =>
                      setState(() => _selectedClass = cls),
                  validator: (v) =>
                      v == null ? 'Please select a class' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date (optional)',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dueDate != null
                      ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                      : 'Tap to select',
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Create Assignment',
              onPressed: _submitAssignment,
              loading: _isSubmitting,
              width: double.infinity,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(teacherRepositoryProvider).createAssignment(
            _titleController.text.trim(),
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            _dueDate != null
                ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                : null,
            _selectedClass!.classId,
            _selectedClass!.subjectId,
          );
      if (mounted) {
        Navigator.pop(context);
        final teacherId = ref.read(authStateProvider).user?.teacherId ?? '';
        ref
            .read(assignmentsStateProvider.notifier)
            .loadAssignments(teacherId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
