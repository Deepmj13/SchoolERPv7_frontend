import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_student/core/storage/storage_service.dart';
import 'package:school_erp_student/features/auth/presentation/login_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_attendance_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_dashboard_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_fees_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_assignments_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_notices_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_profile_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_results_screen.dart';
import 'package:school_erp_student/features/student/presentation/student_shell.dart';
import 'package:school_erp_student/features/student/presentation/student_timetable_screen.dart';
import 'route_names.dart';

GoRouter createRouter(StorageService storage) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) async {
      final token = await storage.getToken();
      final isLoggedIn = token != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/student/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student/dashboard',
            name: RouteNames.studentDashboard,
            builder: (context, state) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/attendance',
            name: RouteNames.studentAttendance,
            builder: (context, state) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: '/student/results',
            name: RouteNames.studentResults,
            builder: (context, state) => const StudentResultsScreen(),
          ),
          GoRoute(
            path: '/student/timetable',
            name: RouteNames.studentTimetable,
            builder: (context, state) => const StudentTimetableScreen(),
          ),
          GoRoute(
            path: '/student/fees',
            name: RouteNames.studentFees,
            builder: (context, state) => const StudentFeesScreen(),
          ),
          GoRoute(
            path: '/student/assignments',
            name: RouteNames.studentAssignments,
            builder: (context, state) => const StudentAssignmentsScreen(),
          ),
          GoRoute(
            path: '/student/notices',
            name: RouteNames.studentNotices,
            builder: (context, state) => const StudentNoticesScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            name: RouteNames.studentProfile,
            builder: (context, state) => const StudentProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
