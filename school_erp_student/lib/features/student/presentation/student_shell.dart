import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/presentation/widgets/back_button_handler.dart';
import 'package:school_erp_student/features/student/presentation/widgets/student_bottom_nav.dart';
import 'package:school_erp_student/features/student/presentation/widgets/student_sidebar_nav.dart';

class StudentShell extends ConsumerWidget {
  final Widget child;

  const StudentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return _desktopLayout(context, ref);
        }
        return _mobileLayout(context, ref);
      },
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  }

  Widget _desktopLayout(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    return Row(
      children: [
        StudentSidebarNav(
          currentRoute: currentRoute,
          onLogout: () => _logout(context, ref),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: BackButtonHandler(
            currentRoute: currentRoute,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navIndex(currentRoute);

    return Scaffold(
      body: BackButtonHandler(
        currentRoute: currentRoute,
        child: child,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            showMoreMenu(context);
            return;
          }
          final route = _routes[index];
          if (route != currentRoute) {
            context.go(route);
          }
        },
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.surface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  static const _routes = [
    '/student/dashboard',
    '/student/attendance',
    '/student/timetable',
  ];

  int _navIndex(String route) {
    if (route == '/student/results' ||
        route == '/student/fees' ||
        route == '/student/assignments' ||
        route == '/student/notices' ||
        route == '/student/holidays' ||
        route == '/student/profile') {
      return 3;
    }
    final i = _routes.indexOf(route);
    return i >= 0 ? i : 0;
  }
}
