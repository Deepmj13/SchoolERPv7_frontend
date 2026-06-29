import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_dashboard_provider.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(studentDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: dashboardAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text('Failed to load: $e',
                  style: const TextStyle(color: AppColors.error))),
          data: (data) => _buildContent(context, data),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, DashboardData data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning ${data.studentName.isNotEmpty ? data.studentName : 'Student'}',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your academic overview',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (data.attendanceSummary != null)
            _attendanceCard(context, data.attendanceSummary!),
          const SizedBox(height: 24),
          _quickLinks(context),
          const SizedBox(height: 24),
          if (data.recentNotices.isNotEmpty)
            _noticesSection(context, data.recentNotices),
        ],
      ),
    );
  }

  Widget _attendanceCard(
      BuildContext context, AttendanceSummary summary) {
    final percentage = summary.percentage;
    final color = percentage >= 75
        ? AppColors.success
        : percentage >= 60
            ? AppColors.warning
            : AppColors.error;

    return GlassCard(
      child: Row(
        children: [
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Attendance',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Present: ${summary.present} / ${summary.total} days',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Links',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                onTap: () => context.go('/student/notices'),
                child: Column(
                  children: [
                    const Icon(Icons.campaign_rounded,
                        color: AppColors.warning, size: 32),
                    const SizedBox(height: 8),
                    Text('Notices',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                onTap: () => context.go('/student/assignments'),
                child: Column(
                  children: [
                    const Icon(Icons.book_rounded,
                        color: AppColors.primary, size: 32),
                    const SizedBox(height: 8),
                    Text('Assignments',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _noticesSection(
      BuildContext context, List<Notice> notices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Latest Notices',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...notices.map(
          (notice) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notice.title,
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        Text(notice.createdAt,
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
