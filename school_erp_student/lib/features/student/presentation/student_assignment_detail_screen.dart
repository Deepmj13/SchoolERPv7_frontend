import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_assignments_provider.dart';

class StudentAssignmentDetailScreen extends ConsumerWidget {
  final String assignmentId;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment')),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (assignments) {
          final assignment = assignments.where(
            (a) => a.id == assignmentId,
          ).firstOrNull;

          if (assignment == null) {
            return const Center(child: Text('Assignment not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, assignment),
                const SizedBox(height: 16),
                _statusCard(context, assignment),
                if (assignment.description != null &&
                    assignment.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _descriptionCard(context, assignment),
                ],
                if (assignment.teacherRemarks != null &&
                    assignment.teacherRemarks!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _remarksCard(context, assignment),
                ],
                if (assignment.grade != null) ...[
                  const SizedBox(height: 16),
                  _gradeCard(context, assignment),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, Assignment assignment) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.title,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.book_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(assignment.subjectName,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          if (assignment.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
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

  Widget _statusCard(BuildContext context, Assignment assignment) {
    final displayStatus = assignment.submissionStatus ?? assignment.status;
    final statusColors = {
      'pending': AppColors.warning,
      'done': AppColors.success,
      'late': AppColors.error,
    };
    final color = statusColors[displayStatus] ?? AppColors.textSecondary;

    final statusLabels = {
      'pending': 'Pending',
      'done': 'Done',
      'late': 'Late',
    };

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              displayStatus == 'done'
                  ? Icons.check_circle_rounded
                  : displayStatus == 'late'
                      ? Icons.access_time_rounded
                      : Icons.hourglass_empty_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabels[displayStatus] ?? displayStatus.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (assignment.submissionUpdatedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(assignment.submissionUpdatedAt!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionCard(BuildContext context, Assignment assignment) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(assignment.description!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _remarksCard(BuildContext context, Assignment assignment) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Teacher\'s Remarks',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(assignment.teacherRemarks!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _gradeCard(BuildContext context, Assignment assignment) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.star_rounded, size: 24, color: AppColors.success),
          const SizedBox(width: 12),
          Text(
            'Grade: ${assignment.grade}',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return 'Updated: ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
