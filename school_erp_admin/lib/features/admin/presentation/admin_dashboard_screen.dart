import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/dashboard_chart.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/stats_panel.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  final future = ref.watch(adminRepositoryProvider).getDashboardStats();
  return future.timeout(const Duration(seconds: 15));
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSkeleton(context, isMobile),
          SizedBox(height: isMobile ? 20 : 32),
          if (isMobile)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) => const _ShimmerCard(width: 140),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1100 ? 4 : 3;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (_) => const _ShimmerCard()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object e, bool isMobile) {
    final padding = isMobile ? 16.0 : 32.0;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSkeleton(context, isMobile),
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
                    child: const Icon(Icons.cloud_off_rounded,
                        color: AppColors.error, size: 36),
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
                      'We couldn\'t fetch your dashboard data. Please check your connection and try again.',
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

  Widget _buildContent(BuildContext context, DashboardStats stats, bool isMobile) {
    final weekData = _generateWeekData(stats.todayAttendancePercentage);
    final padding = isMobile ? 16.0 : 32.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isMobile),
          SizedBox(height: isMobile ? 20 : 32),
          _buildStatsSection(context, stats, isMobile),
          SizedBox(height: isMobile ? 20 : 28),
          _buildChartsSection(context, stats, weekData, isMobile),
          SizedBox(height: isMobile ? 20 : 28),
          _buildActivitySection(context, stats, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, Admin',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                _formatDateShort(now),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isMobile ? 13 : 14,
                    ),
              ),
              if (!isMobile) ...[
                const SizedBox(height: 4),
                Text(
                  "Here's what's happening in your institution today.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                      ),
                ),
              ],
            ],
          ),
        ),
        CircleAvatar(
          radius: isMobile ? 18 : 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.admin_panel_settings,
              color: AppColors.primary, size: 22),
        ),
      ],
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isMobile ? 140 : 200,
              height: isMobile ? 22 : 28,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(height: isMobile ? 6 : 10),
            Container(
              width: isMobile ? 120 : 250,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: isMobile ? 18 : 20,
          backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, DashboardStats stats, bool isMobile) {
    if (isMobile) {
      return SizedBox(
        height: 115,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _CompactStatCard(
                  icon: Icons.people_rounded,
                  label: 'Students',
                  value: '${stats.totalStudents}',
                  color: AppColors.info,
                );
              case 1:
                return _CompactStatCard(
                  icon: Icons.person_rounded,
                  label: 'Teachers',
                  value: '${stats.totalTeachers}',
                  color: AppColors.success,
                );
              case 2:
                return _CompactStatCard(
                  icon: Icons.school_rounded,
                  label: 'Classes',
                  value: '${stats.totalClasses}',
                  color: AppColors.warning,
                );
              default:
                return _CompactStatCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Attendance',
                  value: '${stats.todayAttendancePercentage.toStringAsFixed(1)}%',
                  color: AppColors.primary,
                );
            }
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1100 ? 4 : 3;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatsPanel(
              icon: Icons.people_rounded,
              label: 'Total Students',
              value: '${stats.totalStudents}',
              color: AppColors.info,
              trend: '+12%',
              trendUp: true,
            ),
            StatsPanel(
              icon: Icons.person_rounded,
              label: 'Total Teachers',
              value: '${stats.totalTeachers}',
              color: AppColors.success,
              trend: '+5%',
              trendUp: true,
            ),
            StatsPanel(
              icon: Icons.school_rounded,
              label: 'Total Classes',
              value: '${stats.totalClasses}',
              color: AppColors.warning,
              trend: '0%',
              trendUp: true,
            ),
            StatsPanel(
              icon: Icons.trending_up_rounded,
              label: "Today's Attendance",
              value: '${stats.todayAttendancePercentage.toStringAsFixed(1)}%',
              color: AppColors.primary,
              trend: stats.todayAttendancePercentage >= 90
                  ? '+2.1%'
                  : stats.todayAttendancePercentage >= 75
                      ? '-1.3%'
                      : '-4.8%',
              trendUp: stats.todayAttendancePercentage >= 90,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(
      BuildContext context, DashboardStats stats, List<double> weekData, bool isMobile) {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final attendanceMap = <String, double>{};
    for (int i = 0; i < weekDays.length && i < weekData.length; i++) {
      attendanceMap[weekDays[i]] = weekData[i];
    }

    final chartHeight = isMobile ? 120.0 : 180.0;

    return Column(
      children: [
        AttendanceBarChart(data: attendanceMap, height: chartHeight),
        SizedBox(height: isMobile ? 16 : 24),
        DistributionCard(
          totalStudents: stats.totalStudents,
          totalTeachers: stats.totalTeachers,
          totalClasses: stats.totalClasses,
          attendancePercentage: stats.todayAttendancePercentage,
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, DashboardStats stats, bool isMobile) {
    final cardPadding = isMobile ? 16.0 : 20.0;
    return GlassCard(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Icon(Icons.history_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _ActivityTile(
            icon: Icons.people_rounded,
            color: AppColors.info,
            title: 'Student Enrollment',
            subtitle:
                '${stats.totalStudents} students are currently enrolled across all classes.',
          ),
          const Divider(height: 24),
          _ActivityTile(
            icon: Icons.person_rounded,
            color: AppColors.success,
            title: 'Teaching Staff',
            subtitle:
                '${stats.totalTeachers} teachers are active this academic year.',
          ),
          const Divider(height: 24),
          _ActivityTile(
            icon: Icons.school_rounded,
            color: AppColors.warning,
            title: 'Class Schedule',
            subtitle:
                '${stats.totalClasses} classes are running with assigned teachers.',
          ),
          const Divider(height: 24),
          _ActivityTile(
            icon: Icons.trending_up_rounded,
            color: AppColors.primary,
            title: "Today's Attendance",
            subtitle: stats.todayAttendancePercentage >= 90
                ? 'Excellent attendance at ${stats.todayAttendancePercentage.toStringAsFixed(1)}% today!'
                : stats.todayAttendancePercentage >= 75
                    ? 'Attendance is at ${stats.todayAttendancePercentage.toStringAsFixed(1)}%. Room for improvement.'
                    : 'Attendance dropped to ${stats.todayAttendancePercentage.toStringAsFixed(1)}%. Please review.',
          ),
        ],
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<double> _generateWeekData(double todayPercentage) {
    final rng = Random();
    return List.generate(7, (i) {
      if (i == 6) return todayPercentage;
      return (todayPercentage + (rng.nextDouble() - 0.5) * 16)
          .clamp(60.0, 100.0);
    });
  }
}

class _ShimmerCard extends StatefulWidget {
  final double? width;
  const _ShimmerCard({this.width});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: GlassCard(
        padding: EdgeInsets.all(widget.width != null ? 14 : 20),
        width: widget.width,
        child: widget.width != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 50,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 100,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompactStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 120,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
