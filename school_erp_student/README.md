# School ERP Student Portal

Read-oriented student portal for viewing dashboard, attendance, results, timetable, fees, assignments, notices, holidays, remarks, and profile.

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
│   │   └── app_theme.dart
│   └── widgets/
│       ├── adaptive_layout.dart
│       ├── change_password_dialog.dart
│       ├── custom_button.dart
│       ├── dashboard_skeleton_loader.dart
│       ├── glass_card.dart
│       ├── list_skeleton_loader.dart
│       ├── loading_overlay.dart
│       ├── profile_skeleton_loader.dart
│       ├── shimmer.dart
│       └── skeleton_loader.dart
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── domain/user_model.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── providers/auth_state_provider.dart
│   └── student/
│       ├── data/student_repository.dart
│       ├── domain/student_models.dart
│       └── presentation/
│           ├── student_shell.dart
│           ├── student_dashboard_screen.dart
│           ├── student_attendance_screen.dart
│           ├── student_results_screen.dart
│           ├── student_timetable_screen.dart
│           ├── student_fees_screen.dart
│           ├── student_fee_post_detail_screen.dart
│           ├── student_assignments_screen.dart
│           ├── student_assignment_detail_screen.dart
│           ├── student_notices_screen.dart
│           ├── student_holidays_screen.dart
│           ├── student_remarks_screen.dart
│           ├── student_profile_screen.dart
│           ├── providers/
│           │   ├── student_repository_provider.dart
│           │   ├── student_attendance_provider.dart
│           │   ├── student_assignments_provider.dart
│           │   ├── student_dashboard_provider.dart
│           │   ├── student_fees_provider.dart
│           │   ├── student_notices_provider.dart
│           │   ├── student_profile_provider.dart
│           │   ├── student_remarks_provider.dart
│           │   ├── student_results_provider.dart
│           │   └── student_timetable_provider.dart
│           └── widgets/
│               ├── back_button_handler.dart
│               ├── student_bottom_nav.dart
│               └── student_sidebar_nav.dart
└── test/
    ├── widget_test.dart
    ├── helpers/
    │   └── fake_storage_service.dart
    └── features/
        └── auth/domain/user_model_test.dart
```

---

## Entry Points

### `main.dart`

Same flow as admin: `AppLogger.init()` → create `StorageService` → read `SENTRY_DSN` → optionally init Sentry → run `ProviderScope` with `storageServiceProvider` override → `SchoolErpStudentApp`.

### `app.dart`

```dart
class SchoolErpStudentApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (prev?.status == AuthStatus.authenticated &&
          next.status == AuthStatus.unauthenticated) {
        router.go('/login');
      }
    });

    return MaterialApp.router(
      title: 'School ERP Student',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,    // Student: follows OS setting only (no user toggle)
      routerConfig: router,
    );
  }
}
```

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

**Public methods:** `get`, `post`, `put`, `patch`, `delete`, `dispose` — same signatures as admin.

**Note:** Student app does **not** have the `download()` method (no file exports).

**401 handling:** On 401, calls `_tryRefreshToken()` which POSTs to `/api/v1/auth/refresh` with body `{'token': expiredToken}` **and** `Authorization: Bearer $token` header (differs from admin which omits the auth header on refresh). If refresh succeeds, retries once. If fails, clears storage and calls `onUnauthorized`.

### Endpoints (`core/api/endpoints.dart`)

**Base URL:** `https://renderbackned.onrender.com`
**API Prefix:** `/api/v1`

| Constant | Value |
|----------|-------|
| `login` | `/api/v1/auth/login` |
| `refresh` | `/api/v1/auth/refresh` |
| `changePassword` | `/api/v1/auth/change-password` |
| `assignments` | `/api/v1/assignments` |
| `holidays` | `/api/v1/holidays` |
| `timetable` | `/api/v1/timetable` |
| `notices` | `/api/v1/announcements` |
| `classes` | `/api/v1/classes` |
| `remarks` | `/api/v1/remarks` |

**Dynamic endpoint methods:**

