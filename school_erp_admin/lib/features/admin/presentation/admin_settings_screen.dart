import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/theme/theme_mode_provider.dart';
import 'package:school_erp_admin/core/widgets/change_password_dialog.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/auth/presentation/providers/auth_state_provider.dart';

final _schoolProfileProvider = FutureProvider<SchoolProfile>((ref) {
  return ref.watch(adminRepositoryProvider).getSchoolProfile();
});

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _saving = false;

  Future<void> _editSchoolProfile(SchoolProfile profile) async {
    final nameCtrl = TextEditingController(text: profile.name);
    final addressCtrl = TextEditingController(text: profile.address ?? '');
    final phoneCtrl = TextEditingController(text: profile.phone ?? '');
    final emailCtrl = TextEditingController(text: profile.email ?? '');
    final websiteCtrl = TextEditingController(text: profile.website ?? '');
    final academicYearCtrl = TextEditingController(text: profile.academicYear ?? '');
    final establishedYearCtrl = TextEditingController(text: profile.establishedYear ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('School Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'School Name *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: websiteCtrl, decoration: const InputDecoration(labelText: 'Website', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: academicYearCtrl, decoration: const InputDecoration(labelText: 'Academic Year', hintText: 'e.g. 2025-2026', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: establishedYearCtrl, decoration: const InputDecoration(labelText: 'Established Year', hintText: 'e.g. 2000', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _saving ? null : () async {
                if (nameCtrl.text.trim().isEmpty) return;
                setDialogState(() { _saving = true; });
                try {
                  await ref.read(adminRepositoryProvider).updateSchoolProfile({
                    'name': nameCtrl.text.trim(),
                    'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    'website': websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
                    'academic_year': academicYearCtrl.text.trim().isEmpty ? null : academicYearCtrl.text.trim(),
                    'established_year': establishedYearCtrl.text.trim().isEmpty ? null : establishedYearCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setDialogState(() { _saving = false; });
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) ref.invalidate(_schoolProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authStateProvider).user;
    final profileAsync = ref.watch(_schoolProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('School Profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              profileAsync.when(
                loading: () => const GlassCard(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))),
                error: (e, _) => GlassCard(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Failed to load: $e', style: const TextStyle(color: AppColors.error)),
                )),
                data: (profile) => GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
                          style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow(context, 'School Name', profile.name),
                      if (profile.address != null && profile.address!.isNotEmpty) ...[const Divider(height: 24), _infoRow(context, 'Address', profile.address!)],
                      if (profile.phone != null && profile.phone!.isNotEmpty) ...[const Divider(height: 24), _infoRow(context, 'Phone', profile.phone!)],
                      if (profile.email != null && profile.email!.isNotEmpty) ...[const Divider(height: 24), _infoRow(context, 'Email', profile.email!)],
                      if (profile.website != null && profile.website!.isNotEmpty) ...[const Divider(height: 24), _infoRow(context, 'Website', profile.website!)],
                      if (profile.academicYear != null && profile.academicYear!.isNotEmpty) ...[const Divider(height: 24), _infoRow(context, 'Academic Year', profile.academicYear!)],
                      if (profile.establishedYear != null && profile.establishedYear!.isNotEmpty) ...[const Divider(height: 24), _infoRow(context, 'Est. Year', profile.establishedYear!)],
                      const Divider(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _editSchoolProfile(profile),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    _infoRow(context, 'User ID', user?.userId ?? '-'),
                    const Divider(height: 24),
                    _infoRow(context, 'Role', user?.role ?? '-'),
                    const Divider(height: 24),
                    _infoRow(context, 'App Version', '1.0.0'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Choose how the app looks', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (selected) {
                        ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Security', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Change Password', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Update your account password', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const ChangePasswordDialog()),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Change Password'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
