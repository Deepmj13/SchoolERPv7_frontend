# School ERP v7 — Frontend Monorepo

A complete school management system built with Flutter, consisting of three independent portal apps for **Admins**, **Teachers**, and **Students**. Each app communicates with a shared REST API backend.

## Project Overview

| App | Purpose | Target Users |
|-----|---------|--------------|
| [`school_erp_admin`](./school_erp_admin/) | Full-featured admin dashboard — manages students, teachers, staff, classes, subjects, exams, grading, timetables, attendance, fees, announcements, holidays, proxies, reports, and promotions | School administrators |
| [`school_erp_student`](./school_erp_student/) | Read-oriented student portal — shows dashboard, attendance, results, timetable, fees, assignments, notices, holidays, remarks, and profile | Students |
| [`school_erp_teacher`](./school_erp_teacher/) | Functional teacher portal — marks attendance, enters marks, manages assignments + submissions, creates announcements, writes remarks, manages proxies, views timetable | Teachers |

## Monorepo Structure

```
frontend/
├── school_erp_admin/       # Admin portal (68 Dart files)
├── school_erp_student/     # Student portal (56 Dart files)
├── school_erp_teacher/     # Teacher portal (51 Dart files)
└── README.md               # This file
```

> **Important:** There is no shared/common package. Each app **fully duplicates** the core infrastructure (API client, router, storage, logging, connectivity, theme, widgets, auth). Changes to shared code must be applied to all three apps independently.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart SDK ^3.12.1) |
| State Management | Riverpod (`flutter_riverpod ^2.6.1`) |
| Routing | GoRouter (`go_router ^14.8.1`) |
| HTTP Client | `http ^1.3.0` (not Dio) |
| Secure Storage | `flutter_secure_storage ^10.3.1` |
| Connectivity | `connectivity_plus ^7.1.1` |
| Error Tracking | `sentry_flutter ^9.26.0` |
| Logging | `logging ^1.3.0` |
| TLS Pinning | `crypto ^3.0.0` + conditional imports |
| UI Theme | Material 3 (`useMaterial3: true`) |
| Excel Export | `excel ^4.0.6` (admin only) |
| File System | `path_provider ^2.1.6` (admin only) |

## Shared Architecture (All 3 Apps)

Every app follows the **same clean architecture pattern** with identical directory structure:

```
lib/
├── main.dart                              # Entry point
├── app.dart                               # MaterialApp.router + theme + auth listener
├── core/                                  # Cross-cutting infrastructure
│   ├── api/
│   │   ├── api_client.dart                # HTTP client with JWT auth, retry, refresh
│   │   ├── endpoints.dart                 # REST endpoint URL constants
│   │   ├── security_client_io.dart        # Platform-specific TLS client (native)
│   │   └── security_client_default.dart   # Null client (web fallback)
│   ├── connectivity/
│   │   └── connectivity_provider.dart     # StreamProvider<bool> for online/offline
│   ├── logging/
│   │   └── app_logger.dart                # Hierarchical loggers (api, auth, storage, ui)
│   ├── router/
│   │   ├── app_router.dart                # GoRouter with ShellRoute + auth redirect
│   │   └── route_names.dart               # Named route string constants
│   ├── storage/
│   │   ├── storage_interface.dart         # Abstract interface
│   │   └── storage_service.dart           # FlutterSecureStorage implementation
│   ├── theme/
│   │   ├── app_colors.dart                # Color palette constants
│   │   ├── app_theme.dart                 # Material 3 ThemeData (light + dark)
│   │   └── theme_mode_provider.dart       # Theme toggle persistence (admin only)
│   └── widgets/                           # Shared reusable UI components
│       ├── glass_card.dart                # Glassmorphism card container
│       ├── custom_button.dart             # Loading-aware button
│       ├── skeleton_loader.dart           # Basic skeleton block
│       ├── shimmer.dart                   # Shimmer animation wrapper
│       ├── list_skeleton_loader.dart      # Pre-built list skeleton
│       ├── change_password_dialog.dart    # Reusable password change dialog
│       ├── error_retry_widget.dart        # Error state with retry (admin only)
│       ├── adaptive_layout.dart           # Three-tier responsive switcher (admin only)
│       ├── loading_overlay.dart           # Semi-transparent overlay + spinner (admin only)
│       └── (app-specific skeleton loaders)
└── features/                              # Feature modules
    ├── auth/                              # Authentication (identical across all 3)
    │   ├── domain/user_model.dart
    │   ├── data/auth_repository.dart
    │   └── presentation/
    │       ├── login_screen.dart
    │       └── providers/auth_state_provider.dart
    └── {role}/                            # Role-specific features (admin/student/teacher)
        ├── domain/{role}_models.dart      # Domain model classes with fromJson
        ├── data/{role}_repository.dart    # API call methods
        └── presentation/
            ├── {role}_shell.dart          # Main layout (sidebar + content)
            ├── {role}_dashboard_screen.dart
            ├── {role}_*_screen.dart       # Individual screens
            ├── providers/                 # Riverpod providers per screen
            └── widgets/                   # Feature-specific UI (nav, forms, etc.)
```

