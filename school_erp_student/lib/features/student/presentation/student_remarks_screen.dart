import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_remarks_provider.dart';

class StudentRemarksScreen extends ConsumerWidget {
  const StudentRemarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentRemarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Remarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(studentRemarksProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.remarks.isEmpty
                ? _emptyState(context)
                : _remarksList(context, ref, state),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No remarks yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Teachers will send you praise and feedback here',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _remarksList(BuildContext context, WidgetRef ref, RemarksState state) {
    return ListView.separated(
      itemCount: state.remarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final remark = state.remarks[index];
        final isPraise = remark.type == 'praise';

        return GestureDetector(
          onTap: remark.isRead
              ? null
              : () => ref.read(studentRemarksProvider.notifier).markAsRead(remark.id),
          child: Container(
            decoration: BoxDecoration(
              color: remark.isRead ? null : AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: remark.isRead
                  ? null
                  : Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Card(
              elevation: 0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.glassDark
                  : AppColors.glassLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isPraise ? AppColors.success : AppColors.warning)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPraise ? Icons.thumb_up_rounded : Icons.warning_amber_rounded,
                            color: isPraise ? AppColors.success : AppColors.warning,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isPraise ? AppColors.success : AppColors.warning)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isPraise ? 'Praise' : 'Complaint',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isPraise ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                  if (remark.category != null) ...[
                                    const SizedBox(width: 6),
                                    Text('#${remark.category}',
                                        style: const TextStyle(
                                            fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                  const Spacer(),
                                  if (!remark.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              if (remark.teacherName != null) ...[
                                const SizedBox(height: 4),
                                Text(remark.teacherName!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(remark.message, style: const TextStyle(fontSize: 14, height: 1.4)),
                    const SizedBox(height: 8),
                    Text(_formatDate(remark.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
