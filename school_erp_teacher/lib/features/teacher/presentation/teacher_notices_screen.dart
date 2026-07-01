import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_notices_provider.dart';

class TeacherNoticesScreen extends ConsumerStatefulWidget {
  const TeacherNoticesScreen({super.key});

  @override
  ConsumerState<TeacherNoticesScreen> createState() =>
      _TeacherNoticesScreenState();
}

class _TeacherNoticesScreenState
    extends ConsumerState<TeacherNoticesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(teacherNoticesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(teacherNoticesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: noticesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (notices) {
          if (notices.isEmpty) {
            return const Center(child: Text('No notices available'));
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

  void _showNoticeSheet(BuildContext context, Announcement notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
            const SizedBox(height: 12),
            Text(notice.title,
                style: Theme.of(context).textTheme.titleLarge),
            if (notice.body != null && notice.body!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(notice.body!,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: 16),
            if (notice.createdByEmail != null) ...[
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(notice.createdByEmail!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(_formatDate(notice.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noticeCard(BuildContext context, Announcement notice) {
    return GlassCard(
      onTap: () => _showNoticeSheet(context, notice),
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
          Text(
            _formatDate(notice.createdAt),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