## Provider Dependency Graph

The dependency chain is identical across all apps:

```
StorageInterface (override in main.dart)
       │
       ▼
ApiClient (Provider) ─── ref.onDispose(client.dispose)
       │
       ▼
AuthRepository (Provider)
       │
       ▼
AuthStateNotifier (StateNotifierProvider) ─── AuthState {status, user, errorMessage}
       │
       ▼
Feature Repository (Provider) ─── e.g. AdminRepository, StudentRepository, TeacherRepository
       │
       ▼
Feature Providers (FutureProvider / StateNotifierProvider per screen)
```

## API Client Pattern

All apps use a centralized `ApiClient` class (`core/api/api_client.dart`) that provides:

- **JWT Bearer token injection** — reads token from secure storage, adds `Authorization: Bearer <token>` header
- **Automatic token refresh on 401** — calls `POST /api/v1/auth/refresh` with the expired token, retries the original request once
- **Exponential backoff retry** — retries on transient errors (502, 503, 504, 429) with `pow(2, retry) * 1000ms + random(0-500ms)` jitter, up to 3 retries
- **Configurable timeouts** — Admin/Student: 30s default, 15s refresh; Teacher: 15s default, 10s refresh
- **SSL certificate pinning** — optional, configured via `CERT_PIN` env var
- **Structured error responses** — `ApiException(statusCode, message)` with nested `details` list

## Authentication Flow

1. `LoginScreen` presents email + password form (validated: email regex, 6-char min password)
2. `AuthStateNotifier.login()` calls `AuthRepository.login()` → `POST /api/v1/auth/login`
3. Backend returns `{token, role, userId, teacherId?, studentId?}` → mapped to `UserModel`
4. **Role check**: Admin app rejects non-admin credentials, Student rejects non-students, Teacher rejects non-teachers
5. Token + user saved to `FlutterSecureStorage`
6. `GoRouter.redirect` checks token presence → allows access to `/{role}/dashboard`
7. On 401 from any API call, `ApiClient` triggers refresh → on failure, `onUnauthorized` callback → `AuthStateNotifier.logout()` → clears storage → redirect to `/login`

## Responsive Layout

| App | Breakpoints | Tiers |
|-----|-------------|-------|
| Admin | < 600px (mobile), 600–1100px (tablet), ≥ 1100px (desktop) | 3-tier |
| Student | < 800px (mobile), ≥ 800px (desktop) | 2-tier |
| Teacher | < 800px (mobile), ≥ 800px (desktop) | 2-tier |

**Desktop**: Full sidebar navigation + content area (Row layout)
**Mobile**: Bottom `NavigationBar` + content (Admin also has a drawer with sectioned nav)

## Theme System

### Color Palette

All apps share a unified primary brand color and status colors:

| Token | Hex | Purpose |
|-------|-----|---------|
| `primary` | `#4F6EF7` | Brand blue |
| `primaryLight` | `#7B93F9` | Lighter variant |
| `primaryDark` | `#3A56D4` | Darker variant |
| `background` | `#F5F6FA` | Light scaffold bg |
| `textPrimary` | `#1A1A1A` | Primary text |
| `textSecondary` | `#6B7280` | Muted text |
| `success` | `#22C55E` | Green |
| `warning` | `#F59E0B` | Amber |
| `error` | `#EF4444` | Red |
| `info` | `#3B82F6` | Blue |
| `glassLight` | `#CCFFFFFF` | Glassmorphism fill (light) |
| `glassDark` | `#CC1A1A1A` | Glassmorphism fill (dark) |
| `sidebarBg` | `#1A1D2E` | Dark sidebar (student/teacher) |

### Text Scale

| Style | Size | Weight |
|-------|------|--------|
| `displayLarge` | 32px | bold |
| `headlineLarge` | 24px | w600 |
| `headlineMedium` | 20px | w600 |
| `titleLarge` | 18px | w600 |
| `titleMedium` | 16px | w500 |
| `bodyLarge` | 16px | normal |
| `bodyMedium` | 14px | normal |
| `labelLarge` | 14px | w600 |

### Component Theming

