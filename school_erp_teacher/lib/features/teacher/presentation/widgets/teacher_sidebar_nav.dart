import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';

class TeacherSidebarNav extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onLogout;

  const TeacherSidebarNav({
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
            Row(
              children: [
                const SizedBox(width: 20),
                Icon(Icons.school_rounded,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
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
                'Teacher Panel',
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
              route: '/teacher/dashboard',
              isActive: currentRoute == '/teacher/dashboard',
            ),
            _NavItem(
              icon: Icons.calendar_today_rounded,
              label: 'Attendance',
              route: '/teacher/attendance',
              isActive: currentRoute == '/teacher/attendance',
            ),
            _NavItem(
              icon: Icons.assignment_rounded,
              label: 'Assignments',
              route: '/teacher/assignments',
              isActive: currentRoute.startsWith('/teacher/assignments'),
            ),
            _NavItem(
              icon: Icons.scoreboard_rounded,
              label: 'Marks',
              route: '/teacher/marks',
              isActive: currentRoute == '/teacher/marks',
            ),
            _NavItem(
              icon: Icons.campaign_rounded,
              label: 'Announcements',
              route: '/teacher/announcements',
              isActive: currentRoute == '/teacher/announcements',
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              route: '/teacher/profile',
              isActive: currentRoute == '/teacher/profile',
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.logout,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text(
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
