import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/theme/theme_mode_provider.dart';

class SidebarNav extends ConsumerWidget {
  final String currentRoute;
  final VoidCallback? onLogout;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;

  const SidebarNav({
    super.key,
    required this.currentRoute,
    this.onLogout,
    this.isCollapsed = false,
    this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.sidebarBg : AppColors.sidebarBgLight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isCollapsed ? 80 : 260,
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildHeader(context, ref),
            const SizedBox(height: 32),
            _buildNavItems(context, ref),
            const Spacer(),
            _buildFooter(context, ref),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 16 : 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Text(
                'School ERP',
                style: TextStyle(
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItems(BuildContext context, WidgetRef ref) {
    final items = [
      (Icons.dashboard_rounded, 'Dashboard', '/admin/dashboard'),
      (Icons.people_rounded, 'Students', '/admin/students'),
      (Icons.arrow_upward_rounded, 'Promotion', '/admin/promotion'),
      (Icons.event_rounded, 'Holidays', '/admin/holidays'),
      (Icons.groups_rounded, 'Staff', '/admin/staff'),
      (Icons.person_rounded, 'Teachers', '/admin/teachers'),
      (Icons.school_rounded, 'Classes', '/admin/classes'),
      (Icons.trending_up_rounded, 'Attendance', '/admin/attendance-report'),
      (Icons.book_rounded, 'Subjects', '/admin/subjects'),
      (Icons.assignment_rounded, 'Exams', '/admin/exams'),
      (Icons.grade_rounded, 'Grading', '/admin/grading'),
      (Icons.calendar_month_rounded, 'Timetable', '/admin/timetable'),
      (Icons.bar_chart_rounded, 'Reports', '/admin/reports'),
      (Icons.attach_money_rounded, 'Fees', '/admin/fees'),
      (Icons.campaign_rounded, 'Announcements', '/admin/announcements'),
    ];

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: items.map((item) {
            return _NavItem(
              icon: item.$1,
              label: item.$2,
              route: item.$3,
              isActive: currentRoute == item.$3,
              isCollapsed: isCollapsed,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    final splashColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final borderColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      children: [
        if (onToggleCollapsed != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: IconButton(
              icon: Icon(
                isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                color: secondaryColor,
              ),
              onPressed: onToggleCollapsed,
              tooltip: isCollapsed ? 'Expand' : 'Collapse',
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                color: secondaryColor,
                size: 20,
              ),
              tooltip: 'Toggle theme',
              onPressed: () {
                final next = themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : themeMode == ThemeMode.light
                        ? ThemeMode.system
                        : ThemeMode.dark;
                ref.read(themeModeProvider.notifier).setThemeMode(next);
              },
            ),
            if (!isCollapsed)
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                color: secondaryColor,
                tooltip: 'Settings',
                onPressed: () => context.go('/admin/settings'),
              ),
          ],
        ),
        InkWell(
          splashColor: splashColor,
          onTap: onLogout,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 20 : 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(color: secondaryColor, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
  final bool isCollapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    final activeColor = isDark ? AppColors.sidebarActive : AppColors.sidebarActiveLight;
    final activeBg = isDark
        ? AppColors.sidebarActive.withValues(alpha: 0.2)
        : AppColors.sidebarActiveLight.withValues(alpha: 0.08);
    final splashColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final hoverColor = isDark ? AppColors.sidebarHover : AppColors.sidebarHoverLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? activeBg : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.go(route),
          splashColor: splashColor,
          hoverColor: hoverColor,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isActive ? activeColor : secondaryColor,
                  size: 20,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive ? primaryColor : secondaryColor,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
