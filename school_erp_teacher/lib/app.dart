import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_teacher/core/theme/app_theme.dart';
import 'package:school_erp_teacher/core/router/app_router.dart';
import 'package:school_erp_teacher/core/storage/storage_service.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return createRouter(storage);
});

class SchoolErpTeacherApp extends ConsumerWidget {
  const SchoolErpTeacherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.watch(apiClientProvider).onUnauthorized = () {
      ref.read(authStateProvider.notifier).logout();
    };

    ref.listen(authStateProvider, (prev, next) {
      if (next.status == AuthStatus.unauthenticated && prev?.status == AuthStatus.authenticated) {
        router.go('/login');
      }
    });

    return MaterialApp.router(
      title: 'School ERP Teacher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: brightness == Brightness.light
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                )
              : const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                ),
          child: child!,
        );
      },
    );
  }
}
