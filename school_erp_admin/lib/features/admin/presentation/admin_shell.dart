import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/connectivity/connectivity_provider.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/back_button_handler.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/sidebar_nav.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_ui_provider.dart';
import 'package:school_erp_admin/features/auth/presentation/providers/auth_state_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      mobile: (context) => _MobileLayout(ref: ref, child: child),
      tablet: (context) => _tabletLayout(context, ref),
      desktop: (context) => _desktopLayout(context, ref),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  }

  Widget _desktopLayout(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    return Row(
      children: [
        SidebarNav(
          currentRoute: currentRoute,
          onLogout: () => _logout(context, ref),
          isCollapsed: isCollapsed,
          onToggleCollapsed: () {
            ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed;
          },
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: BackButtonHandler(
            currentRoute: currentRoute,
            child: _contentArea(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _tabletLayout(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    return Row(
      children: [
        SidebarNav(
          currentRoute: currentRoute,
          onLogout: () => _logout(context, ref),
          isCollapsed: isCollapsed,
          onToggleCollapsed: () {
            ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed;
          },
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: BackButtonHandler(
            currentRoute: currentRoute,
            child: _contentArea(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _contentArea(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    return Column(
      children: [
        if (!isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade800,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'No internet connection',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        Expanded(
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatefulWidget {
  final Widget child;
  final WidgetRef ref;

  const _MobileLayout({required this.ref, required this.child});

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _navIndex(String route) {
    if (route == '/admin/dashboard') return 0;
    if (route == '/admin/students') return 1;
    if (route == '/admin/teachers') return 2;
    if (route == '/admin/fees') return 3;
    if (route == '/admin/more') return 4;
    return 4;
  }

  void _navigateOrOpenDrawer(int index) {
    const routes = [
      '/admin/dashboard',
      '/admin/students',
      '/admin/teachers',
      '/admin/fees',
      '/admin/more',
    ];
    final target = routes[index];
    if (GoRouterState.of(context).matchedLocation == target) return;
    if (index == 4) {
      context.push(target);
    } else {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navIndex(currentRoute);
    final isOnline = widget.ref.watch(connectivityProvider).valueOrNull ?? true;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, currentRoute),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.shade800,
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BackButtonHandler(
                currentRoute: currentRoute,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _navigateOrOpenDrawer,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.surface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Teachers',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Fees',
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

  Widget _buildDrawer(BuildContext context, String currentRoute) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionLabel('ACADEMIC'),
                  _drawerItem(
                    icon: Icons.school_rounded,
                    label: 'Classes',
                    route: '/admin/classes',
                    currentRoute: currentRoute,
                  ),
                  _drawerItem(
                    icon: Icons.book_rounded,
                    label: 'Subjects',
                    route: '/admin/subjects',
                    currentRoute: currentRoute,
                  ),
                  _drawerItem(
                    icon: Icons.assignment_rounded,
                    label: 'Exams',
                    route: '/admin/exams',
                    currentRoute: currentRoute,
                  ),
                  _drawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Timetable',
                    route: '/admin/timetable',
                    currentRoute: currentRoute,
                  ),
                  _drawerItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Attendance',
                    route: '/admin/attendance-report',
                    currentRoute: currentRoute,
                  ),
                  const Divider(height: 1),
                  _buildSectionLabel('COMMUNICATION'),
                  _drawerItem(
                    icon: Icons.campaign_rounded,
                    label: 'Announcements',
                    route: '/admin/announcements',
                    currentRoute: currentRoute,
                  ),
                  const Divider(height: 1),
                  _buildSectionLabel('SYSTEM'),
                  _drawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    route: '/admin/settings',
                    currentRoute: currentRoute,
                  ),
                ],
              ),
            ),
            _buildDrawerFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'School ERP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin Portal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required String route,
    required String currentRoute,
    Color? iconColor,
    Color? textColor,
  }) {
    final isActive = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? (isActive ? AppColors.primary : AppColors.textSecondary),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: textColor ??
                (isActive ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
        selected: isActive,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () {
          Navigator.pop(context);
          if (currentRoute != route) {
            context.go(route);
          }
        },
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 4,
          bottom: MediaQuery.of(context).padding.bottom + 4,
        ),
        child: ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error, size: 22),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: () {
            Navigator.pop(context);
            widget.ref.read(authStateProvider.notifier).logout();
            context.go('/login');
          },
        ),
      ),
    );
  }
}
