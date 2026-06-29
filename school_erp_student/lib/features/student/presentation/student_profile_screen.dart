import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/change_password_dialog.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_profile_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);

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
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Failed to load: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (profile) => Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded,
                      size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(profile.fullName,
                    style: Theme.of(context).textTheme.headlineMedium),
                if (profile.email != null) ...[
                  const SizedBox(height: 4),
                  Text(profile.email!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      _profileRow(
                          Icons.badge_outlined,
                          'Roll No',
                          profile.rollNumber ?? 'N/A'),
                      const Divider(height: 1),
                      _profileRow(Icons.school_outlined, 'Class',
                          profile.className ?? 'N/A'),
                      const Divider(height: 1),
                      _profileRow(Icons.group_outlined, 'Section',
                          profile.classSection ?? 'N/A'),
                      if (profile.parentName != null) ...[
                        const Divider(height: 1),
                        _profileRow(Icons.people_outlined,
                            'Parent', profile.parentName!),
                      ],
                      if (profile.parentPhone != null) ...[
                        const Divider(height: 1),
                        _profileRow(Icons.phone_outlined, 'Contact',
                            profile.parentPhone!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ChangePasswordDialog(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).logout();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Logout',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
