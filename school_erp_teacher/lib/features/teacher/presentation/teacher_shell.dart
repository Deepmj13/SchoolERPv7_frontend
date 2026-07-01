import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/presentation/widgets/back_button_handler.dart';
import 'package:school_erp_teacher/features/teacher/presentation/widgets/teacher_bottom_nav.dart';
import 'package:school_erp_teacher/features/teacher/presentation/widgets/teacher_sidebar_nav.dart';

class TeacherShell extends ConsumerWidget {
  final Widget child;

  const TeacherShell({super.key, required this.child});

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
        TeacherSidebarNav(
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
          if (index == 2) {
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
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  static const _routes = [
    '/teacher/dashboard',
    '/teacher/attendance',
  ];

  int _navIndex(String route) {
    if (route == '/teacher/marks' ||
        route == '/teacher/assignments' ||
        route == '/teacher/announcements' ||
        route == '/teacher/profile') {
      return 2;
    }
    final i = _routes.indexOf(route);
    return i >= 0 ? i : 0;
  }
}
