# School ERP Teacher Portal

Functional teacher portal for marking attendance, entering marks, managing assignments + submissions, creating announcements, writing student remarks, managing proxies, and viewing timetable.

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
│   └── teacher/
│       ├── data/teacher_repository.dart
│       ├── domain/teacher_models.dart
│       └── presentation/
│           ├── teacher_shell.dart
│           ├── teacher_dashboard_screen.dart
│           ├── teacher_attendance_screen.dart
│           ├── teacher_marks_screen.dart
│           ├── teacher_timetable_screen.dart
│           ├── teacher_announcements_screen.dart
│           ├── teacher_assignments_screen.dart
│           ├── teacher_assignment_detail_screen.dart
│           ├── teacher_notices_screen.dart
│           ├── teacher_holidays_screen.dart
│           ├── teacher_remarks_screen.dart
│           ├── teacher_profile_screen_screen.dart
│           ├── providers/
│           │   ├── teacher_attendance_provider.dart
│           │   ├── teacher_assignments_provider.dart
│           │   ├── teacher_marks_provider.dart
│           │   ├── teacher_notices_provider.dart
│           │   ├── teacher_proxy_provider.dart
│           │   └── teacher_remarks_provider.dart
│           └── widgets/
│               ├── back_button_handler.dart
│               ├── teacher_bottom_nav.dart
│               └── teacher_sidebar_nav.dart
└── test/
    ├── widget_test.dart
    ├── helpers/
    │   └── fake_storage_service.dart
    ├── core/api/
    │   └── api_client_test.dart
    └── features/
        └── auth/domain/user_model_test.dart
