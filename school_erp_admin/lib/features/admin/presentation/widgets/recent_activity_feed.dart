import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';

class RecentActivityFeed extends StatelessWidget {
  final DashboardStats stats;
  final bool isMobile;

  const RecentActivityFeed({
    super.key,
    required this.stats,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final activities = _buildActivities(context);

    return GlassCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Icon(
                Icons.insights_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                _ActivityTile(
                  icon: activity.icon,
                  color: activity.color,
                  title: activity.title,
                  subtitle: activity.subtitle,
                  trailing: activity.trailing,
                  onTap: activity.route != null
                      ? () => context.go(activity.route!)
                      : null,
                  isMobile: isMobile,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<_ActivityItem> _buildActivities(BuildContext context) {
    final items = <_ActivityItem>[
      _ActivityItem(
        icon: Icons.people_rounded,
        color: AppColors.info,
        title: 'Student Enrollment',
        subtitle: '${stats.totalStudents} students enrolled across all classes',
        trailing: '${stats.totalStudents}',
        route: '/admin/students',
      ),
      _ActivityItem(
        icon: Icons.person_rounded,
        color: AppColors.success,
        title: 'Teaching Staff',
        subtitle: '${stats.totalTeachers} teachers active this year',
        trailing: '${stats.totalTeachers}',
        route: '/admin/teachers',
      ),
      _ActivityItem(
        icon: Icons.school_rounded,
        color: AppColors.warning,
        title: 'Active Classes',
        subtitle: '${stats.totalClasses} classes running',
        trailing: '${stats.totalClasses}',
        route: '/admin/classes',
      ),
      _ActivityItem(
        icon: Icons.trending_up_rounded,
        color: AppColors.primary,
        title: "Today's Attendance",
        subtitle: _attendanceSubtitle(stats.todayAttendancePercentage),
        trailing: '${stats.todayAttendancePercentage.toStringAsFixed(1)}%',
        route: '/admin/attendance-report',
      ),
    ];

    return items;
  }

  String _attendanceSubtitle(double pct) {
    if (pct >= 90) return 'Excellent attendance recorded today';
    if (pct >= 75) return 'Attendance is satisfactory, room for improvement';
    return 'Attendance is below target, review recommended';
  }
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;
  final String? route;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.route,
  });
}

class _ActivityTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final bool isMobile;

  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    required this.isMobile,
  });

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            vertical: widget.isMobile ? 10 : 12,
            horizontal: widget.onTap != null && _isHovered ? 8 : 0,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: widget.onTap != null && _isHovered ? -4 : 0,
          ),
          decoration: BoxDecoration(
            color: widget.onTap != null && _isHovered
                ? widget.color.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.trailing!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ),
              ],
              if (widget.onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
