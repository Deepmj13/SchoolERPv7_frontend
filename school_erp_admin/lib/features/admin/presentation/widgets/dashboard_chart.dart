import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';

class AttendanceBarChart extends StatelessWidget {
  final Map<String, double> data;
  final double height;

  const AttendanceBarChart({
    super.key,
    required this.data,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = data.entries.toList();
    final maxValue = entries.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final effectiveMax = maxValue < 20 ? 100.0 : maxValue.clamp(50.0, 100.0);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance This Week',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Icon(Icons.calendar_month_outlined,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(
                entries: entries,
                maxValue: effectiveMax,
                barColor: AppColors.primary,
                gridColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final double maxValue;
  final Color barColor;
  final Color gridColor;

  _BarChartPainter({
    required this.entries,
    required this.maxValue,
    required this.barColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final barCount = entries.length;
    final totalSpacing = size.width / barCount;
    final barWidth = totalSpacing * 0.5;
    final sidePadding = totalSpacing * 0.25;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw bars
    for (int i = 0; i < barCount; i++) {
      final entry = entries[i];
      final x = sidePadding + i * totalSpacing;
      final barHeight = (entry.value / maxValue) * (size.height - 20);
      final y = size.height - barHeight;

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      final color = entry.value >= 75
          ? AppColors.success
          : entry.value >= 50
              ? AppColors.warning
              : AppColors.error;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.8), color],
        ).createShader(rrect.outerRect);

      canvas.drawRRect(rrect, paint);

      // Day label
      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: totalSpacing);

      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, size.height + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.maxValue != maxValue;
}

class DistributionBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final IconData icon;

  const DistributionBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(
            value >= 1000
                ? '${(value / 1000).toStringAsFixed(1)}k'
                : value.toStringAsFixed(0),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class DistributionCard extends StatelessWidget {
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final double attendancePercentage;

  const DistributionCard({
    super.key,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.attendancePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      totalStudents.toDouble(),
      totalTeachers.toDouble(),
      totalClasses.toDouble(),
    ].reduce((a, b) => a > b ? a : b);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distribution',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Icon(Icons.pie_chart_outline,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          DistributionBar(
            label: 'Students',
            value: totalStudents.toDouble(),
            maxValue: maxValue,
            color: AppColors.info,
            icon: Icons.people_rounded,
          ),
          const SizedBox(height: 14),
          DistributionBar(
            label: 'Teachers',
            value: totalTeachers.toDouble(),
            maxValue: maxValue,
            color: AppColors.success,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          DistributionBar(
            label: 'Classes',
            value: totalClasses.toDouble(),
            maxValue: maxValue,
            color: AppColors.warning,
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 14),
          DistributionBar(
            label: 'Attendance',
            value: attendancePercentage,
            maxValue: 100,
            color: AppColors.primary,
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}
