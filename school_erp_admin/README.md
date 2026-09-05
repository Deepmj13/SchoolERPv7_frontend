# School ERP Admin Portal

Full-featured admin dashboard for managing all aspects of a school — students, teachers, staff, classes, subjects, exams, grading, timetables, attendance, fees, announcements, holidays, proxies, reports, and promotions.

**See also:** [Root README](../README.md) for shared architecture, theme system, and cross-app guides.

---

## Table of Contents

- [File Structure](#file-structure)
- [Entry Points](#entry-points)
- [Core Layer](#core-layer)
- [Auth Feature](#auth-feature)
- [Domain Models](#domain-models)
- [Repository Methods](#repository-methods)
- [API Endpoints](#api-endpoints)
- [Screens](#screens)
- [Providers](#providers)
- [Widgets](#widgets)
- [Step-by-Step Guides](#step-by-step-guides)

---

## File Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── endpoints.dart
│   │   ├── security_client_default.dart
│   │   └── security_client_io.dart
│   ├── connectivity/
│   │   └── connectivity_provider.dart
│   ├── logging/
│   │   └── app_logger.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── storage/
│   │   ├── storage_interface.dart
│   │   └── storage_service.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── theme_mode_provider.dart
│   └── widgets/
│       ├── adaptive_layout.dart
│       ├── change_password_dialog.dart
│       ├── custom_button.dart
│       ├── error_retry_widget.dart
│       ├── glass_card.dart
│       ├── list_skeleton_loader.dart
│       ├── loading_overlay.dart
│       ├── shimmer.dart
│       └── skeleton_loader.dart
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── domain/user_model.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── providers/auth_state_provider.dart
│   └── admin/
│       ├── data/admin_repository.dart
│       ├── domain/admin_models.dart
│       └── presentation/
│           ├── admin_shell.dart
│           ├── admin_dashboard_screen.dart
│           ├── admin_students_screen.dart
│           ├── admin_teachers_screen.dart
│           ├── admin_classes_screen.dart
│           ├── admin_subjects_screen.dart
│           ├── admin_exams_screen.dart
│           ├── admin_mark_entry_screen.dart
│           ├── admin_grading_screen.dart
│           ├── admin_timetable_screen.dart
│           ├── admin_fees_screen.dart
│           ├── admin_announcements_screen.dart
│           ├── admin_attendance_report_screen.dart
│           ├── admin_reports_screen.dart
│           ├── admin_holidays_screen.dart
│           ├── admin_promotion_screen.dart
│           ├── admin_staff_screen.dart
│           ├── admin_settings_screen.dart
│           ├── admin_proxies_screen.dart
│           ├── admin_more_screen.dart
│           ├── student_detail_screen.dart
│           ├── teacher_detail_screen.dart
│           ├── providers/
│           │   ├── admin_repository_provider.dart
│           │   ├── admin_ui_provider.dart
│           │   └── timetable_provider.dart
│           └── widgets/
│               ├── admin_form_dialog.dart
│               ├── admin_form_sheet.dart
│               ├── analytics_section.dart
│               ├── back_button_handler.dart
│               ├── dashboard_header.dart
│               ├── data_table_widget.dart
│               ├── quick_actions_grid.dart
│               ├── recent_activity_feed.dart
│               ├── sidebar_nav.dart
│               ├── stats_overview_grid.dart
│               ├── stats_panel.dart
│               ├── timetable_form_sheet.dart
│               └── timetable_matrix_editor.dart
└── test/
    ├── widget_test.dart
    └── features/
        ├── auth/domain/user_model_test.dart
        └── admin/domain/admin_models_test.dart
```

---

## Entry Points

### `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();                              // 1. Initialize logging
  final storage = StorageService();              // 2. Create storage instance
  await storage.init();                          // 3. Initialize FlutterSecureStorage
  final sentryDsn = String.fromEnvironment('SENTRY_DSN');  // 4. Read Sentry DSN
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {         // 5. Initialize Sentry if DSN provided
      options.dsn = sentryDsn;
      options.tracesSampleRate = 0.1;
    }, appRunner: () => runApp(ProviderScope(    // 6. Wrap in Riverpod ProviderScope
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const SchoolErpAdminApp(),
    )));
  } else {
    runApp(ProviderScope(                        // 7. Run without Sentry if no DSN
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const SchoolErpAdminApp(),
    ));
  }
}
```

**Key:** The `storageServiceProvider` is overridden at the root with a real `StorageService` instance. All downstream providers receive this instance via Riverpod dependency injection.

### `app.dart`

```dart
class SchoolErpAdminApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);           // Watch GoRouter
    final themeMode = ref.watch(themeModeProvider);     // Watch theme mode (admin-only)

    // Listen for logout → redirect to /login
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (prev?.status == AuthStatus.authenticated &&
          next.status == AuthStatus.unauthenticated) {
        router.go('/login');
      }
    });

    return MaterialApp.router(
      title: 'School ERP Admin',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,          // Admin: user-selectable (light/dark/system)
      routerConfig: router,
    );
  }
}
```

The `routerProvider` also wires up `apiClient.onUnauthorized` to trigger `authStateProvider.notifier.logout()`.

---

## Core Layer

### API Client (`core/api/api_client.dart`)

| Property | Value |
|----------|-------|
| Default timeout | 30 seconds |
| Refresh timeout | 15 seconds |
| Max retries | 3 |
| Retry on | 502, 503, 504, 429 |
| Backoff | `pow(2, retry) * 1000ms + random(0-500ms)` jitter |

**Public methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `get` | `Future<http.Response> get(String path, {Map<String, String>? headers, Duration? timeout})` | GET request with Bearer auth |
| `post` | `Future<http.Response> post(String path, {Object? body, Map<String, String>? headers, Duration? timeout})` | POST request |
| `put` | `Future<http.Response> put(String path, {Object? body, Map<String, String>? headers, Duration? timeout})` | PUT request |
| `patch` | `Future<http.Response> patch(String path, {Object? body, Map<String, String>? headers, Duration? timeout})` | PATCH request |
| `delete` | `Future<http.Response> delete(String path, {Map<String, String>? headers, Duration? timeout})` | DELETE request |
| `download` | `Future<List<int>> download(String path, {String? classId, String? startDate, String? endDate, String? groupBy, String? format, Duration? timeout})` | **Admin-only** — download binary file (Excel/PDF report). 60s timeout. Returns raw bytes. |
| `dispose` | `void dispose()` | Closes the underlying `http.Client` |

**401 handling:** On 401, calls `_tryRefreshToken()` which POSTs to `/api/v1/auth/refresh` with body `{'token': expiredToken}` (without Authorization header — admin-only difference). If refresh succeeds, retries the original request once. If refresh fails, clears storage and calls `onUnauthorized`.

**`ApiException`** class:
```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
}
```

### Endpoints (`core/api/endpoints.dart`)

**Base URL:** `String.fromEnvironment('API_BASE_URL', defaultValue: 'https://renderbackned.onrender.com')`
**API Prefix:** `/api/v1`

| Constant | Value |
|----------|-------|
| `login` | `/api/v1/auth/login` |
| `refresh` | `/api/v1/auth/refresh` |
| `changePassword` | `/api/v1/auth/change-password` |
| `dashboardStats` | `/api/v1/admin/dashboard/stats` |
| `schoolProfile` | `/api/v1/admin/school` |
| `students` | `/api/v1/students` |
| `teachers` | `/api/v1/teachers` |
| `classes` | `/api/v1/classes` |
| `subjects` | `/api/v1/subjects` |
| `subjectsByClass` | `/api/v1/subjects/by-class` |
| `exams` | `/api/v1/exams` |
| `timetable` | `/api/v1/timetable` |
| `attendance` | `/api/v1/attendance` |
| `attendanceMark` | `/api/v1/attendance/mark` |
| `feeStructures` | `/api/v1/fees/structures` |
| `feePosts` | `/api/v1/fees/posts` |
| `feesPending` | `/api/v1/fees/pending` |
| `feesPayments` | `/api/v1/fees/payments` |
| `feesUnpaid` | `/api/v1/fees/unpaid` |
| `announcements` | `/api/v1/announcements` |
| `holidays` | `/api/v1/holidays` |
| `gradingSystems` | `/api/v1/grading` |
| `gradingFindGrade` | `/api/v1/grading/find-grade` |
| `staff` | `/api/v1/staff` |
| `staffDepartments` | `/api/v1/staff/departments` |
| `proxyAssign` | `/api/v1/proxy/assign` |
| `proxyAvailable` | `/api/v1/proxy/available` |
| `proxyTeachers` | `/api/v1/proxy/teachers` |
| `proxyAdminAll` | `/api/v1/proxy/admin/all` |
| `resultsBulk` | `/api/v1/results/bulk` |
| `results` | `/api/v1/results` |
| `studentsPromote` | `/api/v1/students/promote` |
| `reportStudentStrength` | `/api/v1/reports/student-strength` |
| `reportAttendance` | `/api/v1/reports/attendance` |
| `reportFeeCollection` | `/api/v1/reports/fee-collection` |
| `reportTeacherWorkload` | `/api/v1/reports/teacher-workload` |
| `reportAdmissions` | `/api/v1/reports/admissions` |

**Dynamic endpoint methods:**

| Method | Signature | Value |
|--------|-----------|-------|
| `student(id)` | `static String student(String id)` | `/api/v1/students/$id` |
| `activateStudent(id)` | `static String activateStudent(String id)` | `/api/v1/students/$id/activate` |
| `teacher(id)` | `static String teacher(String id)` | `/api/v1/teachers/$id` |
| `teacherClasses(id)` | `static String teacherClasses(String id)` | `/api/v1/teachers/$id/classes` |
| `teacherSubjects(id)` | `static String teacherSubjects(String id)` | `/api/v1/teachers/$id/subjects` |
| `teacherTimetable(id)` | `static String teacherTimetable(String id)` | `/api/v1/teachers/$id/timetable` |
| `classById(id)` | `static String classById(String id)` | `/api/v1/classes/$id` |
| `classStudents(id)` | `static String classStudents(String id)` | `/api/v1/classes/$id/students` |
| `classTimetable(id)` | `static String classTimetable(String id)` | `/api/v1/classes/$id/timetable` |
| `attendanceRecord(id)` | `static String attendanceRecord(String id)` | `/api/v1/attendance/$id` |
| `studentAttendance(id)` | `static String studentAttendance(String id)` | `/api/v1/attendance/student/$id` |
| `assignSubject(id)` | `static String assignSubject(String id)` | `/api/v1/subjects/$id/assign` |
| `exam(id)` | `static String exam(String id)` | `/api/v1/exams/$id` |
| `examClasses(examId)` | `static String examClasses(String examId)` | `/api/v1/exams/$examId/classes` |
| `publishExam(id)` | `static String publishExam(String id)` | `/api/v1/exams/$id/publish` |
| `timetableEntry(id)` | `static String timetableEntry(String id)` | `/api/v1/timetable/$id` |
| `studentFees(id)` | `static String studentFees(String id)` | `/api/v1/fees/student/$id` |
| `feePost(id)` | `static String feePost(String id)` | `/api/v1/fees/posts/$id` |
| `announcement(id)` | `static String announcement(String id)` | `/api/v1/announcements/$id` |
| `holiday(id)` | `static String holiday(String id)` | `/api/v1/holidays/$id` |
| `gradingSystem(id)` | `static String gradingSystem(String id)` | `/api/v1/grading/$id` |
| `examSubjects(examId)` | `static String examSubjects(String examId)` | `/api/v1/exams/$examId/subjects` |
| `examSubject(examId, subjectId)` | `static String examSubject(String examId, String subjectId)` | `/api/v1/exams/$examId/subjects/$subjectId` |
| `staffMember(id)` | `static String staffMember(String id)` | `/api/v1/staff/$id` |
| `proxyRespond(id)` | `static String proxyRespond(String id)` | `/api/v1/proxy/$id/respond` |
| `proxyCancel(id)` | `static String proxyCancel(String id)` | `/api/v1/proxy/$id` |
| `proxyTodayForClass(classId)` | `static String proxyTodayForClass(String classId)` | `/api/v1/proxy/today?classId=$classId` |
| `studentResults(id)` | `static String studentResults(String id)` | `/api/v1/results/student/$id` |

### Storage (`core/storage/`)

**Keys used:**

| Key | Purpose |
|-----|---------|
| `jwt_token` | JWT access token |
| `user_profile` | Serialized `UserModel` JSON |
| `theme_mode` | `'light'` / `'dark'` / `'system'` |

**`StorageInterface` methods:**

| Method | Return Type |
|--------|-------------|
| `saveToken(String token)` | `Future<void>` |
| `getToken()` | `Future<String?>` |
| `saveUser(Map<String, dynamic> user)` | `Future<void>` |
| `getUser()` | `Future<Map<String, dynamic>?>` |
| `saveThemeMode(String mode)` | `Future<void>` |
| `getThemeMode()` | `Future<String?>` |
| `clear()` | `Future<void>` |

### Router (`core/router/`)

**Route names** (`route_names.dart`):

| Constant | Value |
|----------|-------|
| `login` | `'login'` |
| `adminDashboard` | `'adminDashboard'` |
| `adminStudents` | `'adminStudents'` |
| `adminTeachers` | `'adminTeachers'` |
| `adminClasses` | `'adminClasses'` |
| `adminAttendanceReport` | `'adminAttendanceReport'` |
| `adminSubjects` | `'adminSubjects'` |
| `adminExams` | `'adminExams'` |
| `adminTimetable` | `'adminTimetable'` |
| `adminFees` | `'adminFees'` |
| `adminAnnouncements` | `'adminAnnouncements'` |
| `adminSettings` | `'adminSettings'` |
| `adminMore` | `'adminMore'` |
| `adminReports` | `'adminReports'` |
| `adminGrading` | `'adminGrading'` |
| `adminMarkEntry` | `'adminMarkEntry'` |
| `adminPromotion` | `'adminPromotion'` |
| `adminHolidays` | `'adminHolidays'` |
| `adminStaff` | `'adminStaff'` |
| `adminProxies` | `'adminProxies'` |

**Route paths** (`app_router.dart`):

| Path | Route Name | Screen |
|------|-----------|--------|
| `/login` | `login` | `LoginScreen` |
| `/admin/dashboard` | `adminDashboard` | `AdminDashboardScreen` |
| `/admin/students` | `adminStudents` | `AdminStudentsScreen` |
| `/admin/teachers` | `adminTeachers` | `AdminTeachersScreen` |
| `/admin/classes` | `adminClasses` | `AdminClassesScreen` |
| `/admin/attendance-report` | `adminAttendanceReport` | `AdminAttendanceReportScreen` |
| `/admin/subjects` | `adminSubjects` | `AdminSubjectsScreen` |
| `/admin/exams` | `adminExams` | `AdminExamsScreen` |
| `/admin/timetable` | `adminTimetable` | `AdminTimetableScreen` |
| `/admin/fees` | `adminFees` | `AdminFeesScreen` |
| `/admin/announcements` | `adminAnnouncements` | `AdminAnnouncementsScreen` |
| `/admin/settings` | `adminSettings` | `AdminSettingsScreen` |
| `/admin/more` | `adminMore` | `AdminMoreScreen` |
| `/admin/reports` | `adminReports` | `AdminReportsScreen` |
| `/admin/grading` | `adminGrading` | `AdminGradingScreen` |
| `/admin/mark-entry/:examId` | `adminMarkEntry` | `AdminMarkEntryScreen` |
| `/admin/promotion` | `adminPromotion` | `AdminPromotionScreen` |
| `/admin/holidays` | `adminHolidays` | `AdminHolidaysScreen` |
| `/admin/staff` | `adminStaff` | `AdminStaffScreen` |
| `/admin/proxies` | `adminProxies` | `AdminProxiesScreen` |

**Auth redirect:** If no token in storage and path is not `/login` → redirect to `/login`. If token exists and path is `/login` → redirect to `/admin/dashboard`.

**Page transitions:** All admin routes use `CustomTransitionPage` with `FadeTransition` (300ms).

### Theme (`core/theme/`)

The admin app has an **extended color palette** compared to student/teacher, with additional tokens for light-mode sidebar, dark-mode backgrounds, and interaction overlays:

| Extra Token | Hex | Purpose |
|-------------|-----|---------|
| `textDarkPrimary` | `#E0E0E0` | Light text on dark bg |
| `textDarkSecondary` | `#9E9E9E` | Muted text on dark bg |
| `glassHighlight` | `#33FFFFFF` | Highlight overlay |
| `hoverOverlay` | `#0AFFFFFF` | Hover state |
| `activeOverlay` | `#1AFFFFFF` | Active state |
| `sidebarBg` | `#000000` | Dark sidebar bg (admin uses pure black) |
| `sidebarBgLight` | `#F5F5F5` | Light sidebar bg |
| `sidebarActiveLight` | `#000000` | Active item in light sidebar |
| `sidebarHoverLight` | `#0A000000` | Hover in light sidebar |

**Admin-only:** `themeModeProvider` in `core/theme/theme_mode_provider.dart` — a `StateNotifierProvider<ThemeModeNotifier, ThemeMode>` that persists the user's theme choice (light/dark/system) to secure storage. The admin settings screen provides a toggle.

**Responsive breakpoints** (`core/widgets/adaptive_layout.dart`):

| Tier | Width | Behavior |
|------|-------|----------|
| Mobile | < 600px | Bottom `NavigationBar` + drawer |
| Tablet | 600–1100px | Collapsible sidebar (narrow) |
| Desktop | ≥ 1100px | Full sidebar |

**`ResponsiveContext` extension** on `BuildContext`:
```dart
context.isMobile   // width < 600
context.isTablet   // 600 <= width < 1100
context.isDesktop  // width >= 1100
```

### Widgets (`core/widgets/`)

| Widget | File | Props | Description |
|--------|------|-------|-------------|
| `AdaptiveLayout` | `adaptive_layout.dart` | `mobile`, `tablet`, `desktop` (WidgetBuilder) | Three-tier responsive switcher |
| `GlassCard` | `glass_card.dart` | `child`, `onTap?` | Semi-transparent card with glassmorphism effect, adapts to light/dark mode |
| `CustomButton` | `custom_button.dart` | `text`, `onTap`, `isLoading`, `isOutlined` | Button with loading spinner |
| `LoadingOverlay` | `loading_overlay.dart` | `isLoading`, `child` | Wraps child with semi-transparent overlay + circular progress |
| `SkeletonLoader` | `skeleton_loader.dart` | `width`, `height`, `borderRadius` | Basic rectangular skeleton block with shimmer |
| `Shimmer` | `shimmer.dart` | `child` | Wraps child in ShaderMask shimmer animation |
| `ListSkeletonLoader` | `list_skeleton_loader.dart` | `itemCount` | Pre-built list of GlassCard + Shimmer skeletons |
| `ErrorRetryWidget` | `error_retry_widget.dart` | `message`, `onRetry` | Error state with icon, message, and retry button |
| `ChangePasswordDialog` | `change_password_dialog.dart` | — | Reusable dialog with old/new/confirm fields + validation |

---

## Auth Feature

### UserModel (`features/auth/domain/user_model.dart`)

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `token` | `String` | `token` | yes |
| `role` | `String` | `role` | yes |
| `userId` | `String` | `userId` | yes |
| `teacherId` | `String?` | `teacherId` | no |
| `studentId` | `String?` | `studentId` | no |

**Getter:** `bool get isAdmin => role == 'admin';`

### AuthRepository (`features/auth/data/auth_repository.dart`)

| Method | Parameters | Return | Endpoint | HTTP |
|--------|-----------|--------|----------|------|
| `login(email, password)` | `String email, String password` | `Future<UserModel>` | `POST /api/v1/auth/login` | POST |
| `changePassword(oldPw, newPw)` | `String oldPassword, String newPassword` | `Future<void>` | `POST /api/v1/auth/change-password` | POST |

### AuthStateNotifier

**States** (`AuthState`):
- `status`: `AuthStatus` enum — `unauthenticated`, `authenticating`, `authenticated`, `error`
- `user`: `UserModel?`
- `errorMessage`: `String?`

**Methods:**
- `_tryAutoLogin()` — reads token from storage; if present, loads user; if `!user.isAdmin`, clears storage
- `login(email, password)` — sets `authenticating` → calls repo → **rejects non-admin** → saves token/user → sets `authenticated`
- `logout()` — clears storage → sets `unauthenticated`

### LoginScreen

- Email field: validated with regex pattern
- Password field: minimum 6 characters
- Connectivity banner: shows offline warning when `connectivityProvider` is false
- Login button: shows loading during `authenticating` state
- Error box: displays `errorMessage` when status is `error`
- On success: navigates to `/admin/dashboard` via `context.go()`

---

## Domain Models

All models are in `features/admin/domain/admin_models.dart`. Global constant: `defaultUserPassword = 'ChangeMe@123'`.

### SchoolProfile

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `name` | `String` | `name` | yes |
| `address` | `String?` | `address` | no |
| `phone` | `String?` | `phone` | no |
| `email` | `String?` | `email` | no |
| `website` | `String?` | `website` | no |
| `logoUrl` | `String?` | `logo_url` | no |
| `academicYear` | `String?` | `academic_year` | no |
| `establishedYear` | `String?` | `established_year` | no |

**Methods:** `toUpdateJson()` — returns map with only non-null, non-empty fields.

### DashboardStats

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `totalStudents` | `int` | `totalStudents` | yes |
| `totalTeachers` | `int` | `totalTeachers` | yes |
| `totalClasses` | `int` | `totalClasses` | yes |
| `todayAttendancePercentage` | `double` | `todayAttendancePercentage` | yes |

### Student

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `userId` | `String` | `user_id` | yes |
| `fullName` | `String` | `full_name` | yes |
| `classId` | `String?` | `class_id` | no |
| `rollNumber` | `String?` | `roll_number` | no |
| `dob` | `String?` | `dob` | no |
| `parentName` | `String?` | `parent_name` | no |
| `parentPhone` | `String?` | `parent_phone` | no |
| `emergencyContact` | `String?` | `emergency_contact` | no |
| `isActive` | `bool` | `is_active` | yes |
| `email` | `String?` | `email` | no |
| `className` | `String?` | `class_name` | no |
| `classSection` | `String?` | `class_section` | no |

**Methods:**
- `toCreateJson()` — `{full_name, email, password: defaultUserPassword, class_id, roll_number, parent_name, parent_phone}`
- `toUpdateJson()` — `{full_name, class_id, roll_number, parent_name, parent_phone, is_active}`

### Teacher

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `userId` | `String` | `user_id` | yes |
| `fullName` | `String` | `full_name` | yes |
| `phone` | `String?` | `phone` | no |
| `isActive` | `bool` | `is_active` | yes |
| `email` | `String?` | `email` | no |

**Methods:**
- `toCreateJson()` — `{full_name, email, password: defaultUserPassword, phone}`
- `toUpdateJson()` — `{full_name, phone, is_active}`

### TeacherAssignment

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `classId` | `String` | `class_id` | yes |
| `className` | `String` | `class_name` | yes |
| `section` | `String` | `section` | yes |
| `subjectId` | `String` | `subject_id` | yes |
| `subjectName` | `String` | `subject_name` | yes |

### Subject

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `name` | `String` | `name` | yes |

**Equality:** `operator ==` and `hashCode` based on `id`.

### ClassSubjects

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `classId` | `String` | `class_id` | yes |
| `className` | `String` | `class_name` | yes |
| `section` | `String` | `section` | yes |
| `subjects` | `List<Subject>` | `subjects` | yes |

**Computed:** `displayName` — `'$className - $section'` or just `'$className'` if section empty.

### ClassModel

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `name` | `String` | `name` | yes |
| `section` | `String` | `section` | yes |
| `classTeacherId` | `String?` | `class_teacher_id` | no |
| `classTeacherName` | `String?` | `class_teacher_name` | no |
| `studentCount` | `int` | `student_count` | yes |

**Methods:**
- `toCreateJson()` — `{name, section, class_teacher_id}`
- `toUpdateJson()` — `{name, section, class_teacher_id}`

**Computed:** `displayName`, `display` — both return `'$name - $section'`.

### Announcement

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `title` | `String` | `title` | yes |
| `body` | `String?` | `body` | no |
| `classId` | `String?` | `class_id` | no |
| `createdBy` | `String` | `created_by` | yes |
| `createdAt` | `String` | `created_at` | yes |
| `createdByEmail` | `String?` | `created_by_email` | no |

**Computed:** `isSchoolWide` — `true` if `classId == null`.

### PaginatedResponse\<T\> (Generic)

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `items` | `List<T>` | `data` | yes |
| `total` | `int` | `total` | yes |
| `page` | `int` | `page` | yes |
| `pages` | `int` | `pages` | yes |

**fromJson** takes a `T Function(Map<String, dynamic>) fromItem` callback. Handles both `List` (single page) and `Map` (paginated) responses.

### AttendanceRecord

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `studentId` | `String` | `student_id` | yes |
| `classId` | `String` | `class_id` | yes |
| `date` | `String` | `date` | yes |
| `status` | `String` | `status` | yes |
| `markedBy` | `String` | `marked_by` | yes |
| `studentName` | `String` | `student_name` | yes |
| `rollNumber` | `String?` | `roll_number` | no |

### ExamClass

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `name` | `String` | `name` | yes |
| `section` | `String?` | `section` | no |

**Computed:** `displayName` — `'$name - $section'` or just `'$name'`.

### Exam

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `name` | `String` | `name` | yes | — |
| `examDate` | `String?` | `exam_date` | no | — |
| `isPublished` | `bool` | `is_published` | no | `false` |
| `classes` | `List<ExamClass>` | `classes` | no | `const []` |

### TimetableEntry

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `classId` | `String` | `class_id` | yes | — |
| `subjectId` | `String` | `subject_id` | yes | — |
| `teacherId` | `String` | `teacher_id` | yes | — |
| `day` | `String` | `day` | yes | — |
| `startTime` | `String` | `start_time` | yes | — |
| `endTime` | `String` | `end_time` | yes | — |
| `room` | `String?` | `room` | no | — |
| `subjectName` | `String?` | `subject_name` | no | — |
| `teacherName` | `String?` | `teacher_name` | no | — |
| `className` | `String?` | `class_name` | no | — |
| `classSection` | `String?` | `class_section` | no | — |
| `proxyTeacherId` | `String?` | `proxy_teacher_id` | no | — |
| `originalTeacherId` | `String?` | `original_teacher_id` | no | — |
| `hasProxy` | `bool` | `has_proxy` | no | `false` |

**Computed:** `dayLabel` (maps `mon`→`Monday`, etc.), `classDisplay` (`'$className - $classSection'`).

### FeeStructure

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `feeType` | `String` | `fee_type` | yes |
| `amount` | `double` | `amount` | yes |
| `classId` | `String?` | `class_id` | no |
| `className` | `String?` | `class_name` | no |
| `postTitle` | `String?` | `post_title` | no |

### FeePost

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `title` | `String` | `title` | yes | — |
| `description` | `String?` | `description` | no | — |
| `dueDate` | `String?` | `due_date` | no | — |
| `structures` | `List<FeeStructure>` | `structures` | no | `const []` |

### UnpaidFeeItem

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `studentId` | `String` | `student_id` | yes | — |
| `studentName` | `String` | `student_name` | yes | — |
| `className` | `String` | `className` | yes | `''` |
| `feeStructureId` | `String` | `fee_structure_id` | yes | — |
| `feeType` | `String` | `fee_type` | yes | — |
| `amount` | `double` | `amount` | yes | — |
| `totalAmount` | `double` | `total_amount` | no | `0` |
| `dueDate` | `String?` | `due_date` | no | — |
| `paymentStatus` | `String` | `payment_status` | no | `'none'` |

**Computed:** `isPartial` (`paymentStatus == 'partial'`), `isNone` (`paymentStatus == 'none'`).

### StaffMember

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `userId` | `String` | `user_id` | yes |
| `fullName` | `String` | `full_name` | yes |
| `email` | `String?` | `email` | no |
| `phone` | `String?` | `phone` | no |
| `department` | `String?` | `department` | no |
| `designation` | `String?` | `designation` | no |
| `salary` | `double?` | `salary` | no |
| `joiningDate` | `String?` | `joining_date` | no |
| `isActive` | `bool` | `is_active` | yes |

**Methods:**
- `toCreateJson()` — `{email, password: defaultUserPassword, full_name, phone, department, designation, salary, joining_date}`
- `toUpdateJson()` — `{full_name, phone, department, designation, salary, joining_date, is_active}`

### Holiday

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `title` | `String` | `title` | yes | — |
| `description` | `String?` | `description` | no | — |
| `date` | `String` | `date` | yes | — |
| `type` | `String` | `type` | no | `'holiday'` |
| `isRecurring` | `bool` | `is_recurring` | no | `false` |

**Computed:** `isHoliday` (`type == 'holiday'`), `displayType` (`'Holiday'` or `'Event'`).

### ProxyAssignment

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `timetableId` | `String` | `timetable_id` | yes | — |
| `date` | `String` | `date` | yes | — |
| `originalTeacherId` | `String` | `original_teacher_id` | yes | — |
| `originalTeacherName` | `String` | `original_teacher_name` | yes | `''` |
| `proxyTeacherId` | `String` | `proxy_teacher_id` | yes | — |
| `proxyTeacherName` | `String` | `proxy_teacher_name` | yes | `''` |
| `requestedBy` | `String` | `requested_by` | yes | — |
| `requestedByEmail` | `String?` | `requested_by_email` | no | — |
| `status` | `String` | `status` | yes | `'pending'` |
| `reason` | `String?` | `reason` | no | — |
| `subjectId` | `String?` | `subject_id` | no | — |
| `subjectName` | `String?` | `subject_name` | no | — |
| `day` | `String?` | `day` | no | — |
| `startTime` | `String?` | `start_time` | no | — |
| `endTime` | `String?` | `end_time` | no | — |
| `room` | `String?` | `room` | no | — |
| `className` | `String?` | `class_name` | no | — |
| `classSection` | `String?` | `class_section` | no | — |

**Computed:** `classDisplay`, `dayLabel`, `statusLabel` (capitalized), `isPending`, `isAccepted`, `isRejected`, `isCancelled`.

### GradingRange, GradingSystem, ExamSubject

Additional model classes defined in the same file for grading and exam subject management. See `admin_models.dart` for full field definitions.

---

## Repository Methods

All methods are in `features/admin/data/admin_repository.dart` (76 methods total).

### Staff

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getStaffPage` | `({int page, int limit, String? department})` → `Future<PaginatedResponse<StaffMember>>` | GET | `/api/v1/staff` |
| `createStaff` | `(Map<String, dynamic> body)` → `Future<StaffMember>` | POST | `/api/v1/staff` |
| `updateStaff` | `(String id, Map<String, dynamic> body)` → `Future<StaffMember>` | PUT | `/api/v1/staff/$id` |
| `deleteStaff` | `(String id)` → `Future<void>` | DELETE | `/api/v1/staff/$id` |
| `getStaffDepartments` | `()` → `Future<List<String>>` | GET | `/api/v1/staff/departments` |

### School

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getSchoolProfile` | `()` → `Future<SchoolProfile>` | GET | `/api/v1/admin/school` |
| `updateSchoolProfile` | `(Map<String, dynamic> body)` → `Future<SchoolProfile>` | PUT | `/api/v1/admin/school` |
| `getDashboardStats` | `()` → `Future<DashboardStats>` | GET | `/api/v1/admin/dashboard/stats` |

### Students

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getStudents` | `()` → `Future<List<Student>>` | GET | `/api/v1/students` |
| `getStudentsPage` | `({int page, int limit, String? search})` → `Future<PaginatedResponse<Student>>` | GET | `/api/v1/students` |
| `createStudent` | `(Map<String, dynamic> body)` → `Future<Student>` | POST | `/api/v1/students` |
| `updateStudent` | `(String id, Map<String, dynamic> body)` → `Future<Student>` | PUT | `/api/v1/students/$id` |
| `deleteStudent` | `(String id)` → `Future<void>` | DELETE | `/api/v1/students/$id` |
| `activateStudent` | `(String id)` → `Future<void>` | PATCH | `/api/v1/students/$id/activate` |
| `promoteStudents` | `(Map<String, dynamic> body)` → `Future<Map<String, dynamic>>` | POST | `/api/v1/students/promote` |

### Teachers

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getTeachers` | `()` → `Future<List<Teacher>>` | GET | `/api/v1/teachers` |
| `getTeachersPage` | `({int page, int limit, String? search})` → `Future<PaginatedResponse<Teacher>>` | GET | `/api/v1/teachers` |
| `createTeacher` | `(Map<String, dynamic> body)` → `Future<Teacher>` | POST | `/api/v1/teachers` |
| `updateTeacher` | `(String id, Map<String, dynamic> body)` → `Future<Teacher>` | PUT | `/api/v1/teachers/$id` |
| `deleteTeacher` | `(String id)` → `Future<void>` | DELETE | `/api/v1/teachers/$id` |
| `getTeacherAssignments` | `(String id)` → `Future<List<TeacherAssignment>>` | GET | `/api/v1/teachers/$id/classes` |
| `setTeacherSubjects` | `(String teacherId, List<String> subjectIds)` → `Future<void>` | PUT | `/api/v1/teachers/$teacherId/subjects` |

### Subjects

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getSubjects` | `()` → `Future<List<Subject>>` | GET | `/api/v1/subjects` |
| `getSubjectsByClass` | `()` → `Future<List<ClassSubjects>>` | GET | `/api/v1/subjects/by-class` |
| `createSubject` | `(String name)` → `Future<Subject>` | POST | `/api/v1/subjects` |
| `assignSubjectToTeacher` | `(String subjectId, String teacherId, String classId)` → `Future<void>` | POST | `/api/v1/subjects/$subjectId/assign` |

### Classes

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getClasses` | `()` → `Future<List<ClassModel>>` | GET | `/api/v1/classes` |
| `getClassesPage` | `({int page, int limit, String? search})` → `Future<PaginatedResponse<ClassModel>>` | GET | `/api/v1/classes` |
| `createClass` | `(Map<String, dynamic> body)` → `Future<ClassModel>` | POST | `/api/v1/classes` |
| `updateClass` | `(String id, Map<String, dynamic> body)` → `Future<ClassModel>` | PUT | `/api/v1/classes/$id` |
| `deleteClass` | `(String id)` → `Future<void>` | DELETE | `/api/v1/classes/$id` |
| `getClassStudents` | `(String id)` → `Future<List<Student>>` | GET | `/api/v1/classes/$id/students` |

### Attendance

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getAttendance` | `(String classId, String date)` → `Future<List<AttendanceRecord>>` | GET | `/api/v1/attendance` |

### Exams & Grading

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getExams` | `()` → `Future<List<Exam>>` | GET | `/api/v1/exams` |
| `getExam` | `(String id)` → `Future<Exam>` | GET | `/api/v1/exams/$id` |
| `createExam` | `(Map<String, dynamic> body)` → `Future<Exam>` | POST | `/api/v1/exams` |
| `deleteExam` | `(String id)` → `Future<void>` | DELETE | `/api/v1/exams/$id` |
| `publishExam` | `(String id, bool isPublished)` → `Future<Exam>` | PATCH | `/api/v1/exams/$id/publish` |
| `getExamSubjects` | `(String examId)` → `Future<List<ExamSubject>>` | GET | `/api/v1/exams/$examId/subjects` |
| `getExamClasses` | `(String examId)` → `Future<List<ExamClass>>` | GET | `/api/v1/exams/$examId/classes` |
| `addExamSubject` | `(String examId, Map<String, dynamic> body)` → `Future<ExamSubject>` | POST | `/api/v1/exams/$examId/subjects` |
| `removeExamSubject` | `(String examId, String subjectId)` → `Future<void>` | DELETE | `/api/v1/exams/$examId/subjects/$subjectId` |
| `bulkSaveResults` | `(String examId, String subjectId, List<Map<String, dynamic>> marks)` → `Future<void>` | POST | `/api/v1/results/bulk` |
| `getGradingSystems` | `()` → `Future<List<GradingSystem>>` | GET | `/api/v1/grading` |
| `createGradingSystem` | `(Map<String, dynamic> body)` → `Future<GradingSystem>` | POST | `/api/v1/grading` |
| `updateGradingSystem` | `(String id, Map<String, dynamic> body)` → `Future<GradingSystem>` | PUT | `/api/v1/grading/$id` |
| `deleteGradingSystem` | `(String id)` → `Future<void>` | DELETE | `/api/v1/grading/$id` |

### Timetable

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getTeacherTimetable` | `(String teacherId, {String? date})` → `Future<List<TimetableEntry>>` | GET | `/api/v1/teachers/$teacherId/timetable` |
| `getClassTimetable` | `(String classId, {String? date})` → `Future<List<TimetableEntry>>` | GET | `/api/v1/classes/$classId/timetable` |
| `createTimetableEntry` | `(Map<String, dynamic> body)` → `Future<void>` | POST | `/api/v1/timetable` |
| `updateTimetableEntry` | `(String id, Map<String, dynamic> body)` → `Future<void>` | PUT | `/api/v1/timetable/$id` |
| `deleteTimetableEntry` | `(String id)` → `Future<void>` | DELETE | `/api/v1/timetable/$id` |

### Fees

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getFeeStructures` | `()` → `Future<List<FeeStructure>>` | GET | `/api/v1/fees/structures` |
| `createFeeStructure` | `(Map<String, dynamic> body)` → `Future<FeeStructure>` | POST | `/api/v1/fees/structures` |
| `getPendingFees` | `()` → `Future<List<FeePayment>>` | GET | `/api/v1/fees/pending` |
| `getUnpaidFees` | `({String? classId, String? paymentFilter, String? search})` → `Future<List<UnpaidFeeItem>>` | GET | `/api/v1/fees/unpaid` |
| `recordFeePayment` | `(Map<String, dynamic> body)` → `Future<void>` | POST | `/api/v1/fees/payments` |
| `createFeePost` | `(Map<String, dynamic> body)` → `Future<Map<String, dynamic>>` | POST | `/api/v1/fees/posts` |
| `getFeePosts` | `()` → `Future<List<FeePost>>` | GET | `/api/v1/fees/posts` |
| `getFeePost` | `(String id)` → `Future<FeePost>` | GET | `/api/v1/fees/posts/$id` |

### Announcements

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getAnnouncements` | `({String? classId})` → `Future<List<Announcement>>` | GET | `/api/v1/announcements` |
| `getAnnouncementsPage` | `({int page, int limit, String? search, String? classId})` → `Future<PaginatedResponse<Announcement>>` | GET | `/api/v1/announcements` |
| `createAnnouncement` | `(Map<String, dynamic> body)` → `Future<Announcement>` | POST | `/api/v1/announcements` |
| `updateAnnouncement` | `(String id, Map<String, dynamic> body)` → `Future<Announcement>` | PUT | `/api/v1/announcements/$id` |
| `deleteAnnouncement` | `(String id)` → `Future<void>` | DELETE | `/api/v1/announcements/$id` |

### Holidays

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getHolidays` | `({String? year, String? month})` → `Future<List<Holiday>>` | GET | `/api/v1/holidays` |
| `createHoliday` | `(Map<String, dynamic> body)` → `Future<Holiday>` | POST | `/api/v1/holidays` |
| `updateHoliday` | `(String id, Map<String, dynamic> body)` → `Future<Holiday>` | PUT | `/api/v1/holidays/$id` |
| `deleteHoliday` | `(String id)` → `Future<void>` | DELETE | `/api/v1/holidays/$id` |

### Reports & Downloads

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getReportJson` | `(String endpoint, {String? classId, String? startDate, String? endDate, String? groupBy})` → `Future<Map<String, dynamic>>` | GET | Dynamic |
| `downloadReport` | `(String endpoint, {String? classId, String? startDate, String? endDate, String? groupBy, required String format})` → `Future<List<int>>` | GET | Dynamic (60s timeout) |

### Proxies

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getAdminProxies` | `(String? date)` → `Future<List<ProxyAssignment>>` | GET | `/api/v1/proxy/admin/all` |
| `assignProxy` | `(String timetableId, String proxyTeacherId, String? reason, {String? date})` → `Future<ProxyAssignment>` | POST | `/api/v1/proxy/assign` |
| `getProxyTeachers` | `(String timetableId, {String? date})` → `Future<Map<String, dynamic>>` | GET | `/api/v1/proxy/teachers` |
| `cancelProxy` | `(String proxyId)` → `Future<void>` | DELETE | `/api/v1/proxy/$proxyId` |
| `getAvailableTeachers` | `(String timetableId)` → `Future<List<Map<String, dynamic>>>` | GET | `/api/v1/proxy/available` |

---

## Screens

| Screen | File | Route | Providers Watched | Key Features |
|--------|------|-------|-------------------|--------------|
| `AdminShell` | `admin_shell.dart` | ShellRoute wrapper | `connectivityProvider`, `sidebarCollapsedProvider` | Three-tier adaptive layout, sidebar nav (desktop), bottom nav (mobile), drawer (mobile), online/offline banner. Theme toggle lives in `sidebar_nav.dart` (watches `themeModeProvider`), not the shell itself. |
| `LoginScreen` | `login_screen.dart` | `/login` | `authStateProvider`, `connectivityProvider` | Email/password form, role validation, error display |
| `AdminDashboardScreen` | `admin_dashboard_screen.dart` | `/admin/dashboard` | `dashboardStatsProvider` | Stats overview grid, quick actions, recent activity |
| `AdminStudentsScreen` | `admin_students_screen.dart` | `/admin/students` | `studentsProvider` | Paginated list, search, create/edit/delete via form dialogs, activate/deactivate |
| `AdminTeachersScreen` | `admin_teachers_screen.dart` | `/admin/teachers` | `teachersProvider` | Paginated list, search, create/edit/delete, view assignments |
| `AdminClassesScreen` | `admin_classes_screen.dart` | `/admin/classes` | `classesProvider` | Paginated list, create/edit/delete, view class students |
| `AdminSubjectsScreen` | `admin_subjects_screen.dart` | `/admin/subjects` | `subjectsProvider`, `subjectsByClassProvider` | Subject list, group by class, assign to teacher |
| `AdminExamsScreen` | `admin_exams_screen.dart` | `/admin/exams` | `examsProvider` | Exam list, create/delete, publish toggle, navigate to mark entry |
| `AdminMarkEntryScreen` | `admin_mark_entry_screen.dart` | `/admin/mark-entry/:examId` | `markEntryExamSubjectsProvider`, `markEntryClassesForFilterProvider`, `markEntryClassStudentsProvider` | Select subject → class → enter marks for students, bulk save |
| `AdminGradingScreen` | `admin_grading_screen.dart` | `/admin/grading` | `gradingSystemsProvider` | CRUD grading systems with grade ranges |
| `AdminTimetableScreen` | `admin_timetable_screen.dart` | `/admin/timetable` | `selectedClassProvider`, `timetableEntriesProvider`, `timetableControllerProvider` | Matrix editor (days × periods), create/edit/delete entries |
| `AdminFeesScreen` | `admin_fees_screen.dart` | `/admin/fees` | `feePostsProvider`, `unpaidFeesProvider`, `unpaidFilterProvider` | Fee Posts tab + Pending Payments tab, record payments, export to Excel |
| `AdminAnnouncementsScreen` | `admin_announcements_screen.dart` | `/admin/announcements` | `announcementsProvider` | Paginated list, create/edit/delete, class-targeted or school-wide |
| `AdminAttendanceReportScreen` | `admin_attendance_report_screen.dart` | `/admin/attendance-report` | `attendanceReportClassesForFilterProvider`, `attendanceRecordsProvider` | Select class + date, view attendance grid |
| `AdminReportsScreen` | `admin_reports_screen.dart` | `/admin/reports` | `reportsClassesForFilterProvider`, `reportDataProvider` | Dashboard with 5 report types: student strength, attendance, fee collection, teacher workload, admissions. Excel download. |
| `AdminHolidaysScreen` | `admin_holidays_screen.dart` | `/admin/holidays` | `adminRepositoryProvider` | Holiday/event list, create/edit/delete, recurring toggle |
| `AdminPromotionScreen` | `admin_promotion_screen.dart` | `/admin/promotion` | `studentsProvider`, `classesProvider` | Select source class → target class, bulk promote students |
| `AdminStaffScreen` | `admin_staff_screen.dart` | `/admin/staff` | `staffProvider` | Paginated list, CRUD, department filter |
| `AdminSettingsScreen` | `admin_settings_screen.dart` | `/admin/settings` | `themeModeProvider`, `schoolProfileProvider` | Theme toggle (light/dark/system), school profile edit, change password |
| `AdminMoreScreen` | `admin_more_screen.dart` | `/admin/more` | — | Overflow menu for less-used screens |
| `AdminProxiesScreen` | `admin_proxies_screen.dart` | `/admin/proxies` | `adminRepositoryProvider` | View/assign/cancel proxy teachers |
| `StudentDetailScreen` | `student_detail_screen.dart` | — (push) | — | Full student profile view |
| `TeacherDetailScreen` | `teacher_detail_screen.dart` | — (push) | — | Full teacher profile + assignments view |

---

## Providers

### Auth (identical to all apps)

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `apiClientProvider` | `Provider<ApiClient>` | — | Creates `ApiClient` with secure client, disposes on cleanup |
| `authRepositoryProvider` | `Provider<AuthRepository>` | — | Wraps `apiClientProvider` |
| `authStateProvider` | `StateNotifierProvider<AuthStateNotifier, AuthState>` | `AuthState {status, user, errorMessage}` | Login/logout/auto-login with admin role check |

### Admin-Specific

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `adminRepositoryProvider` | `Provider<AdminRepository>` | — | Wraps `apiClientProvider` |
| `sidebarCollapsedProvider` | `StateProvider<bool>` | `bool` (default: `false`) | Sidebar collapse state |
| `selectedClassProvider` | `StateProvider<ClassModel?>` | `ClassModel?` | Selected class for timetable view |
| `timetableEntriesProvider` | `FutureProvider<List<TimetableEntry>>` | `List<TimetableEntry>` | Fetches timetable for selected class |
| `timetableControllerProvider` | `StateNotifierProvider<TimetableController, AsyncValue<void>>` | `AsyncValue<void>` | CRUD operations for timetable entries. Methods: `createEntry()`, `updateEntry()`, `deleteEntry()` |

### Screen Providers (defined inline in screen files)

Each screen that loads data defines its own `FutureProvider` or `StateNotifierProvider` inside its file or in the `providers/` directory. The admin app follows a pattern where most data-fetching providers are `FutureProvider` defined in the screen files themselves (e.g., `studentsProvider`, `teachersProvider`, etc.).

---

## Widgets

### Sidebar Navigation (`features/admin/presentation/widgets/sidebar_nav.dart`)

- Collapsible sidebar (toggles via `sidebarCollapsedProvider`)
- Supports both light and dark mode with different color schemes
- Contains theme toggle button (sun/moon icon)
- Flat navigation list: Dashboard, Students, Promotion, Holidays, Staff, Teachers, Classes, Attendance, Subjects, Exams, Grading, Timetable, Proxies, Reports, Fees, Announcements
- Footer holds the collapse toggle, theme toggle, Settings (`goNamed(RouteNames.adminSettings)`) and Logout
- Active route highlighting via `GoRouterState.matchedLocation`

### Dashboard Widgets

| Widget | File | Description |
|--------|------|-------------|
| `DashboardHeader` | `dashboard_header.dart` | Welcome text + school name |
| `StatsOverviewGrid` | `stats_overview_grid.dart` | Grid of stat cards (students, teachers, classes, attendance %) |
| `StatsPanel` | `stats_panel.dart` | Detailed stats display |
| `QuickActionsGrid` | `quick_actions_grid.dart` | Shortcut buttons to common actions |
| `RecentActivityFeed` | `recent_activity_feed.dart` | List of recent activities |
| `AnalyticsSection` | `analytics_section.dart` | Analytics display |

### Form Patterns

| Widget | File | Description |
|--------|------|-------------|
| `AdminFormDialog` | `admin_form_dialog.dart` | Desktop form dialog for CRUD operations |
| `AdminFormSheet` | `admin_form_sheet.dart` | Mobile bottom sheet form for CRUD operations |
| `DataTableWidget` | `data_table_widget.dart` | Reusable paginated data table |
| `TimetableFormSheet` | `timetable_form_sheet.dart` | Timetable entry create/edit form |
| `TimetableMatrixEditor` | `timetable_matrix_editor.dart` | Visual timetable matrix (days × periods) |

### Other

| Widget | File | Description |
|--------|------|-------------|
| `BackButtonHandler` | `back_button_handler.dart` | Hardware back button handling for Android/web |

---

## Step-by-Step Guides

### How to Add a New CRUD Entity (e.g., "Library Books")

1. **Add model** in `lib/features/admin/domain/admin_models.dart`:
   ```dart
   class LibraryBook {
     final String id;
     final String title;
     final String author;
     final bool isAvailable;

     LibraryBook({required this.id, required this.title, required this.author, this.isAvailable = true});

     factory LibraryBook.fromJson(Map<String, dynamic> json) => LibraryBook(
       id: json['id'] as String,
       title: json['title'] as String,
       author: json['author'] as String,
       isAvailable: json['is_available'] as bool? ?? true,
     );

     Map<String, dynamic> toCreateJson() => {'title': title, 'author': author};
     Map<String, dynamic> toUpdateJson() => {'title': title, 'author': author, 'is_available': isAvailable};
   }
   ```

2. **Add endpoints** in `lib/core/api/endpoints.dart`:
   ```dart
   static const String libraryBooks = '$apiPrefix/library/books';
   static String libraryBook(String id) => '$apiPrefix/library/books/$id';
   ```

3. **Add repository methods** in `lib/features/admin/data/admin_repository.dart`:
   ```dart
   Future<List<LibraryBook>> getLibraryBooks() async {
     final response = await _client.get(Endpoints.libraryBooks);
     final List data = json.decode(response.body);
     return data.map((e) => LibraryBook.fromJson(e)).toList();
   }
   Future<LibraryBook> createLibraryBook(Map<String, dynamic> body) async {
     final response = await _client.post(Endpoints.libraryBooks, body: body);
     return LibraryBook.fromJson(json.decode(response.body));
   }
   // ... update, delete methods
   ```

4. **Add screen** in `lib/features/admin/presentation/admin_library_screen.dart`:
   ```dart
   class AdminLibraryScreen extends ConsumerWidget { ... }
   ```
   Use `AdminFormDialog` (desktop) or `AdminFormSheet` (mobile) for create/edit forms.
   Use `DataTableWidget` for the list view.

5. **Add route** in `route_names.dart`:
   ```dart
   static const String adminLibrary = 'adminLibrary';
   ```
   And in `app_router.dart`:
   ```dart
   GoRoute(path: '/admin/library', name: RouteNames.adminLibrary, builder: (_, __) => const AdminLibraryScreen()),
   ```

6. **Add navigation** in `sidebar_nav.dart` — add a `NavigationDestination` in the appropriate section.

7. **Add provider** (optional, if state management is needed beyond FutureProvider):
   ```dart
   final libraryBooksProvider = FutureProvider.autoDispose<List<LibraryBook>>((ref) async {
     return ref.watch(adminRepositoryProvider).getLibraryBooks();
   });
   ```

### How to Add a New Screen to the Sidebar

1. Add route name in `route_names.dart`
2. Add `GoRoute` in `app_router.dart`
3. Create screen file in `presentation/`
4. Open `widgets/sidebar_nav.dart` and add to the appropriate section in the navigation list

### How to Modify Dashboard Stats

1. Edit `DashboardStats` model in `domain/admin_models.dart` to add/remove fields
2. Update the `fromJson` factory
3. Edit `getDashboardStats()` in `data/admin_repository.dart` if needed
4. Update `admin_dashboard_screen.dart` to display the new stats
5. Update dashboard widget files (`stats_overview_grid.dart`, `stats_panel.dart`, etc.)