| Method | Value |
|--------|-------|
| `studentProfile(id)` | `/api/v1/students/$id` |
| `studentAttendance(id)` | `/api/v1/attendance/student/$id` |
| `studentResults(id)` | `/api/v1/results/student/$id` |
| `studentFees(id)` | `/api/v1/fees/student/$id` |
| `assignment(id)` | `/api/v1/assignments/$id` |
| `notice(id)` | `/api/v1/announcements/$id` |
| `classById(id)` | `/api/v1/classes/$id` |
| `classTimetable(id)` | `/api/v1/classes/$id/timetable` |
| `studentRemarks(id)` | `/api/v1/remarks/student/$id` |
| `markRemarkRead(id)` | `/api/v1/remarks/$id/read` |

### Storage (`core/storage/`)

**Keys used:** `jwt_token`, `user_profile`, `theme_mode`.

**`StorageInterface` methods:** `saveToken`, `getToken`, `saveUser`, `getUser`, `saveThemeMode`, `getThemeMode`, `clear`.

### Router (`core/router/`)

**Route names** (`route_names.dart`):

| Constant | Value |
|----------|-------|
| `login` | `'login'` |
| `studentDashboard` | `'studentDashboard'` |
| `studentAttendance` | `'studentAttendance'` |
| `studentResults` | `'studentResults'` |
| `studentTimetable` | `'studentTimetable'` |
| `studentFees` | `'studentFees'` |
| `studentFeePostDetail` | `'studentFeePostDetail'` |
| `studentAssignments` | `'studentAssignments'` |
| `studentAssignmentDetail` | `'studentAssignmentDetail'` |
| `studentNotices` | `'studentNotices'` |
| `studentRemarks` | `'studentRemarks'` |
| `studentProfile` | `'studentProfile'` |
| `studentHolidays` | `'studentHolidays'` |

**Route paths** (`app_router.dart`):

| Path | Route Name | Screen |
|------|-----------|--------|
| `/login` | `login` | `LoginScreen` |
| `/student/dashboard` | `studentDashboard` | `StudentDashboardScreen` |
| `/student/attendance` | `studentAttendance` | `StudentAttendanceScreen` |
| `/student/results` | `studentResults` | `StudentResultsScreen` |
| `/student/timetable` | `studentTimetable` | `StudentTimetableScreen` |
| `/student/fees` | `studentFees` | `StudentFeesScreen` |
| `/student/fees/:id` | `studentFeePostDetail` | `StudentFeePostDetailScreen` |
| `/student/assignments` | `studentAssignments` | `StudentAssignmentsScreen` |
| `/student/assignments/:id` | `studentAssignmentDetail` | `StudentAssignmentDetailScreen` |
| `/student/notices` | `studentNotices` | `StudentNoticesScreen` |
| `/student/holidays` | `studentHolidays` | `StudentHolidaysScreen` |
| `/student/remarks` | `studentRemarks` | `StudentRemarksScreen` |
| `/student/profile` | `studentProfile` | `StudentProfileScreen` |

**Auth redirect:** No token + not on `/login` → redirect to `/login`. Token + on `/login` → redirect to `/student/dashboard`.

**Page transitions:** Default (no custom transitions, unlike admin's fade).

### Theme (`core/theme/`)

Identical to admin except:
- **No** `theme_mode_provider.dart` — student app uses `ThemeMode.system` only
- **No** additional color tokens — uses the base 16-color palette from the root README

### Responsive Layout (`core/widgets/adaptive_layout.dart`)

Two-tier only: `mobile` (< 800px) and `desktop` (>= 800px). No `tablet` tier, no `ResponsiveContext` extension.

### Shared Widgets

Same set as admin minus `ErrorRetryWidget` (student uses `Shimmer` + `ListSkeletonLoader` instead).

Additional student-only widgets:
- `DashboardSkeletonLoader` — skeleton for dashboard layout
- `ProfileSkeletonLoader` — skeleton for profile page

---

## Auth Feature

### UserModel

Identical fields to admin. Getter: `bool get isStudent => role == 'student';`

### AuthRepository

| Method | Parameters | Return | Endpoint | HTTP |
|--------|-----------|--------|----------|------|
| `login(email, password)` | `String, String` | `Future<UserModel>` | `POST /api/v1/auth/login` | POST |
| `changePassword(oldPw, newPw)` | `String, String` | `Future<void>` | `POST /api/v1/auth/change-password` | POST |

**Note:** Student's `AuthRepository` does **not** wrap methods in try/catch → `ApiException` (simpler than admin's version).

