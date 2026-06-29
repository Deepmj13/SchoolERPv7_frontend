import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_timetable_provider.dart';

class StudentTimetableScreen extends ConsumerStatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  ConsumerState<StudentTimetableScreen> createState() =>
      _StudentTimetableScreenState();
}

class _StudentTimetableScreenState
    extends ConsumerState<StudentTimetableScreen> {
  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  static const _dayLabels = {
    'mon': 'Mon',
    'tue': 'Tue',
    'wed': 'Wed',
    'thu': 'Thu',
    'fri': 'Fri',
    'sat': 'Sat',
  };
  static const _dayFullLabels = {
    'mon': 'Monday',
    'tue': 'Tuesday',
    'wed': 'Wednesday',
    'thu': 'Thursday',
    'fri': 'Friday',
    'sat': 'Saturday',
  };

  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    final weekday = DateTime.now().weekday;
    final todayIndex = weekday - 1;
    _selectedDay = (todayIndex >= 0 && todayIndex < _days.length)
        ? _days[todayIndex]
        : 'mon';
  }

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(studentTimetableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
      ),
      body: timetableAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Failed to load: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text('No timetable available',
                  style: Theme.of(context).textTheme.bodyMedium),
            );
          }
          return _buildTimetable(context, entries);
        },
      ),
    );
  }

  Widget _buildTimetable(
      BuildContext context, List<TimetableEntry> entries) {
    final grouped = <String, List<TimetableEntry>>{};
    for (final day in _days) {
      grouped[day] = entries.where((e) => e.day == day).toList();
    }

    final todayEntries = grouped[_selectedDay] ?? [];
    final now = DateTime.now();
    final isToday = _selectedDay == _days[now.weekday - 1];

    return Column(
      children: [
        _daySelector(context),
        if (todayEntries.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No classes scheduled',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ListView(
                children: [
                  Row(
                    children: [
                      Text(
                        _dayFullLabels[_selectedDay] ?? _selectedDay,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...todayEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _entryCard(context, entry, isToday),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _daySelector(BuildContext context) {
    final now = DateTime.now();
    final todayDay = _days[now.weekday - 1];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: _days.map((day) {
            final isSelected = day == _selectedDay;
            final isToday = day == todayDay;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_dayLabels[day] ?? day),
                    if (isToday) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedDay = day),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.sidebarBg
                        : Colors.grey.shade100,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _entryCard(
      BuildContext context, TimetableEntry entry, bool isToday) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startParts = entry.startTime.split(':');
    final endParts = entry.endTime.split(':');
    final startMin =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final isOngoing = isToday &&
        currentMinutes >= startMin &&
        currentMinutes <= endMin;

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: isOngoing ? AppColors.success : AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          isOngoing
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: AppColors.success, size: 20),
                )
              : Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppColors.primary, size: 18),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subjectName,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${entry.startTime} - ${entry.endTime}${entry.room != null ? ' | ${entry.room}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (entry.teacherName != null)
            Flexible(
              child: Text(
                entry.teacherName!,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
