import 'dart:math';
import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';

enum AnalyticsPeriod { today, week, month }

class AnalyticsSection extends StatefulWidget {
  final double todayAttendance;
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;

  const AnalyticsSection({
    super.key,
    required this.todayAttendance,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalClasses,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.week;
  int? _tappedBarIndex;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        _PeriodTabs(
          selected: _selectedPeriod,
          onSelected: (p) => setState(() {
            _selectedPeriod = p;
            _tappedBarIndex = null;
          }),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _AttendanceChartCard(
          period: _selectedPeriod,
          todayAttendance: widget.todayAttendance,
          tappedBarIndex: _tappedBarIndex,
          onBarTapped: (i) => setState(() => _tappedBarIndex = i),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _DistributionCard(
          totalStudents: widget.totalStudents,
          totalTeachers: widget.totalTeachers,
          totalClasses: widget.totalClasses,
          attendancePercentage: widget.todayAttendance,
          isMobile: isMobile,
        ),
      ],
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onSelected;
  final bool isMobile;

  const _PeriodTabs({
    required this.selected,
    required this.onSelected,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassDark : AppColors.glassLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        ),
      ),
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = period == selected;
          final label = switch (period) {
            AnalyticsPeriod.today => 'Today',
            AnalyticsPeriod.week => 'This Week',
            AnalyticsPeriod.month => 'This Month',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AttendanceChartCard extends StatelessWidget {
  final AnalyticsPeriod period;
  final double todayAttendance;
  final int? tappedBarIndex;
  final ValueChanged<int> onBarTapped;
  final bool isMobile;

  const _AttendanceChartCard({
    required this.period,
    required this.todayAttendance,
    required this.tappedBarIndex,
    required this.onBarTapped,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData();
    final entries = chartData.entries.toList();
    final chartHeight = isMobile ? 160.0 : 200.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTitle(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (tappedBarIndex != null &&
              tappedBarIndex! < entries.length) ...[
            const SizedBox(height: 8),
            _TooltipChip(
              label: entries[tappedBarIndex!].key,
              value: '${entries[tappedBarIndex!].value.toStringAsFixed(1)}%',
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight,
            child: RepaintBoundary(
              child: GestureDetector(
                onTapUp: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final width = renderBox.size.width - 40;
                  final barCount = chartData.entries.length;
                  if (barCount == 0) return;
                  final spacing = width / barCount;
                  final tapX = details.localPosition.dx - 20;
                  final index = (tapX / spacing).floor();
                  if (index >= 0 && index < barCount) {
                    onBarTapped(index);
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _InteractiveBarChartPainter(
                    entries: chartData.entries.toList(),
                    maxValue: _getEffectiveMax(chartData),
                    tappedIndex: tappedBarIndex,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _getChartData() {
    final rng = Random(42);
    switch (period) {
      case AnalyticsPeriod.today:
        return {'Today': todayAttendance};
      case AnalyticsPeriod.week:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return Map.fromIterables(days, List.generate(7, (i) {
          if (i == 6) return todayAttendance;
          return (todayAttendance + (rng.nextDouble() - 0.5) * 16).clamp(60.0, 100.0);
        }));
      case AnalyticsPeriod.month:
        return Map.fromIterables(
          List.generate(4, (i) => 'Week ${i + 1}'),
          List.generate(4, (i) {
            if (i == 3) return todayAttendance;
            return (todayAttendance + (rng.nextDouble() - 0.5) * 12).clamp(60.0, 100.0);
          }),
        );
    }
  }

  double _getEffectiveMax(Map<String, double> data) {
    final maxVal = data.values.fold<double>(0, (m, v) => v > m ? v : m);
    return maxVal < 20 ? 100.0 : maxVal.clamp(50.0, 100.0);
  }

  String _getTitle() => switch (period) {
        AnalyticsPeriod.today => "Today's Attendance",
        AnalyticsPeriod.week => 'Attendance This Week',
        AnalyticsPeriod.month => 'Attendance This Month',
      };
}

class _TooltipChip extends StatelessWidget {
  final String label;
  final String value;

  const _TooltipChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveBarChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final double maxValue;
  final int? tappedIndex;
  final bool isDark;

  _InteractiveBarChartPainter({
    required this.entries,
    required this.maxValue,
    required this.tappedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final barCount = entries.length;
    final totalSpacing = size.width / barCount;
    final barWidth = totalSpacing * 0.5;
    final sidePadding = totalSpacing * 0.25;

    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < barCount; i++) {
      final entry = entries[i];
      final x = sidePadding + i * totalSpacing;
      final barHeight = (entry.value / maxValue) * (size.height - 20);
      final y = size.height - barHeight;

      final isTapped = tappedIndex == i;
      final effectiveWidth = isTapped ? barWidth * 1.1 : barWidth;
      final effectiveX = isTapped ? x - barWidth * 0.05 : x;

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(effectiveX, y, effectiveWidth, barHeight),
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
          colors: [
            color.withValues(alpha: isTapped ? 1.0 : 0.7),
            color,
          ],
        ).createShader(rrect.outerRect);

      canvas.drawRRect(rrect, paint);

      if (isTapped) {
        final highlightPaint = Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        final highlightRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            effectiveX - 2,
            y - 2,
            effectiveWidth + 4,
            barHeight + 4,
          ),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(highlightRect, highlightPaint);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: isTapped ? AppColors.textPrimary : Colors.grey,
            fontSize: 11,
            fontWeight: isTapped ? FontWeight.w600 : FontWeight.normal,
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
  bool shouldRepaint(covariant _InteractiveBarChartPainter oldDelegate) =>
      oldDelegate.entries != entries ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.tappedIndex != tappedIndex;
}

class _DistributionCard extends StatelessWidget {
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final double attendancePercentage;
  final bool isMobile;

  const _DistributionCard({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.attendancePercentage,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      totalStudents.toDouble(),
      totalTeachers.toDouble(),
      totalClasses.toDouble(),
    ].reduce((a, b) => a > b ? a : b);

    return GlassCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
              const Icon(
                Icons.pie_chart_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DistributionBar(
            label: 'Students',
            value: totalStudents.toDouble(),
            maxValue: maxValue,
            color: AppColors.info,
            icon: Icons.people_rounded,
          ),
          const SizedBox(height: 14),
          _DistributionBar(
            label: 'Teachers',
            value: totalTeachers.toDouble(),
            maxValue: maxValue,
            color: AppColors.success,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _DistributionBar(
            label: 'Classes',
            value: totalClasses.toDouble(),
            maxValue: maxValue,
            color: AppColors.warning,
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 14),
          _DistributionBar(
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

class _DistributionBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final IconData icon;

  const _DistributionBar({
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