### AuthStateNotifier

Same as admin but role check is `user.isStudent`. Rejects non-student credentials with "Access denied. Student credentials required."

### LoginScreen

Same structure as admin: email/password form, connectivity banner, error display, loading state. On success: `context.go('/student/dashboard')`.

---

## Domain Models

All in `features/student/domain/student_models.dart`. This app is **read-only** — no `toCreateJson`/`toUpdateJson` methods.

### StudentProfile

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `userId` | `String` | `user_id` | yes |
| `fullName` | `String` | `full_name` | yes |
| `email` | `String?` | `email` | no |
| `rollNumber` | `String?` | `roll_number` | no |
| `classId` | `String?` | `class_id` | no |
| `className` | `String?` | `class_name` | no |
| `classSection` | `String?` | `class_section` | no |
| `parentName` | `String?` | `parent_name` | no |
| `parentPhone` | `String?` | `parent_phone` | no |
| `isActive` | `bool` | `is_active` | yes (default: `true`) |

### AttendanceSummary

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `month` | `String` | `month` | yes (default: `''`) |
| `total` | `int` | `total` | yes (default: `0`) |
| `present` | `int` | `present` | yes (default: `0`) |
| `absent` | `int` | `absent` | yes (default: `0`) |
| `percentage` | `double` | `percentage` | yes (default: `0.0`) |

### AttendanceRecord

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `date` | `String` | `date` | yes |
| `status` | `String` | `status` | yes |
| `subjectName` | `String?` | `subject_name` | no |

### ResultEntry

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes (default: `''`) |
| `examName` | `String` | `exam_name` | yes (default: `''`) |
| `subjectName` | `String` | `subject_name` | yes (default: `''`) |
| `marksObtained` | `double` | `marks_obtained` | yes (default: `0`) |
| `totalMarks` | `double` | `total_marks` | yes (default: `0`) |
| `percentage` | `double` | `percentage` | yes (default: `0`) |
| `grade` | `String?` | `grade` | no |
| `passed` | `bool` | `passed` | yes (default: `false`) |

### TimetableEntry

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `subjectName` | `String` | `subject_name` | yes | `''` |
| `teacherName` | `String?` | `teacher_name` | no | — |
| `day` | `String` | `day` | yes | — |
| `startTime` | `String` | `start_time` | yes | — |
| `endTime` | `String` | `end_time` | yes | — |
| `room` | `String?` | `room` | no | — |
| `proxyTeacherId` | `String?` | `proxy_teacher_id` | no | — |
| `originalTeacherId` | `String?` | `original_teacher_id` | no | — |
| `hasProxy` | `bool` | `has_proxy` | no | `false` |

### FeeDetail

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes (default: `''`) |
| `feeType` | `String` | `fee_type` | yes (default: `''`) |
| `amount` | `double` | `amount` | yes (default: `0`) |
| `dueDate` | `String?` | `due_date` | no |
| `paid` | `bool` | `paid` | yes (default: `false`) |
| `paidDate` | `String?` | `paid_date` | no |

### FeePayment

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes (default: `''`) |
| `amount` | `double` | `amount` | yes (default: `0`) |
| `paymentDate` | `String` | `payment_date` | yes (default: `''`) |
| `paymentMethod` | `String?` | `payment_method` | no |
| `transactionId` | `String?` | `transaction_id` | no |

