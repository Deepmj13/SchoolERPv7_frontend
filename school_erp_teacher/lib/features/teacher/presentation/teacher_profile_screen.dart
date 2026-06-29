import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/change_password_dialog.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

final teacherProfileProvider =
    FutureProvider<TeacherProfile>((ref) {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getTeacherProfile(teacherId);
});

final teacherClassesForProfileProvider =
    FutureProvider<List<TeacherClass>>((ref) {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getTeacherClasses(teacherId);
});

final teacherClassTeacherProvider =
    FutureProvider<ClassModel?>((ref) async {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  final repo = ref.watch(teacherRepositoryProvider);
  try {
    return await repo.getClassTeacherClass(teacherId);
  } catch (_) {
    return null;
  }
});

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);
    final classesAsync = ref.watch(teacherClassesForProfileProvider);
    final classTeacherAsync = ref.watch(teacherClassTeacherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary,
              child: profileAsync.when(
                loading: () => const CircularProgressIndicator(
                    color: Colors.white),
                error: (_, _) =>
                    const Icon(Icons.person, size: 48, color: Colors.white),
                data: (profile) => Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : 'T',
                  style: const TextStyle(
                      fontSize: 36, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              loading: () =>
                  const CircularProgressIndicator(),
              error: (e, _) =>
                  Text('Failed to load: $e',
                      style: const TextStyle(color: AppColors.error)),
              data: (profile) => Column(
                children: [
                  Text(profile.fullName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium),
                  const SizedBox(height: 4),
                  if (profile.email != null)
                    Text(profile.email!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      children: [
                        _ProfileRow(
                            icon: Icons.badge,
                            label: 'Employee ID',
                            value: profile.id),
                        const Divider(),
                        _ProfileRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: profile.email ?? '-'),
                        const Divider(),
                        _ProfileRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: profile.phone ?? '-'),
                        const Divider(),
                        _ProfileRow(
                            icon: Icons.check_circle,
                            label: 'Status',
                            value: profile.isActive
                                ? 'Active'
                                : 'Inactive'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (classTeacherAsync.valueOrNull != null) ...[
              const SizedBox(height: 24),
              Text('My Class',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _myClassCard(context, classTeacherAsync.valueOrNull!),
            ],
            const SizedBox(height: 24),
            Text('Assigned Classes',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            classesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Failed to load: $e',
                      style: const TextStyle(color: AppColors.error)),
              data: (classes) {
                final classTeacher = classTeacherAsync.valueOrNull;
                final filtered = classTeacher != null
                    ? classes.where((c) => c.classId != classTeacher.id).toList()
                    : classes;
                final grouped = <String, List<TeacherClass>>{};
                for (final c in filtered) {
                  grouped.putIfAbsent(c.display, () => []).add(c);
                }
                if (grouped.isEmpty) {
                  return const GlassCard(
                    child: Center(
                      child: Text('No classes assigned'),
                    ),
                  );
                }
                return Column(
                  children: grouped.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary
                                  .withValues(alpha: 0.1),
                              child: Icon(Icons.school_rounded,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Text(
                                    entry.value
                                        .map((e) => e.subjectName)
                                        .join(', '),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Security',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ChangePasswordDialog(),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

Widget _myClassCard(BuildContext context, ClassModel cls) {
  return GlassCard(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 4),
              Text('Class Teacher',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${cls.name} - ${cls.section}',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${cls.studentCount} students',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}
