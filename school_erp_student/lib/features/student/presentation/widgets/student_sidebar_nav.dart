import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';

class StudentSidebarNav extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onLogout;

  const StudentSidebarNav({
    super.key,
    required this.currentRoute,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sidebarBg,
      child: SizedBox(
        width: 260,
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Row(
              children: [
                SizedBox(width: 20),
                Icon(Icons.school_rounded,
                    color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'School ERP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'Student Panel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              route: '/student/dashboard',
              isActive: currentRoute == '/student/dashboard',
            ),
            _NavItem(
              icon: Icons.calendar_today_rounded,
              label: 'Attendance',
              route: '/student/attendance',
              isActive: currentRoute == '/student/attendance',
            ),
            _NavItem(
              icon: Icons.assignment_rounded,
              label: 'Results',
              route: '/student/results',
              isActive: currentRoute == '/student/results',
            ),
            _NavItem(
              icon: Icons.schedule_rounded,
              label: 'Timetable',
              route: '/student/timetable',
              isActive: currentRoute == '/student/timetable',
            ),
            _NavItem(
              icon: Icons.attach_money_rounded,
              label: 'Fees',
              route: '/student/fees',
              isActive: currentRoute == '/student/fees',
            ),
            _NavItem(
              icon: Icons.book_rounded,
              label: 'Assignments',
              route: '/student/assignments',
              isActive: currentRoute == '/student/assignments',
            ),
            _NavItem(
              icon: Icons.campaign_rounded,
              label: 'Notices',
              route: '/student/notices',
              isActive: currentRoute == '/student/notices',
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              route: '/student/profile',
              isActive: currentRoute == '/student/profile',
            ),
            const Spacer(),
            InkWell(
              splashColor: Colors.white.withValues(alpha: 0.08),
              onTap: onLogout,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.logout,
                          size: 18, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.sidebarActive.withValues(alpha: 0.2)
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          splashColor: Colors.white.withValues(alpha: 0.08),
          hoverColor: Colors.white.withValues(alpha: 0.04),
          focusColor: Colors.white.withValues(alpha: 0.12),
          leading: Icon(
            icon,
            color: isActive ? AppColors.sidebarActive : Colors.white54,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 14,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: () => context.go(route),
        ),
      ),
    );
  }
}