### FeePost

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String?` | `id` | no | — |
| `title` | `String` | `title` | yes | `'Other Fees'` |
| `description` | `String?` | `description` | no | — |
| `dueDate` | `String?` | `due_date` | no | — |
| `structures` | `List<FeeDetail>` | `structures` | no | `[]` |

**Computed properties:**
- `totalAmount` → `structures.fold(0.0, (sum, s) => sum + s.amount)`
- `totalPaid` → sum of amounts where `s.paid == true`
- `totalPending` → sum of amounts where `s.paid == false`

### Assignment

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | `''` |
| `title` | `String` | `title` | yes | `''` |
| `description` | `String?` | `description` | no | — |
| `subjectName` | `String` | `subject_name` | yes | `''` |
| `dueDate` | `String?` | `due_date` | no | — |
| `status` | `String` | `status` | yes | `'pending'` |
| `grade` | `String?` | `grade` | no | — |
| `submissionStatus` | `String?` | `submission_status` | no | — |
| `teacherRemarks` | `String?` | `teacher_remarks` | no | — |
| `submissionUpdatedAt` | `String?` | `submission_updated_at` | no | — |

### Notice

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `title` | `String` | `title` | yes |
| `body` | `String?` | `body` | no |
| `createdAt` | `String` | `created_at` | yes |
| `createdByEmail` | `String?` | `created_by_email` | no |
| `isSchoolWide` | `bool` | — | yes (derived: `json['class_id'] == null`) |

### StudentRemark

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `teacherName` | `String?` | `teacher_name` | no | — |
| `type` | `String` | `type` | yes | `'praise'` |
| `category` | `String?` | `category` | no | — |
| `message` | `String` | `message` | yes | `''` |
| `isRead` | `bool` | `is_read` | yes | `false` |
| `createdAt` | `String` | `created_at` | yes | `''` |

### DashboardData

| Field | Type | Required |
|-------|------|----------|
| `studentName` | `String` | yes |
| `attendanceSummary` | `AttendanceSummary?` | no |
| `recentNotices` | `List<Notice>` | no (default: `[]`) |

**Note:** No `fromJson` factory — constructed programmatically by `studentDashboardProvider`.

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

---

## Repository Methods

All in `features/student/data/student_repository.dart` (10 methods total).

| # | Method | Signature | HTTP | Endpoint |
|---|--------|-----------|------|----------|
| 1 | `getProfile` | `(String studentId)` → `Future<StudentProfile>` | GET | `/api/v1/students/$studentId` |
| 2 | `getAttendance` | `(String studentId)` → `Future<List<AttendanceRecord>>` | GET | `/api/v1/attendance/student/$studentId` |
| 3 | `getResults` | `(String studentId)` → `Future<List<ResultEntry>>` | GET | `/api/v1/results/student/$studentId` |
| 4 | `getFees` | `(String studentId)` → `Future<Map<String, dynamic>>` | GET | `/api/v1/fees/student/$studentId` |
| 5 | `getAssignments` | `()` → `Future<List<Assignment>>` | GET | `/api/v1/assignments` |
| 6 | `getNotices` | `()` → `Future<List<Notice>>` | GET | `/api/v1/announcements` |
| 7 | `getTimetable` | `(String classId, {String? date})` → `Future<List<TimetableEntry>>` | GET | `/api/v1/classes/$classId/timetable` |
| 8 | `getRemarks` | `(String studentId)` → `Future<List<StudentRemark>>` | GET | `/api/v1/remarks/student/$studentId` |
| 9 | `markRemarkRead` | `(String remarkId)` → `Future<void>` | PATCH | `/api/v1/remarks/$remarkId/read` |
| 10 | `getHolidays` | `()` → `Future<List<Holiday>>` | GET | `/api/v1/holidays` |

---

## Screens

| Screen | File | Route | Providers Watched | Key Features |
|--------|------|-------|-------------------|--------------|
| `StudentShell` | `student_shell.dart` | ShellRoute wrapper | `connectivityProvider` | Two-tier layout (800px breakpoint). Desktop: sidebar. Mobile: bottom nav. Online/offline banner. |
| `LoginScreen` | `login_screen.dart` | `/login` | `authStateProvider`, `connectivityProvider` | Email/password form, student role validation |
| `StudentDashboardScreen` | `student_dashboard_screen.dart` | `/student/dashboard` | `studentDashboardProvider` | Greeting, attendance summary card, recent notices list, quick links |
| `StudentAttendanceScreen` | `student_attendance_screen.dart` | `/student/attendance` | `attendancePageProvider`, `attendanceOverviewProvider` | Monthly summary + detailed attendance records, calendar-style display |
| `StudentResultsScreen` | `student_results_screen.dart` | `/student/results` | `studentResultsProvider` | Exam results grouped by exam, marks/grade display |
| `StudentTimetableScreen` | `student_timetable_screen.dart` | `/student/timetable` | `studentTimetableProvider` | Weekly timetable grid, proxy teacher indicators |
| `StudentFeesScreen` | `student_fees_screen.dart` | `/student/fees` | `studentFeesProvider` | Fee posts with paid/pending breakdown, total paid/pending amounts, navigate to detail |
| `StudentFeePostDetailScreen` | `student_fee_post_detail_screen.dart` | `/student/fees/:id` | — | Individual fee post detail with structure breakdown |
| `StudentAssignmentsScreen` | `student_assignments_screen.dart` | `/student/assignments` | `studentAssignmentsProvider` | Assignment list with status badges, navigate to detail |
| `StudentAssignmentDetailScreen` | `student_assignment_detail_screen.dart` | `/student/assignments/:id` | — | Assignment detail with description, submission status, grade |
| `StudentNoticesScreen` | `student_notices_screen.dart` | `/student/notices` | `studentNoticesProvider` | Notice list, school-wide vs class-specific indicators |
| `StudentHolidaysScreen` | `student_holidays_screen.dart` | `/student/holidays` | `studentHolidaysProvider` | Holiday/event list with type badges |
| `StudentRemarksScreen` | `student_remarks_screen.dart` | `/student/remarks` | `studentRemarksProvider` | Teacher remarks list, mark-as-read, praise/warning/category filters |
| `StudentProfileScreen` | `student_profile_screen.dart` | `/student/profile` | `studentProfileProvider` | Profile info display (name, email, class, roll number, parent info), change password |

---

## Providers

### Auth (same as all apps)

| Provider | Type | State |
|----------|------|-------|
| `apiClientProvider` | `Provider<ApiClient>` | — |
| `authRepositoryProvider` | `Provider<AuthRepository>` | — |
| `authStateProvider` | `StateNotifierProvider<AuthStateNotifier, AuthState>` | `AuthState` |

### Repository

| Provider | Type | Description |
|----------|------|-------------|
| `studentRepositoryProvider` | `Provider<StudentRepository>` | Wraps `apiClientProvider` |

### Dashboard

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentDashboardProvider` | `FutureProvider<DashboardData>` | `DashboardData` | Fetches profile (for name), attendance summary, and top 3 notices. Each fetch wrapped in try/catch with fallback defaults. |

