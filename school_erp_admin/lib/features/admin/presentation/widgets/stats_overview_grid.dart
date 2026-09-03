import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';

class StatsOverviewGrid extends StatelessWidget {
  final DashboardStats stats;
  final bool isMobile;

  const StatsOverviewGrid({
    super.key,
    required this.stats,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        icon: Icons.people_rounded,
        label: 'Students',
        value: '${stats.totalStudents}',
        color: AppColors.info,
        route: '/admin/students',
        subtitle: 'Total enrolled',
      ),
      _StatCardData(
        icon: Icons.person_rounded,
        label: 'Teachers',
        value: '${stats.totalTeachers}',
        color: AppColors.success,
        route: '/admin/teachers',
        subtitle: 'Active staff',
      ),
      _StatCardData(
        icon: Icons.school_rounded,
        label: 'Classes',
        value: '${stats.totalClasses}',
        color: AppColors.warning,
        route: '/admin/classes',
        subtitle: 'Running',
      ),
      _StatCardData(
        icon: Icons.trending_up_rounded,
        label: 'Attendance',
        value: '${stats.todayAttendancePercentage.toStringAsFixed(1)}%',
        color: AppColors.primary,
        route: '/admin/attendance-report',
        subtitle: _attendanceLabel(stats.todayAttendancePercentage),
        trendUp: stats.todayAttendancePercentage >= 75,
        trend: stats.todayAttendancePercentage >= 90
            ? 'Excellent'
            : stats.todayAttendancePercentage >= 75
                ? 'Good'
                : 'Low',
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) => _StatCard(
            data: cards[index],
            compact: true,
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
          children: cards
              .map((c) => _StatCard(data: c, compact: false))
              .toList(),
        );
      },
    );
  }

  String _attendanceLabel(double pct) {
    if (pct >= 90) return 'Excellent today';
    if (pct >= 75) return 'Good today';
    return 'Needs attention';
  }
}

class _StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String route;
  final String subtitle;
  final bool? trendUp;
  final String? trend;

  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.route,
    required this.subtitle,
    this.trendUp,
    this.trend,
  });
}

class _StatCard extends StatefulWidget {
  final _StatCardData data;
  final bool compact;

  const _StatCard({
    required this.data,
    required this.compact,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = widget.compact
        ? _buildCompactLayout(context, d)
        : _buildDesktopLayout(context, d, isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(d.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.compact ? 130 : null,
          height: widget.compact ? 130 : null,
          transform: Matrix4.diagonal3Values(
            _isHovered ? 1.02 : 1.0,
            _isHovered ? 1.02 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
          padding: EdgeInsets.all(widget.compact ? 12 : 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? d.color.withValues(alpha: 0.3)
                  : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
            ),
            boxShadow: [
              BoxShadow(
                color: d.color.withValues(alpha: _isHovered ? 0.12 : 0.04),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, _StatCardData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: d.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(d.icon, color: d.color, size: 16),
        ),
        const Spacer(),
        Text(
          d.value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: d.color,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          d.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, _StatCardData d, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: d.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(d.icon, color: d.color, size: 22),
            ),
            if (d.trend != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (d.trendUp == true ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  d.trend!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: d.trendUp == true ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: d.color,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              d.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