- **Cards**: No elevation, 16px border radius, glass-effect fill, thin border
- **Elevated Buttons**: Primary color bg, 12px border radius, 24x14 padding, no elevation
- **Input Fields**: Filled style, 12px border radius, primary focus border (2px), 16x14 content padding

## Environment Configuration

All configuration is compile-time via `--dart-define`:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_BASE_URL` | `https://renderbackned.onrender.com` | Backend API base URL |
| `SENTRY_DSN` | `''` (empty = disabled) | Sentry error tracking DSN |
| `CERT_PIN` | `''` (empty = no pinning) | SHA-256 certificate pin for TLS |

### Running an App

```bash
# Run admin app (development)
cd school_erp_admin
flutter run

# Run with custom API URL
flutter run --dart-define=API_BASE_URL=https://your-api.com

# Build for release
flutter build apk --dart-define=API_BASE_URL=https://your-api.com
```

## Code Duplication Map

The following files are **identical or near-identical** across all three apps:

| Duplicated File | Notes |
|----------------|-------|
| `core/api/api_client.dart` | Minor timeout differences (teacher: 15s vs 30s) |
| `core/api/security_client_io.dart` | Byte-identical across all apps |
| `core/api/security_client_default.dart` | Byte-identical across all apps |
| `core/storage/storage_interface.dart` | Identical (admin adds 2 theme methods) |
| `core/storage/storage_service.dart` | Identical |
| `core/connectivity/connectivity_provider.dart` | Identical |
| `core/logging/app_logger.dart` | Identical |
| `core/theme/app_colors.dart` | Admin has additional tokens |
| `core/theme/app_theme.dart` | Admin has additional dark mode tokens |
| `core/widgets/*.dart` | All shared widgets duplicated |
| `features/auth/*` | Entire auth module (UserModel, AuthRepository, AuthStateNotifier, LoginScreen) |
| Domain model classes: `Holiday`, `TimetableEntry`, `AttendanceRecord`, `Announcement`, `Student`, `ClassModel` | Re-declared in each app's `*_models.dart` with minor field variations |

> **Recommendation:** Consider extracting shared code into a `common/` or `core/` package using melos or a path dependency to eliminate ~500+ lines of duplication.

## Cross-App Comparison

### Routes

| Metric | Admin | Student | Teacher |
|--------|-------|---------|---------|
| Total routes | 20 | 13 | 12 |
| Dynamic routes (`:id`) | 1 (`:examId`) | 2 (`:id` × 2) | 1 (`:id`) |
| Page transitions | Fade (CustomTransitionPage) | Default | Default |

### Screens

| Metric | Admin | Student | Teacher |
|--------|-------|---------|---------|
| Total screens | 20 + shell | 12 + shell | 11 + shell |
| CRUD screens | 12 | 0 | 3 |
| Read-only screens | 8 | 12 | 8 |

### API Surface

| Metric | Admin | Student | Teacher |
|--------|-------|---------|---------|
| Endpoint constants | 43 | 11 | 20 |
| Endpoint methods | 22 | 10 | 22 |
| Repository methods | 76 | 10 | 32 |

### Domain Models

| Metric | Admin | Student | Teacher |
|--------|-------|---------|---------|
| Total model classes | 20 | 13 | 16 |
| With `fromJson` | 19 | 12 | 14 |
| With serialization out | 4 | 0 | 0 |
| Generic classes | 1 (`PaginatedResponse<T>`) | 0 | 0 |

### Providers

| Metric | Admin | Student | Teacher |
|--------|-------|---------|---------|
| `Provider` | 3 | 3 | 2 |
| `StateNotifierProvider` | 3 | 3 | 7 |
| `FutureProvider` | 1 | 2 | 0 |
| `FutureProvider.autoDispose` | 0 | 7 | 3 |
| `StateProvider` | 2 | 0 | 0 |
| **Total** | **9** | **15** | **12** |

## Step-by-Step Guides

### How to Add a New Screen (Any App)

1. **Create the screen file** in `lib/features/{role}/presentation/`:
   ```dart
   // lib/features/{role}/presentation/{role}_my_feature_screen.dart
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';

   class MyFeatureScreen extends ConsumerWidget {
     const MyFeatureScreen({super.key});

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       // Use ref.watch() to consume providers
       return Scaffold(
         body: Center(child: Text('My Feature')),
       );
     }
   }
   ```

2. **Add a route name** in `lib/core/router/route_names.dart`:
   ```dart
   static const String myFeature = 'myFeature';
   ```

3. **Add the GoRoute** in `lib/core/router/app_router.dart` inside the `ShellRoute`:
   ```dart
   GoRoute(
     path: '/{role}/my-feature',
     name: RouteNames.myFeature,
     builder: (context, state) => const MyFeatureScreen(),
   ),
   ```

