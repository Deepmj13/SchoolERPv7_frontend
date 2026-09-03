import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/widgets/shimmer.dart';
import 'package:school_erp_admin/core/widgets/skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/dashboard_header.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/quick_actions_grid.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/stats_overview_grid.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/analytics_section.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/recent_activity_feed.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  final future = ref.watch(adminRepositoryProvider).getDashboardStats();
  return future.timeout(const Duration(seconds: 90));
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final isMobile = context.isMobile;

    return statsAsync.when(
      loading: () => _buildLoading(context, isMobile),
      error: (e, _) => _buildError(context, ref, e, isMobile),
      data: (stats) => RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: _buildContent(context, stats, isMobile),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isMobile) {
    final padding = isMobile ? 16.0 : 32.0;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSkeleton(isMobile),
            SizedBox(height: isMobile ? 20 : 28),
            _buildQuickActionsSkeleton(isMobile),
            SizedBox(height: isMobile ? 20 : 28),
            _buildStatsSkeleton(isMobile),
            SizedBox(height: isMobile ? 20 : 28),
            _buildChartSkeleton(isMobile),
            SizedBox(height: isMobile ? 16 : 24),
            _buildActivitySkeleton(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(
              width: isMobile ? 160 : 220,
              height: isMobile ? 22 : 28,
              borderRadius: BorderRadius.circular(8),
            ),
            SizedBox(height: isMobile ? 6 : 10),
            SkeletonLoader(
              width: isMobile ? 180 : 280,
              height: 14,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
        SkeletonLoader(
          width: 42,
          height: 42,
          borderRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSkeleton(bool isMobile) {
    if (isMobile) {
      return SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, _) => SkeletonLoader(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
    return Row(
      children: List.generate(
        5,
        (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: SkeletonLoader(
              height: 48,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSkeleton(bool isMobile) {
    if (isMobile) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, _) => SkeletonLoader(
            width: 130,
            height: 130,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1100 ? 4 : 3;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            4,
            (_) => SkeletonLoader(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSkeleton(bool isMobile) {
    return SkeletonLoader(
      height: isMobile ? 260 : 300,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildActivitySkeleton(bool isMobile) {
    return SkeletonLoader(
      height: isMobile ? 240 : 280,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object e,
    bool isMobile,
  ) {
    final padding = isMobile ? 16.0 : 32.0;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSkeleton(isMobile),
          SizedBox(height: isMobile ? 20 : 32),
          SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Failed to load statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Couldn't fetch your dashboard data. Please check your connection and try again.",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(dashboardStatsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DashboardStats stats,
    bool isMobile,
  ) {
    final padding = isMobile ? 16.0 : 32.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(),
          SizedBox(height: isMobile ? 20 : 28),
          _SectionLabel(label: 'Quick Actions', isMobile: isMobile),
          SizedBox(height: isMobile ? 10 : 14),
          const QuickActionsGrid(),
          SizedBox(height: isMobile ? 20 : 28),
          _SectionLabel(label: 'Overview', isMobile: isMobile),
          SizedBox(height: isMobile ? 10 : 14),
          StatsOverviewGrid(stats: stats, isMobile: isMobile),
          SizedBox(height: isMobile ? 20 : 28),
          _SectionLabel(label: 'Analytics', isMobile: isMobile),
          SizedBox(height: isMobile ? 10 : 14),
          AnalyticsSection(
            todayAttendance: stats.todayAttendancePercentage,
            totalStudents: stats.totalStudents,
            totalTeachers: stats.totalTeachers,
            totalClasses: stats.totalClasses,
          ),
          SizedBox(height: isMobile ? 20 : 28),
          RecentActivityFeed(stats: stats, isMobile: isMobile),
          SizedBox(height: isMobile ? 16 : 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isMobile;

  const _SectionLabel({
    required this.label,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
    );
  }
}
