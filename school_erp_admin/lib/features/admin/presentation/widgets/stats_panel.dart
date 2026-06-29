import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';

class StatsPanel extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? trend;
  final bool trendUp;
  final VoidCallback? onTap;

  const StatsPanel({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trend,
    this.trendUp = true,
    this.onTap,
  });

  @override
  State<StatsPanel> createState() => _StatsPanelState();
}

class _StatsPanelState extends State<StatsPanel> {
  bool _isHovered = false;

  Color get _accent => widget.color;
  Color get _accentLight => widget.color.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context) {
    final numValue = _parseNumericValue(widget.value);
    final suffix = _parseSuffix(widget.value);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: GlassCard(
            onTap: widget.onTap,
            padding: const EdgeInsets.all(20),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accentLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: _accent, size: 22),
                    ),
                    if (widget.trend != null)
                      _TrendBadge(
                        trend: widget.trend!,
                        isUp: widget.trendUp,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: numValue),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      suffix == '%'
                          ? '${value.toStringAsFixed(1)}%'
                          : value.toStringAsFixed(0),
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                            height: 1.1,
                          ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _parseNumericValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _parseSuffix(String value) {
    if (value.contains('%')) return '%';
    return '';
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  final bool isUp;

  const _TrendBadge({required this.trend, required this.isUp});

  @override
  Widget build(BuildContext context) {
    final color = isUp ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            trend,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
