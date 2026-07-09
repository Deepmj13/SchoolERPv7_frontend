import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';

void showMoreMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor:
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _MoreItem(
            icon: Icons.assignment_rounded,
            label: 'Results',
            onTap: () {
              Navigator.pop(ctx);
              context.go('/student/results');
            },
          ),
          _MoreItem(
            icon: Icons.attach_money_rounded,
            label: 'Fees',
            onTap: () {
              Navigator.pop(ctx);
              context.go('/student/fees');
            },
          ),
          _MoreItem(
            icon: Icons.event_rounded,
            label: 'Holidays',
            onTap: () {
              Navigator.pop(ctx);
              context.go('/student/holidays');
            },
          ),
          _MoreItem(
            icon: Icons.campaign_rounded,
            label: 'Notices',
            onTap: () {
              Navigator.pop(ctx);
              context.go('/student/notices');
            },
          ),
          _MoreItem(
            icon: Icons.book_rounded,
            label: 'Assignments',
            onTap: () {
              Navigator.pop(ctx);
              context.go('/student/assignments');
            },
          ),
          _MoreItem(
            icon: Icons.rate_review_rounded,
            label: 'Remarks',
            onTap: () {
              Navigator.pop(ctx);
              context.go('/student/remarks');
            },
          ),
          _MoreItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            onTap: () {
              Navigator.pop(ctx);
              context.go('/student/profile');
            },
          ),
          ],
        ),
        ),
      ),
    ),
  );
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}
