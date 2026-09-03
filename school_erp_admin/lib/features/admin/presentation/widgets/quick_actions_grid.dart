import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final actions = [
      const _QuickAction(
        icon: Icons.person_add_rounded,
        label: 'Add Student',
        color: AppColors.info,
        route: '/admin/students',
      ),
      const _QuickAction(
        icon: Icons.payments_rounded,
        label: 'Record Fee',
        color: AppColors.success,
        route: '/admin/fees',
      ),
      const _QuickAction(
        icon: Icons.campaign_rounded,
        label: 'Announce',
        color: AppColors.warning,
        route: '/admin/announcements',
      ),
      const _QuickAction(
        icon: Icons.swap_horiz_rounded,
        label: 'Assign Proxy',
        color: AppColors.primary,
        route: '/admin/proxies',
      ),
      const _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'Reports',
        color: AppColors.error,
        route: '/admin/reports',
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: actions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) => _QuickActionTile(
            action: actions[index],
            compact: true,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 5 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: actions
              .map((a) => _QuickActionTile(action: a, compact: false))
              .toList(),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _QuickActionTile extends StatefulWidget {
  final _QuickAction action;
  final bool compact;

  const _QuickActionTile({
    required this.action,
    required this.compact,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.compact) {
      return GestureDetector(
        onTap: () => context.go(a.route),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.glassDark
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: a.color.withValues(alpha: _isHovered ? 0.12 : 0.04),
                blurRadius: _isHovered ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.icon, color: a.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                a.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(a.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? a.color.withValues(alpha: 0.3)
                  : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
            ),
            boxShadow: [
              BoxShadow(
                color: a.color.withValues(alpha: _isHovered ? 0.12 : 0.04),
                blurRadius: _isHovered ? 14 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.icon, color: a.color, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  a.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