### Attendance

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `attendanceOverviewProvider` | `FutureProvider<AttendanceSummary>` | `AttendanceSummary` | Computes monthly totals + percentage from attendance records |
| `attendancePageProvider` | `StateNotifierProvider<AttendancePageNotifier, AttendancePageState>` | `AttendancePageState {records, isLoading, errorMessage}` | Loads attendance records for display. Method: `loadAttendance(studentId)` |

### Assignments

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentAssignmentsProvider` | `FutureProvider.autoDispose<List<Assignment>>` | `List<Assignment>` | Fetches all assignments via `repo.getAssignments()` |

### Fees

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentFeesProvider` | `FutureProvider.autoDispose<FeesData>` | `FeesData {posts, payments, totalPaid, totalPending}` | Fetches raw fees map, parses posts + payments, computes totals |

### Notices

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentNoticesProvider` | `FutureProvider.autoDispose<List<Notice>>` | `List<Notice>` | Fetches notices via `repo.getNotices()` |

### Profile

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentProfileProvider` | `FutureProvider.autoDispose<StudentProfile>` | `StudentProfile` | Watches `authStateProvider` for `studentId`, fetches profile |

### Remarks

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentRemarksProvider` | `StateNotifierProvider<RemarksStateNotifier, RemarksState>` | `RemarksState {remarks, isLoading, errorMessage}` | Loads remarks, `markAsRead(remarkId)`, `refresh()` |

### Results

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentResultsProvider` | `FutureProvider.autoDispose<List<ResultEntry>>` | `List<ResultEntry>` | Watches `authStateProvider` for `studentId`, fetches results |