4. **Add navigation** — add a `NavigationDestination` (mobile) / `NavigationRailDestination` (desktop) in the shell widget, or use `context.go()` / `context.push()`.

### How to Add a New API Endpoint

1. **Add the endpoint constant** in `lib/core/api/endpoints.dart`:
   ```dart
   static const String myEndpoint = '$apiPrefix/my-resource';
   static String myEndpointById(String id) => '$apiPrefix/my-resource/$id';
   ```

2. **Add the domain model** (if new) in `lib/features/{role}/domain/{role}_models.dart`:
   ```dart
   class MyModel {
     final String id;
     final String name;
     // ... fields

     MyModel({required this.id, required this.name});

     factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
       id: json['id'] as String,
       name: json['name'] as String,
     );
   }
   ```

3. **Add repository methods** in `lib/features/{role}/data/{role}_repository.dart`:
   ```dart
   Future<List<MyModel>> getMyResources() async {
     final response = await _client.get(Endpoints.myEndpoint);
     final List data = json.decode(response.body);
     return data.map((e) => MyModel.fromJson(e)).toList();
   }
   ```

4. **Create a provider** in `lib/features/{role}/presentation/providers/`:
   ```dart
   final myResourcesProvider = FutureProvider.autoDispose<List<MyModel>>((ref) async {
     final repo = ref.watch(myRepositoryProvider);
     return repo.getMyResources();
   });
   ```

5. **Consume in a screen** using `ref.watch(myResourcesProvider)`.

### How to Add a New Domain Model Field

1. **Add the field** to the model class in `lib/features/{role}/domain/{role}_models.dart`
2. **Update `fromJson`** to map the JSON key (use snake_case key from the API)
3. **Update `toJson`/`toCreateJson`/`toUpdateJson`** if the field is sent to the API
4. **Update `UnpaidFeeItem`, `FeePost`, etc.** — if the field affects computed properties

### How to Add a New Riverpod Provider

**For read-only data (FutureProvider):**
```dart
final myDataProvider = FutureProvider.autoDispose<MyData>((ref) async {
  final repo = ref.watch(myRepositoryProvider);
  return repo.fetchData();
});
```

**For interactive/editable state (StateNotifierProvider):**
```dart
// State class
class MyState {
  final List<Item> items;
  final bool isLoading;
  final String? error;
  MyState({this.items = const [], this.isLoading = false, this.error});
  MyState copyWith({...}) => MyState(...);
}

// Notifier class
class MyNotifier extends StateNotifier<MyState> {
  final MyRepository _repo;
  MyNotifier(this._repo) : super(MyState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.fetchItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// Provider
final myStateProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref.watch(myRepositoryProvider));
});
```

### How to Change the Theme/Colors

1. **Change the primary color** in `lib/core/theme/app_colors.dart`:
   ```dart
   static const Color primary = Color(0xFF_YOUR_COLOR);  // Change this
   ```

2. **Add new color tokens** (optional) in the same file:
   ```dart
   static const Color myCustomColor = Color(0xFF123456);
   ```

3. **Modify component styles** in `lib/core/theme/app_theme.dart` — update `cardTheme`, `elevatedButtonTheme`, `inputDecorationTheme`, or `textTheme`.

4. **Apply everywhere**: Since Material 3 uses `colorSchemeSeed`, changing `AppColors.primary` will cascade to all derived colors automatically.

### How to Add a New Feature Module

1. **Create the directory structure:**
   ```
   lib/features/{feature_name}/
   ├── domain/
   │   └── {feature_name}_models.dart
   ├── data/
   │   └── {feature_name}_repository.dart
   └── presentation/
       ├── {feature_name}_screen.dart
       ├── providers/
       │   └── {feature_name}_provider.dart
       └── widgets/
           └── (feature-specific widgets)
   ```

2. **Add endpoints** in `lib/core/api/endpoints.dart`
3. **Add route name** in `lib/core/router/route_names.dart`
4. **Add GoRoute** in `lib/core/router/app_router.dart`
5. **Add navigation** in the shell widget's sidebar/bottom nav
6. **Wire up providers** and consume in screens

## Testing

Tests are minimal and located in each app's `test/` directory:

| App | Test Files |
|-----|-----------|
| Admin | `widget_test.dart`, `features/auth/domain/user_model_test.dart`, `features/admin/domain/admin_models_test.dart` |
| Student | `widget_test.dart`, `features/auth/domain/user_model_test.dart` |
| Teacher | `widget_test.dart`, `core/api/api_client_test.dart`, `features/auth/domain/user_model_test.dart` |

Run tests with:
```bash
cd school_erp_admin  # or school_erp_student / school_erp_teacher
flutter test
```
