import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

const _dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const _dayLabels = {
  'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
  'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday',
};
const _subjectColors = [
  Color(0xFF4F6EF7), Color(0xFF22C55E), Color(0xFFF59E0B),
  Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4),
  Color(0xFFEC4899), Color(0xFF84CC16),
];

Color _colorForSubject(String subjectId) {
  return _subjectColors[subjectId.hashCode.abs() % _subjectColors.length];
}

final teacherTimetableProvider = FutureProvider<List<TimetableEntry>>((ref) {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  if (teacherId.isEmpty) return Future.value([]);
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getTeacherTimetable(teacherId);
});

class TeacherTimetableScreen extends ConsumerStatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  ConsumerState<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends ConsumerState<TeacherTimetableScreen> {
  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(teacherTimetableProvider);
    final now = DateTime.now();
    final todayDay = _dayOrder[now.weekday - 1 < _dayOrder.length ? now.weekday - 1 : 0];

    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: timetableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load timetable: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('No timetable entries found', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            );
          }
          return _buildWeeklyView(context, entries, todayDay);
        },
      ),
    );
  }

  Widget _buildWeeklyView(BuildContext context, List<TimetableEntry> entries, String todayDay) {
    final grouped = <String, List<TimetableEntry>>{};
    for (final d in _dayOrder) { grouped[d] = []; }
    for (final e in entries) {
      grouped[e.day]?.add(e);
    }
    for (final d in _dayOrder) {
      grouped[d]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _dayOrder.map((day) {
          final dayEntries = grouped[day]!;
          if (dayEntries.isEmpty) return const SizedBox.shrink();
          final isToday = day == todayDay;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          _dayLabels[day] ?? day,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isToday ? AppColors.primary : null,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Today', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...dayEntries.map((e) {
                    final color = _colorForSubject(e.subjectId);
                    final startParts = e.startTime.split(':');
                    final endParts = e.endTime.split(':');
                    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
                    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
                    final isOngoing = isToday && currentMinutes >= startMin && currentMinutes <= endMin;

                    return ListTile(
                      leading: Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isOngoing ? AppColors.success : color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(e.subjectName ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        '${e.startTime} - ${e.endTime}  |  ${e.classDisplay}${e.room != null && e.room!.isNotEmpty ? '  Room: ${e.room}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isOngoing
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, size: 14, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text('Ongoing', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
