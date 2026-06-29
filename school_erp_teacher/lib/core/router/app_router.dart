import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_teacher/core/storage/storage_service.dart';
import 'package:school_erp_teacher/features/auth/presentation/login_screen.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_announcements_screen.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_attendance_screen.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_marks_screen.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_profile_screen.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_shell.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_timetable_screen.dart';
import 'route_names.dart';

GoRouter createRouter(StorageService storage) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) async {
      final token = await storage.getToken();
      final isLoggedIn = token != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/teacher/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
            path: '/teacher/dashboard',
            name: RouteNames.teacherDashboard,
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/attendance',
            name: RouteNames.teacherAttendance,
            builder: (context, state) => const TeacherAttendanceScreen(),
          ),
          GoRoute(
            path: '/teacher/marks',
            name: RouteNames.teacherMarks,
            builder: (context, state) => const TeacherMarksScreen(),
          ),
          GoRoute(
            path: '/teacher/timetable',
            name: RouteNames.teacherTimetable,
            builder: (context, state) => const TeacherTimetableScreen(),
          ),
          GoRoute(
            path: '/teacher/announcements',
            name: RouteNames.teacherAnnouncements,
            builder: (context, state) => const TeacherAnnouncementsScreen(),
          ),
          GoRoute(
            path: '/teacher/profile',
            name: RouteNames.teacherProfile,
            builder: (context, state) => const TeacherProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
