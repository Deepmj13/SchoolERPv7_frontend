import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';
import 'package:school_erp_admin/features/auth/presentation/providers/auth_state_provider.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  static const _items = (
    academic: [
      _MoreItem(icon: Icons.school_rounded, label: 'Classes', route: '/admin/classes'),
      _MoreItem(icon: Icons.book_rounded, label: 'Subjects', route: '/admin/subjects'),
      _MoreItem(icon: Icons.assignment_rounded, label: 'Exams', route: '/admin/exams'),
      _MoreItem(icon: Icons.calendar_month_rounded, label: 'Timetable', route: '/admin/timetable'),
      _MoreItem(icon: Icons.trending_up_rounded, label: 'Attendance', route: '/admin/attendance-report'),
    ],
    communication: [
      _MoreItem(icon: Icons.campaign_rounded, label: 'Announcements', route: '/admin/announcements'),
    ],
    system: [
      _MoreItem(icon: Icons.settings_rounded, label: 'Settings', route: '/admin/settings'),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Academic', _items.academic, context, ref),
            const SizedBox(height: 24),
            _buildSection('Communication', _items.communication, context, ref),
            const SizedBox(height: 24),
            _buildSection('System', _items.system, context, ref),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<_MoreItem> items, BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: items.map((item) => _buildGridCard(item, context)).toList(),
        ),
      ],
    );
  }

  Widget _buildGridCard(_MoreItem item, BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(item.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
