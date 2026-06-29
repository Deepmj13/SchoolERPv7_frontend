import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_assignments_provider.dart';

class StudentAssignmentsScreen extends ConsumerWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: assignmentsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Failed to load: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Text('No assignments found',
                  style: Theme.of(context).textTheme.bodyMedium),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: assignments
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _assignmentCard(context, a),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _assignmentCard(
      BuildContext context, Assignment assignment) {
    final statusColors = {
      'pending': AppColors.warning,
      'submitted': AppColors.info,
      'graded': AppColors.success,
    };
    final color =
        statusColors[assignment.status] ?? AppColors.textSecondary;

    return GlassCard(
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assignment.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(assignment.subjectName,
              style: Theme.of(context).textTheme.bodyMedium),
          if (assignment.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Due: ${assignment.dueDate}',
                    style:
                        Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
          if (assignment.grade != null) ...[
            const SizedBox(height: 8),
            Text('Grade: ${assignment.grade}',
                style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
