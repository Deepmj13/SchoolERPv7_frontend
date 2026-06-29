import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_notices_provider.dart';

class StudentNoticesScreen extends ConsumerWidget {
  const StudentNoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(studentNoticesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
      ),
      body: noticesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Failed to load: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Text('No notices available',
                  style: Theme.of(context).textTheme.bodyMedium),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: notices
                  .map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _noticeCard(context, n),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _noticeCard(BuildContext context, Notice notice) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: notice.isSchoolWide
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  notice.isSchoolWide ? 'School' : 'Class',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: notice.isSchoolWide
                        ? AppColors.primary
                        : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(notice.title,
              style: Theme.of(context).textTheme.titleMedium),
          if (notice.body != null && notice.body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(notice.body!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Text(notice.createdAt,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