```

---

## Entry Points

### `main.dart`

Same flow as admin/student: `AppLogger.init()` → create `StorageService` → read `SENTRY_DSN` → optionally init Sentry → run `ProviderScope` with `storageServiceProvider` override → `SchoolErpTeacherApp`.

### `app.dart`

```dart
class SchoolErpTeacherApp extends ConsumerWidget {
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
      title: 'School ERP Teacher',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,    // Teacher: follows OS setting only
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
| Default timeout | **15 seconds** (shorter than admin/student) |
| Refresh timeout | **10 seconds** (shorter than admin/student) |
| Max retries | 3 |
| Retry on | 502, 503, 504, 429 |
| Backoff | `pow(2, retry) * 1000ms + random(0-500ms)` jitter |

**Public methods:** `get`, `post`, `put`, `patch`, `delete`, `dispose` — same signatures as admin. No `download()` method.

**401 handling:** Same as student — POST to `/api/v1/auth/refresh` with body `{'token': expiredToken}` **and** `Authorization: Bearer $token` header.

### Endpoints (`core/api/endpoints.dart`)

**Base URL:** `https://renderbackned.onrender.com`
**API Prefix:** `/api/v1`

| Constant | Value |
|----------|-------|
| `login` | `/api/v1/auth/login` |
| `refresh` | `/api/v1/auth/refresh` |
| `changePassword` | `/api/v1/auth/change-password` |
| `classes` | `/api/v1/classes` |
| `subjects` | `/api/v1/subjects` |
| `exams` | `/api/v1/exams` |
| `announcements` | `/api/v1/announcements` |
| `assignments` | `/api/v1/assignments` |
| `holidays` | `/api/v1/holidays` |
| `timetable` | `/api/v1/timetable` |
| `attendance` | `/api/v1/attendance` |
| `attendanceMark` | `/api/v1/attendance/mark` |
| `marksBulk` | `/api/v1/results/bulk` |
| `results` | `/api/v1/results` |
| `proxyAssign` | `/api/v1/proxy/assign` |
| `proxyMy` | `/api/v1/proxy/my` |
| `proxyPending` | `/api/v1/proxy/pending` |
| `remarks` | `/api/v1/remarks` |

**Dynamic endpoint methods:**

| Method | Value |
|--------|-------|
| `classById(id)` | `/api/v1/classes/$id` |
| `classStudents(id)` | `/api/v1/classes/$id/students` |
| `classTimetable(id)` | `/api/v1/classes/$id/timetable` |
| `teacherClasses(id)` | `/api/v1/teachers/$id/classes` |
| `teacherClassTeacherClass(id)` | `/api/v1/teachers/$id/class-teacher-class` |
| `teacherProfile(id)` | `/api/v1/teachers/$id` |
| `teacherTimetable(id)` | `/api/v1/teachers/$id/timetable` |
| `attendanceRecord(id)` | `/api/v1/attendance/$id` |
| `studentAttendance(id)` | `/api/v1/attendance/student/$id` |
| `resultsByExam(examId, subjectId, {classId?})` | `/api/v1/results?examId=$examId&subjectId=$subjectId[&classId=$classId]` |
| `announcement(id)` | `/api/v1/announcements/$id` |
| `teacherAnnouncements(id)` | `/api/v1/announcements/teacher/$id` |
| `assignment(id)` | `/api/v1/assignments/$id` |
| `assignmentSubmissions(id)` | `/api/v1/assignments/$id/submissions` |
| `timetableEntry(id)` | `/api/v1/timetable/$id` |
| `proxyRespond(id)` | `/api/v1/proxy/$id/respond` |
| `proxyCancel(id)` | `/api/v1/proxy/$id` |
| `proxyTodayForClass(classId)` | `/api/v1/proxy/today?classId=$classId` |
| `proxyAvailable(timetableId, {date?})` | `/api/v1/proxy/available?timetableId=$timetableId[&date=$date]` |
| `teacherRemarks(id)` | `/api/v1/remarks/teacher/$id` |
| `teacherRemarksForStudent(teacherId, studentId)` | `/api/v1/remarks/teacher/$teacherId/student/$studentId` |
| `remark(id)` | `/api/v1/remarks/$id` |

### Storage (`core/storage/`)

Same as student/admin.

### Router (`core/router/`)

**Route names** (`route_names.dart`):

| Constant | Value |
|----------|-------|
| `login` | `'login'` |
| `teacherDashboard` | `'teacherDashboard'` |
| `teacherAttendance` | `'teacherAttendance'` |
| `teacherMarks` | `'teacherMarks'` |
| `teacherTimetable` | `'teacherTimetable'` |
| `teacherAnnouncements` | `'teacherAnnouncements'` |
| `teacherAssignments` | `'teacherAssignments'` |
| `teacherAssignmentDetail` | `'teacherAssignmentDetail'` |
| `teacherNotices` | `'teacherNotices'` |
| `teacherRemarks` | `'teacherRemarks'` |
| `teacherProfile` | `'teacherProfile'` |
| `teacherHolidays` | `'teacherHolidays'` |

**Route paths** (`app_router.dart`):

| Path | Route Name | Screen |
|------|-----------|--------|
| `/login` | `login` | `LoginScreen` |
| `/teacher/dashboard` | `teacherDashboard` | `TeacherDashboardScreen` |
| `/teacher/attendance` | `teacherAttendance` | `TeacherAttendanceScreen` |
| `/teacher/marks` | `teacherMarks` | `TeacherMarksScreen` |
| `/teacher/timetable` | `teacherTimetable` | `TeacherTimetableScreen` |
| `/teacher/announcements` | `teacherAnnouncements` | `TeacherAnnouncementsScreen` |
| `/teacher/notices` | `teacherNotices` | `TeacherNoticesScreen` |
| `/teacher/holidays` | `teacherHolidays` | `TeacherHolidaysScreen` |
| `/teacher/assignments` | `teacherAssignments` | `TeacherAssignmentsScreen` |
| `/teacher/assignments/:id` | `teacherAssignmentDetail` | `TeacherAssignmentDetailScreen` |
| `/teacher/remarks` | `teacherRemarks` | `TeacherRemarksScreen` |
| `/teacher/profile` | `teacherProfile` | `TeacherProfileScreen` |

**Auth redirect:** No token + not on `/login` → redirect to `/login`. Token + on `/login` → redirect to `/teacher/dashboard`.

**Page transitions:** Default (no custom transitions).

### Theme (`core/theme/`)

Identical to student — base color palette, `ThemeMode.system` only, no additional tokens.

### Responsive Layout (`core/widgets/adaptive_layout.dart`)

Two-tier: `mobile` (< 800px) and `desktop` (>= 800px). Same as student.

### Shared Widgets

Same set as student: `GlassCard`, `CustomButton`, `LoadingOverlay`, `SkeletonLoader`, `Shimmer`, `ListSkeletonLoader`, `ChangePasswordDialog`, `DashboardSkeletonLoader`, `ProfileSkeletonLoader`.

---

## Auth Feature

### UserModel

Identical fields to admin/student. Getter: `bool get isTeacher => role == 'teacher';`

### AuthRepository

| Method | Parameters | Return | Endpoint | HTTP |
|--------|-----------|--------|----------|------|
| `login(email, password)` | `String, String` | `Future<UserModel>` | `POST /api/v1/auth/login` | POST |
| `changePassword(oldPw, newPw)` | `String, String` | `Future<void>` | `POST /api/v1/auth/change-password` | POST |

Same as student — no try/catch wrapping.

### AuthStateNotifier

Same structure but role check is `user.isTeacher`. Rejects non-teacher credentials with "Access denied. Teacher credentials required."

### LoginScreen

Same as student/admin. On success: `context.go('/teacher/dashboard')`.

---

## Domain Models

All in `features/teacher/domain/teacher_models.dart`.

### TeacherClass

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `classId` | `String` | `class_id` | yes |
| `className` | `String` | `class_name` | yes |
| `section` | `String` | `section` | yes |
| `subjectId` | `String` | `subject_id` | yes |
| `subjectName` | `String` | `subject_name` | yes |
| `classTeacherId` | `String?` | `class_teacher_id` | no |

**Computed:** `display` — `'$className - $section'`.

**Equality:** `operator ==` and `hashCode` based on `(classId, subjectId)`.

### ClassModel

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `name` | `String` | `name` | yes |
| `section` | `String` | `section` | yes |
| `classTeacherId` | `String?` | `class_teacher_id` | no |
| `classTeacherName` | `String?` | `class_teacher_name` | no |
| `studentCount` | `int` | `student_count` | yes |

**Computed:** `display` — `'$name - $section'`. Static `_parseInt()` helper for safe int parsing.

### Student

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `userId` | `String` | `user_id` | yes |
| `fullName` | `String` | `full_name` | yes |
| `classId` | `String?` | `class_id` | no |
| `rollNumber` | `String?` | `roll_number` | no |
| `email` | `String?` | `email` | no |
| `className` | `String?` | `class_name` | no |
| `classSection` | `String?` | `class_section` | no |
| `isActive` | `bool` | `is_active` | yes (default: `true`) |

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

### Exam

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `name` | `String` | `name` | yes | — |
| `examDate` | `String?` | `exam_date` | no | — |
| `isPublished` | `bool` | `is_published` | no | `false` |

**Equality:** Based on `id`.

### Subject

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `name` | `String` | `name` | yes |

**Equality:** Based on `id`.

### TimetableEntry

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `classId` | `String` | `class_id` | yes | — |
| `subjectId` | `String` | `subject_id` | yes | — |
| `subjectName` | `String?` | `subject_name` | no | — |
| `teacherName` | `String?` | `teacher_name` | no | — |
| `day` | `String` | `day` | yes | — |
| `startTime` | `String` | `start_time` | yes | — |
| `endTime` | `String` | `end_time` | yes | — |
| `room` | `String?` | `room` | no | — |
| `className` | `String?` | `class_name` | no | — |
| `classSection` | `String?` | `class_section` | no | — |
| `proxyTeacherId` | `String?` | `proxy_teacher_id` | no | — |
| `originalTeacherId` | `String?` | `original_teacher_id` | no | — |
| `hasProxy` | `bool` | `has_proxy` | no | `false` |

**Computed:** `classDisplay` — `'$className - $classSection'` with null/empty checks.

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

**Computed:** `isSchoolWide` — `classId == null`.

### TeacherProfile

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes |
| `userId` | `String` | `user_id` | yes |
| `fullName` | `String` | `full_name` | yes |
| `phone` | `String?` | `phone` | no |
| `isActive` | `bool` | `is_active` | yes (default: `true`) |
| `email` | `String?` | `email` | no |

### DashboardData

| Field | Type | Required |
|-------|------|----------|
| `teacherName` | `String` | yes |
| `assignedClasses` | `List<TeacherClass>` | yes |
| `todaySchedule` | `List<TimetableEntry>` | yes |
| `classTeacherClass` | `ClassModel?` | no |

**Note:** No `fromJson` — constructed programmatically.

### Assignment

| Field | Type | JSON Key | Required |
|-------|------|----------|----------|
| `id` | `String` | `id` | yes (default: `''`) |
| `title` | `String` | `title` | yes (default: `''`) |
| `description` | `String?` | `description` | no |
| `subjectName` | `String` | `subject_name` | yes (default: `''`) |
| `className` | `String` | `class_name` | yes (default: `''`) |
| `section` | `String` | `section` | yes (default: `''`) |
| `dueDate` | `String?` | `due_date` | no |
| `createdAt` | `String` | `created_at` | yes (default: `''`) |

**Computed:** `classDisplay` — `'$className - $section'`.

### AssignmentSubmission

| Field | Type | JSON Key | Required | Mutable | Default |
|-------|------|----------|----------|---------|---------|
| `id` | `String` | `id` | yes | no | — |
| `studentId` | `String` | `student_id` | yes | no | — |
| `studentName` | `String` | `student_name` | yes | no | — |
| `rollNumber` | `String?` | `roll_number` | no | no | — |
| `status` | `String` | `status` | no | **yes** | `'pending'` |
| `remarks` | `String?` | `remarks` | no | **yes** | — |

**Note:** `status` and `remarks` are **mutable** — the teacher modifies these locally before bulk-saving.

### StudentRemark

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `studentId` | `String` | `student_id` | yes | — |
| `studentName` | `String?` | `student_name` | no | — |
| `teacherId` | `String?` | `teacher_id` | no | — |
| `type` | `String` | `type` | yes | `'praise'` |
| `category` | `String?` | `category` | no | — |
| `message` | `String` | `message` | yes | `''` |
| `isRead` | `bool` | `is_read` | yes | `false` |
| `createdAt` | `String` | `created_at` | yes | `''` |

### MarkEntry

| Field | Type | Required | Mutable | Default |
|-------|------|----------|---------|---------|
| `studentId` | `String` | yes | no | — |
| `studentName` | `String` | yes | no | — |
| `rollNumber` | `String?` | no | no | — |
| `marksObtained` | `double` | no | **yes** | `0` |
| `totalMarks` | `double` | no | **yes** | `100` |

**Note:** No `fromJson` — constructed locally from student data. Mutable fields for teacher input.

### Holiday

Same as admin/student.

| Field | Type | JSON Key | Required | Default |
|-------|------|----------|----------|---------|
| `id` | `String` | `id` | yes | — |
| `title` | `String` | `title` | yes | — |
| `description` | `String?` | `description` | no | — |
| `date` | `String` | `date` | yes | — |
| `type` | `String` | `type` | no | `'holiday'` |
| `isRecurring` | `bool` | `is_recurring` | no | `false` |

**Computed:** `isHoliday`, `displayType`.

### ProxyAssignment

Same as admin. 19 fields. See admin README for full field list.

**Computed:** `classDisplay`, `dayLabel`, `statusLabel`, `isPending`, `isAccepted`, `isRejected`, `isCancelled`.

---

## Repository Methods

All in `features/teacher/data/teacher_repository.dart` (32 methods total).

### Classes & Students

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getTeacherClasses` | `(String teacherId)` → `Future<List<TeacherClass>>` | GET | `/api/v1/teachers/$teacherId/classes` |
| `getClasses` | `()` → `Future<List<ClassModel>>` | GET | `/api/v1/classes` |
| `getClassStudents` | `(String classId)` → `Future<List<Student>>` | GET | `/api/v1/classes/$classId/students` |
| `getClassTeacherClass` | `(String teacherId)` → `Future<ClassModel?>` | GET | `/api/v1/teachers/$teacherId/class-teacher-class` |

### Attendance

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `markAttendance` | `(String classId, String date, List<Map<String, dynamic>> records)` → `Future<void>` | POST | `/api/v1/attendance/mark` |
| `getAttendance` | `(String classId, String date)` → `Future<List<AttendanceRecord>>` | GET | `/api/v1/attendance` |

**`markAttendance` body format:**
```json
{
  "classId": "...",
  "date": "YYYY-MM-DD",
  "records": [
    {"studentId": "...", "status": "present"},
    {"studentId": "...", "status": "absent"}
  ]
}
```

### Exams, Subjects & Marks

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getExams` | `()` → `Future<List<Exam>>` | GET | `/api/v1/exams` |
| `getSubjects` | `()` → `Future<List<Subject>>` | GET | `/api/v1/subjects` |
| `bulkEnterMarks` | `(String examId, String subjectId, List<Map<String, dynamic>> marks)` → `Future<void>` | POST | `/api/v1/results/bulk` |
| `getResults` | `(String examId, String subjectId, String? classId)` → `Future<List<Map<String, dynamic>>>` | GET | `/api/v1/results?examId=...&subjectId=...[&classId=...]` |

**`bulkEnterMarks` body format:**
```json
{
  "examId": "...",
  "subjectId": "...",
  "marks": [
    {"studentId": "...", "marksObtained": 85, "totalMarks": 100}
  ]
}
```

### Timetable

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getTeacherTimetable` | `(String teacherId, {String? date})` → `Future<List<TimetableEntry>>` | GET | `/api/v1/teachers/$teacherId/timetable` |
| `getClassTimetable` | `(String classId, {String? date})` → `Future<List<TimetableEntry>>` | GET | `/api/v1/classes/$classId/timetable` |

### Announcements

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getTeacherAnnouncements` | `(String teacherId)` → `Future<List<Announcement>>` | GET | `/api/v1/announcements/teacher/$teacherId` |
| `createAnnouncement` | `(String title, String? body, String? classId)` → `Future<Announcement>` | POST | `/api/v1/announcements` |
| `getNotices` | `()` → `Future<List<Announcement>>` | GET | `/api/v1/announcements` |

### Assignments

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getAssignments` | `(String teacherId)` → `Future<List<Assignment>>` | GET | `/api/v1/assignments` (filtered by teacherId query param) |
| `createAssignment` | `(String title, String? description, String? dueDate, String classId, String subjectId)` → `Future<Assignment>` | POST | `/api/v1/assignments` |
| `getAssignmentSubmissions` | `(String assignmentId)` → `Future<List<AssignmentSubmission>>` | GET | `/api/v1/assignments/$assignmentId/submissions` |
| `bulkUpdateSubmissions` | `(String assignmentId, List<Map<String, dynamic>> submissions)` → `Future<void>` | PUT | `/api/v1/assignments/$assignmentId/submissions` |

### Profile

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getTeacherProfile` | `(String teacherId)` → `Future<TeacherProfile>` | GET | `/api/v1/teachers/$teacherId` |

### Remarks

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `createRemark` | `(String studentId, String type, String? category, String message)` → `Future<StudentRemark>` | POST | `/api/v1/remarks` |
| `getTeacherRemarks` | `(String teacherId)` → `Future<List<StudentRemark>>` | GET | `/api/v1/remarks/teacher/$teacherId` |
| `getRemarksForStudent` | `(String teacherId, String studentId)` → `Future<List<StudentRemark>>` | GET | `/api/v1/remarks/teacher/$teacherId/student/$studentId` |
| `updateRemark` | `(String id, {String? type, String? category, String? message})` → `Future<StudentRemark>` | PATCH | `/api/v1/remarks/$id` |
| `deleteRemark` | `(String id)` → `Future<void>` | DELETE | `/api/v1/remarks/$id` |

### Holidays

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getHolidays` | `()` → `Future<List<Holiday>>` | GET | `/api/v1/holidays` |

### Proxies

| Method | Signature | HTTP | Endpoint |
|--------|-----------|------|----------|
| `getMyProxies` | `()` → `Future<List<ProxyAssignment>>` | GET | `/api/v1/proxy/my` |
| `getPendingProxies` | `()` → `Future<List<ProxyAssignment>>` | GET | `/api/v1/proxy/pending` |
| `assignProxy` | `(String timetableId, String proxyTeacherId, String? reason, {String? date})` → `Future<ProxyAssignment>` | POST | `/api/v1/proxy/assign` |
| `respondToProxy` | `(String proxyId, String status)` → `Future<ProxyAssignment>` | PATCH | `/api/v1/proxy/$proxyId/respond` |
| `cancelProxy` | `(String proxyId)` → `Future<void>` | DELETE | `/api/v1/proxy/$proxyId` |
| `getAvailableTeachers` | `(String timetableId, {String? date})` → `Future<List<Map<String, dynamic>>>` | GET | `/api/v1/proxy/available?timetableId=...[&date=...]` |

---

## Screens

| Screen | File | Route | Providers Watched | Key Features |
|--------|------|-------|-------------------|--------------|
| `TeacherShell` | `teacher_shell.dart` | ShellRoute wrapper | `connectivityProvider` | Two-tier layout (800px). Desktop: sidebar. Mobile: bottom nav. |
| `LoginScreen` | `login_screen.dart` | `/login` | `authStateProvider`, `connectivityProvider` | Email/password form, teacher role validation |
| `TeacherDashboardScreen` | `teacher_dashboard_screen.dart` | `/teacher/dashboard` | `teacherDashboardProvider` | Greeting, assigned classes, today's schedule, class teacher info |
| `TeacherAttendanceScreen` | `teacher_attendance_screen.dart` | `/teacher/attendance` | `attendanceStateProvider` | Select class → date → mark present/absent for each student → submit |
| `TeacherMarksScreen` | `teacher_marks_screen.dart` | `/teacher/marks` | `marksStateProvider` | Select class → exam → subject → enter marks per student → submit |
| `TeacherTimetableScreen` | `teacher_timetable_screen.dart` | `/teacher/timetable` | `teacherTimetableProvider` | Weekly timetable view, proxy indicators |
| `TeacherAnnouncementsScreen` | `teacher_announcements_screen.dart` | `/teacher/announcements` | `teacherAnnouncementsProvider` | View announcements + create new (title, body, optional class targeting) |
| `TeacherAssignmentsScreen` | `teacher_assignments_screen.dart` | `/teacher/assignments` | `assignmentsStateProvider` | View assignments, create new, select to view submissions |
| `TeacherAssignmentDetailScreen` | `teacher_assignment_detail_screen.dart` | `/teacher/assignments/:id` | `assignmentsStateProvider` | View submissions, mark status (submitted/pending), add remarks, bulk save |
| `TeacherNoticesScreen` | `teacher_notices_screen.dart` | `/teacher/notices` | `teacherNoticesProvider` | General announcements/notices list |
| `TeacherHolidaysScreen` | `teacher_holidays_screen.dart` | `/teacher/holidays` | `teacherHolidaysProvider` | Holiday/event list |
| `TeacherRemarksScreen` | `teacher_remarks_screen.dart` | `/teacher/remarks` | `remarksStateProvider` | Select class → student → write/edit/delete remarks, view all remarks |
| `TeacherProfileScreen` | `teacher_profile_screen_screen.dart` | `/teacher/profile` | `teacherProfileProvider` | Profile info, change password |

---

## Providers

### Auth (same as all apps)

| Provider | Type | State |
|----------|------|-------|
| `apiClientProvider` | `Provider<ApiClient>` | — |
| `authRepositoryProvider` | `Provider<AuthRepository>` | — |
| `authStateProvider` | `StateNotifierProvider<AuthStateNotifier, AuthState>` | `AuthState` |

### Repository

**Note:** `teacherRepositoryProvider` is defined in `teacher_dashboard_screen.dart`, not in the `providers/` directory:
```dart
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository(ref.watch(apiClientProvider));
});
```

### Attendance

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `attendanceStateProvider` | `StateNotifierProvider<AttendanceStateNotifier, AttendanceState>` | `AttendanceState` | Full attendance workflow |

**`AttendanceState` fields:**

| Field | Type | Default |
|-------|------|---------|
| `teacherClasses` | `List<TeacherClass>` | `[]` |
| `selectedClass` | `TeacherClass?` | `null` |
| `selectedDate` | `DateTime` | `DateTime.now()` |
| `students` | `List<Student>` | `[]` |
| `statuses` | `Map<String, String>` | `{}` (studentId → 'present'/'absent'/'late') |
| `isSubmitting` | `bool` | `false` |
| `errorMessage` | `String?` | `null` |
| `successMessage` | `String?` | `null` |
| `pastRecords` | `List<AttendanceRecord>` | `[]` |
| `quickMode` | `bool` | `false` |

**Methods:**

| Method | Description |
|--------|-------------|
| `loadTeacherClasses(String teacherId)` | Loads assigned classes |
| `quickSelectClass(TeacherClass cls)` | Sets quickMode=true, loads students + existing records |
| `selectClass(TeacherClass cls)` | Sets quickMode=false, loads students + existing records |
| `setDate(DateTime date)` | Changes selected date |
| `setStatus(String studentId, String status)` | Sets attendance status for a student |
| `submitAttendance()` | Bulk marks attendance via `repo.markAttendance()` |
| `clearQuickMode()` | Resets quickMode |
| `clearMessages()` | Clears error/success messages |

### Marks

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `marksStateProvider` | `StateNotifierProvider<MarksStateNotifier, MarksState>` | `MarksState` | Full marks entry workflow |

**`MarksState` fields:**

| Field | Type | Default |
|-------|------|---------|
| `teacherClasses` | `List<TeacherClass>` | `[]` |
| `selectedClass` | `TeacherClass?` | `null` |
| `exams` | `List<Exam>` | `[]` |
| `selectedExam` | `Exam?` | `null` |
| `selectedSubject` | `Subject?` | `null` |
| `students` | `List<Student>` | `[]` |
| `marks` | `Map<String, double>` | `{}` (studentId → marksObtained) |
| `totalMarks` | `double` | `100` |
| `isSubmitting` | `bool` | `false` |
| `errorMessage` | `String?` | `null` |
| `successMessage` | `String?` | `null` |
| `previousResults` | `List<Map<String, dynamic>>` | `[]` |
| `isLoadingPrevious` | `bool` | `false` |

**Methods:**

| Method | Description |
|--------|-------------|
| `loadInitialData(String teacherId)` | Loads classes + exams |
| `selectClass(TeacherClass cls)` | Sets class + derived subject, loads students + previous results |
| `selectExam(Exam exam)` | Sets selected exam |
| `setMark(String studentId, double value)` | Sets marks for a student |
| `setTotalMarks(double value)` | Sets total marks |
| `submitMarks()` | Bulk enters marks via `repo.bulkEnterMarks()` |
| `clearMessages()` | Clears error/success |

### Assignments

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `assignmentsStateProvider` | `StateNotifierProvider<AssignmentsStateNotifier, AssignmentsState>` | `AssignmentsState` | Full assignment + submission workflow |

**`AssignmentsState` fields:**

| Field | Type | Default |
|-------|------|---------|
| `assignments` | `List<Assignment>` | `[]` |
| `selectedAssignment` | `Assignment?` | `null` |
| `submissions` | `List<AssignmentSubmission>` | `[]` |
| `statuses` | `Map<String, String>` | `{}` (studentId → status) |
| `remarks` | `Map<String, String>` | `{}` (studentId → remarks text) |
| `isLoading` | `bool` | `false` |
| `isSubmitting` | `bool` | `false` |
| `errorMessage` | `String?` | `null` |
| `successMessage` | `String?` | `null` |

**Methods:**

| Method | Description |
|--------|-------------|
| `loadAssignments(String teacherId)` | Loads all assignments |
| `selectAssignment(Assignment)` | Selects + loads submissions |
| `setStatus(String studentId, String status)` | Sets submission status |
| `setRemarks(String studentId, String remarks)` | Sets submission remarks |
| `saveSubmissions()` | Bulk updates via `repo.bulkUpdateSubmissions()` |
| `clearSelection()` | Clears selected assignment + submissions |
| `clearMessages()` | Clears error/success |

### Notices

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `teacherNoticesProvider` | `FutureProvider.autoDispose<List<Announcement>>` | `List<Announcement>` | Fetches general notices |

### Proxy

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `myProxiesProvider` | `FutureProvider.autoDispose<List<ProxyAssignment>>` | `List<ProxyAssignment>` | Proxy assignments where teacher is the designated proxy |
| `pendingProxiesProvider` | `FutureProvider.autoDispose<List<ProxyAssignment>>` | `List<ProxyAssignment>` | Pending proxy requests for the teacher |
| `proxyControllerProvider` | `StateNotifierProvider<ProxyController, AsyncValue<void>>` | `AsyncValue<void>` | Proxy CRUD operations |

**`ProxyController` methods:**

| Method | Description |
|--------|-------------|
| `assignProxy(timetableId, proxyTeacherId, reason, {date?})` | Assigns a proxy, invalidates `myProxiesProvider` |
| `respondToProxy(proxyId, status)` | Accepts/rejects, invalidates both providers |
| `cancelProxy(proxyId)` | Cancels, invalidates `myProxiesProvider` |
| `getAvailableTeachers(timetableId, {date?})` | Returns list of available teachers |

### Remarks

| Provider | Type | State | Description |
|----------|------|-------|-------------|
| `remarksStateProvider` | `StateNotifierProvider<RemarksStateNotifier, RemarksState>` | `RemarksState` | Full remarks CRUD workflow |

**`RemarksState` fields:**

| Field | Type | Default |
|-------|------|---------|
| `classes` | `List<TeacherClass>` | `[]` |
| `selectedClass` | `TeacherClass?` | `null` |
| `students` | `List<Student>` | `[]` |
| `selectedStudent` | `Student?` | `null` |
| `studentRemarks` | `List<StudentRemark>` | `[]` |
| `allRemarks` | `List<StudentRemark>` | `[]` |
| `isLoadingClasses` | `bool` | `false` |
| `isLoadingStudents` | `bool` | `false` |
| `isLoadingRemarks` | `bool` | `false` |
| `isLoadingAllRemarks` | `bool` | `false` |
| `isSubmitting` | `bool` | `false` |
| `remarkType` | `String` | `'praise'` |
| `remarkCategory` | `String?` | `null` |
| `errorMessage` | `String?` | `null` |
| `successMessage` | `String?` | `null` |

**Methods:**

| Method | Description |
|--------|-------------|
| `selectClass(TeacherClass)` | Loads students in class |
| `selectStudent(Student)` | Loads remarks for student |
| `clearStudent()` | Clears student selection |
| `setRemarkType(String)` | Sets remark type (praise/warning/etc.) |
| `setRemarkCategory(String?)` | Sets category |
| `submitRemark(String message)` | Creates new remark |
| `editRemark(String id, String type, String? category, String message)` | Updates remark |
| `deleteRemark(String id)` | Deletes remark |
| `loadAllRemarks()` | Loads all teacher's remarks |
| `refresh()` / `refreshRemarks()` | Reloads data |
| `clearMessages()` | Clears error/success |

---

## Widgets

### Sidebar Navigation (`widgets/teacher_sidebar_nav.dart`)

Fixed-width dark sidebar (260px). Navigation items: Dashboard, Attendance, Marks, Timetable, Announcements, Assignments, Notices, Remarks, Holidays, Profile.

### Bottom Navigation (`widgets/teacher_bottom_nav.dart`)

Mobile `NavigationBar` with 5 items: Dashboard, Attendance, Marks, Assignments, Profile. Additional items via "More".

### Back Button Handler (`widgets/back_button_handler.dart`)

Hardware back button handling for Android/web.

---

## Step-by-Step Guides

### How to Add a New Teacher Feature

1. **Add endpoints** in `core/api/endpoints.dart`
2. **Add model** in `domain/teacher_models.dart` with `fromJson` factory
3. **Add repository methods** in `data/teacher_repository.dart`
4. **Add screen** in `presentation/teacher_{feature}_screen.dart` as a `ConsumerWidget`
5. **Add provider** in `presentation/providers/`:
   - Use `FutureProvider.autoDispose` for simple data fetches
   - Use `StateNotifierProvider` for interactive workflows (forms, submissions, etc.)
6. **Add route name** in `core/router/route_names.dart`
7. **Add GoRoute** in `core/router/app_router.dart`
8. **Add navigation** in `teacher_shell.dart` — sidebar (desktop) + bottom nav (mobile)

### How to Add a New Write Operation (e.g., Marking Homework)

1. **Add endpoint** in `endpoints.dart`:
   ```dart
   static const String homework = '$apiPrefix/homework';
   ```

2. **Add repository method** in `teacher_repository.dart`:
   ```dart
   Future<void> markHomework(Map<String, dynamic> body) async {
     await _client.post(Endpoints.homework, body: body);
   }
   ```

3. **Add model** (if needed) in `teacher_models.dart`:
   ```dart
   class Homework {
     final String id;
     final String title;
     final String classId;
     final String subjectId;
     // ... fields
     factory Homework.fromJson(Map<String, dynamic> json) => ...;
   }
   ```

4. **Add provider** with `StateNotifierProvider` for the form state:
   ```dart
   final homeworkStateProvider = StateNotifierProvider<HomeworkNotifier, HomeworkState>((ref) {
     return HomeworkNotifier(ref.watch(teacherRepositoryProvider));
   });
   ```

5. **Add screen** with form fields and submit button that calls the notifier.

6. **Add route** and **navigation** as described above.

### How to Modify the Attendance Flow

1. Edit `AttendanceState` in `teacher_attendance_provider.dart` to add/modify fields
2. Edit `AttendanceStateNotifier` methods to change behavior
3. Edit `teacher_attendance_screen.dart` to change the UI
4. Edit `teacherRepository.markAttendance()` if the API payload format changes

### How to Add Proxy Management for Teachers

The proxy system is already fully implemented. To modify:

1. Edit `ProxyAssignment` model fields in `domain/teacher_models.dart`
2. Edit repository methods in `data/teacher_repository.dart` (6 proxy methods)
3. Edit `teacher_proxy_provider.dart` — `ProxyController` methods
4. Proxy UI is accessible from the teacher dashboard's quick actions or timetable screen
