import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_results_provider.dart';

class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(studentResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: resultsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Failed to load: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Text('No results found',
                  style: Theme.of(context).textTheme.bodyMedium),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: results
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _resultCard(context, r),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _resultCard(BuildContext context, ResultEntry result) {
    final color = result.passed
        ? AppColors.success
        : AppColors.error;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.examName,
                        style:
                            Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(result.subjectName,
                        style:
                            Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.passed ? 'PASS' : 'FAIL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _detailItem('Marks', '${result.marksObtained}/${result.totalMarks}'),
              const SizedBox(width: 24),
              _detailItem('Percentage', '${result.percentage.toStringAsFixed(1)}%'),
              if (result.grade != null) ...[
                const SizedBox(width: 24),
                _detailItem('Grade', result.grade!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