### Timetable

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `studentTimetableProvider` | `FutureProvider.autoDispose<List<TimetableEntry>>` | `List<TimetableEntry>` | Gets `classId` from profile, fetches today's timetable |

---

## Widgets

### Sidebar Navigation (`widgets/student_sidebar_nav.dart`)

Fixed-width dark sidebar (260px). Navigation items: Dashboard, Attendance, Results, Timetable, Fees, Assignments, Notices, Holidays, Remarks, Profile. Active route highlighting via `GoRouterState.matchedLocation`.

### Bottom Navigation (`widgets/student_bottom_nav.dart`)

Mobile bottom `NavigationBar` with 5 items: Dashboard, Attendance, Timetable, Notices, Profile. Additional items accessible via "More" overflow.

### Back Button Handler (`widgets/back_button_handler.dart`)

Handles hardware back button on Android — pops navigation stack or shows exit confirmation.

---

## Step-by-Step Guides

### How to Add a New Read-Only Screen

1. **Create screen** in `lib/features/student/presentation/`:
   ```dart
   class StudentMyScreen extends ConsumerWidget {
     const StudentMyScreen({super.key});
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final data = ref.watch(myDataProvider);
       return data.when(
         loading: () => const SkeletonLoader(),
         error: (e, _) => Text('Error: $e'),
         data: (items) => ListView(...),
       );
     }
   }
   ```

2. **Add endpoint** in `core/api/endpoints.dart`:
   ```dart
   static const String myResource = '$apiPrefix/my-resource';
   ```

3. **Add repository method** in `data/student_repository.dart`:
   ```dart
   Future<List<MyItem>> getMyItems() async {
     final response = await _client.get(Endpoints.myResource);
     return (json.decode(response.body) as List).map((e) => MyItem.fromJson(e)).toList();
   }
   ```

4. **Add model** (if new) in `domain/student_models.dart`:
   ```dart
   class MyItem {
     final String id;
     final String name;
     MyItem({required this.id, required this.name});
     factory MyItem.fromJson(Map<String, dynamic> json) => MyItem(id: json['id'], name: json['name']);
   }
   ```

5. **Add provider** in `providers/`:
   ```dart
   final myDataProvider = FutureProvider.autoDispose<List<MyItem>>((ref) async {
     return ref.watch(studentRepositoryProvider).getMyItems();
   });
   ```

6. **Add route name** in `core/router/route_names.dart`:
   ```dart
   static const String studentMyScreen = 'studentMyScreen';
   ```

7. **Add GoRoute** in `core/router/app_router.dart` inside the `ShellRoute`.

8. **Add navigation** in `student_shell.dart` — add to sidebar nav (desktop) and bottom nav (mobile).

### How to Modify the Dashboard

1. Edit the `DashboardData` model in `domain/student_models.dart` to add fields
2. Update `studentDashboardProvider` in `providers/student_dashboard_provider.dart` to fetch the new data
3. Edit `student_dashboard_screen.dart` to display it

### How to Add a New Provider

**For simple data fetch:**
```dart
final myProvider = FutureProvider.autoDispose<T>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getData();
});
```

**For interactive state:**
```dart
class MyState {
  final List<Item> items;
  final bool isLoading;
  final String? error;
  MyState({this.items = const [], this.isLoading = false, this.error});
  MyState copyWith({List<Item>? items, bool? isLoading, String? error}) =>
    MyState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading, error: error);
}

class MyNotifier extends StateNotifier<MyState> {
  final StudentRepository _repo;
  MyNotifier(this._repo) : super(MyState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.getData();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref.watch(studentRepositoryProvider));
});
```
