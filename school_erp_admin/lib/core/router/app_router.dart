import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/storage/storage_interface.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_announcements_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_attendance_report_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_classes_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_exams_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_fees_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_more_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_settings_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_shell.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_students_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_subjects_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_teachers_screen.dart';
import 'package:school_erp_admin/features/admin/presentation/admin_timetable_screen.dart';
import 'package:school_erp_admin/features/auth/presentation/login_screen.dart';
import 'route_names.dart';

GoRouter createRouter(StorageInterface storage) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) async {
      final token = await storage.getToken();
      final isLoggedIn = token != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/admin/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: RouteNames.adminDashboard,
            pageBuilder: (context, state) => _fadePage(
              const AdminDashboardScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/students',
            name: RouteNames.adminStudents,
            pageBuilder: (context, state) => _fadePage(
              const AdminStudentsScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/teachers',
            name: RouteNames.adminTeachers,
            pageBuilder: (context, state) => _fadePage(
              const AdminTeachersScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/classes',
            name: RouteNames.adminClasses,
            pageBuilder: (context, state) => _fadePage(
              const AdminClassesScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/attendance-report',
            name: RouteNames.adminAttendanceReport,
            pageBuilder: (context, state) => _fadePage(
              const AdminAttendanceReportScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/subjects',
            name: RouteNames.adminSubjects,
            pageBuilder: (context, state) => _fadePage(
              const AdminSubjectsScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/exams',
            name: RouteNames.adminExams,
            pageBuilder: (context, state) => _fadePage(
              const AdminExamsScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/timetable',
            name: RouteNames.adminTimetable,
            pageBuilder: (context, state) => _fadePage(
              const AdminTimetableScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/fees',
            name: RouteNames.adminFees,
            pageBuilder: (context, state) => _fadePage(
              const AdminFeesScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/announcements',
            name: RouteNames.adminAnnouncements,
            pageBuilder: (context, state) => _fadePage(
              const AdminAnnouncementsScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            name: RouteNames.adminSettings,
            pageBuilder: (context, state) => _fadePage(
              const AdminSettingsScreen(),
              state,
            ),
          ),
          GoRoute(
            path: '/admin/more',
            name: RouteNames.adminMore,
            pageBuilder: (context, state) => _fadePage(
              const AdminMoreScreen(),
              state,
            ),
          ),
        ],
      ),
    ],
  );
}

Page<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
