import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/custom_button.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_assignments_provider.dart';

class TeacherAssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const TeacherAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<TeacherAssignmentDetailScreen> createState() =>
      _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState
    extends ConsumerState<TeacherAssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignment();
    });
  }

  void _loadAssignment() {
    final state = ref.read(assignmentsStateProvider);
    final assignment = state.assignments.where(
      (a) => a.id == widget.assignmentId,
    ).firstOrNull;

    if (assignment != null) {
      ref.read(assignmentsStateProvider.notifier).selectAssignment(assignment);
    } else {
      final teacherId = ref.read(authStateProvider).user?.teacherId ?? '';
      ref.read(assignmentsStateProvider.notifier).loadAssignments(teacherId);
    }
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
      if (next.selectedAssignment == null && next.assignments.isNotEmpty) {
        final assignment = next.assignments.where(
          (a) => a.id == widget.assignmentId,
        ).firstOrNull;
        if (assignment != null) {
          ref
              .read(assignmentsStateProvider.notifier)
              .selectAssignment(assignment);
        }
      }
    });

    final state = ref.watch(assignmentsStateProvider);
    final assignment = state.assignments.where(
      (a) => a.id == widget.assignmentId,
    ).firstOrNull;

    if (assignment == null && state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment')),
        body: const Center(child: Text('Assignment not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(assignment.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _assignmentInfo(context, assignment),
            const SizedBox(height: 16),
            Text('Student Submissions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.submissions.isEmpty)
              GlassCard(
                child: Center(
                  child: Text('No students found for this assignment',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else ...[
              _submissionList(state),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Save All Changes',
                onPressed: () =>
                    ref.read(assignmentsStateProvider.notifier).saveSubmissions(),
                loading: state.isSubmitting,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _assignmentInfo(BuildContext context, Assignment assignment) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.title,
              style: Theme.of(context).textTheme.titleLarge),
          if (assignment.description != null &&
              assignment.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(assignment.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.class_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(assignment.classDisplay,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.book_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(assignment.subjectName,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          if (assignment.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Due: ${assignment.dueDate}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _submissionList(AssignmentsState state) {
    return Column(
      children: state.submissions.asMap().entries.map((entry) {
        final i = entry.key;
        final submission = entry.value;
        final status = state.statuses[submission.studentId] ?? submission.status;
        final remarks = state.remarks[submission.studentId] ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${i + 1}.',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(submission.studentName,
                              style: Theme.of(context).textTheme.titleMedium),
                          if (submission.rollNumber != null)
                            Text('Roll: ${submission.rollNumber}',
                                style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _statusToggle(status, submission.studentId),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: remarks,
                  decoration: const InputDecoration(
                    hintText: 'Add remarks...',
                    isDense: true,
                    prefixIcon: Icon(Icons.comment_rounded, size: 18),
                  ),
                  maxLines: 2,
                  onChanged: (v) => ref
                      .read(assignmentsStateProvider.notifier)
                      .setRemarks(submission.studentId, v),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statusToggle(String currentStatus, String studentId) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'done',
          label: Text('Done', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.check_circle, size: 16),
        ),
        ButtonSegment(
          value: 'pending',
          label: Text('Pending', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.hourglass_empty, size: 16),
        ),
        ButtonSegment(
          value: 'late',
          label: Text('Late', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.access_time, size: 16),
        ),
      ],
      selected: {currentStatus},
      onSelectionChanged: (selected) {
        ref
            .read(assignmentsStateProvider.notifier)
            .setStatus(studentId, selected.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
