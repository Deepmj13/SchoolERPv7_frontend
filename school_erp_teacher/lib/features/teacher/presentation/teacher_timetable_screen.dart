import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_proxy_provider.dart';
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

final teacherTimetableProvider = FutureProvider<List<TimetableEntry>>((ref) async {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  if (teacherId.isEmpty) return Future.value([]);
  final repo = ref.watch(teacherRepositoryProvider);
  final now = DateTime.now();
  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return repo.getTeacherTimetable(teacherId, date: todayStr);
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
    final teacherId = ref.read(authStateProvider).user?.teacherId ?? '';

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
                    final canProxy = isToday && !e.hasProxy && (e.originalTeacherId == null || e.originalTeacherId == teacherId);

                    return GestureDetector(
                      onLongPress: canProxy
                          ? () => _showProxyContextMenu(context, ref, e)
                          : null,
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isOngoing ? AppColors.success : color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(e.subjectName ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            if (e.hasProxy && isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PROXY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
                      ),
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

  void _showProxyContextMenu(BuildContext context, WidgetRef ref, TimetableEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                title: const Text('Assign Proxy'),
                subtitle: Text(
                  '${entry.subjectName ?? "Lecture"} - ${entry.classDisplay}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAssignProxySheet(context, ref, entry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignProxySheet(BuildContext context, WidgetRef ref, TimetableEntry entry) {
    final repo = ref.read(teacherRepositoryProvider);
    String? selectedTeacherId;
    final reasonCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Assign Proxy',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.subjectName ?? "Lecture"} - ${entry.classDisplay}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.startTime} - ${entry.endTime}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: repo.getAvailableTeachers(entry.id),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          snapshot.hasError
                              ? 'Failed to load teachers'
                              : 'No available teachers for this slot',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      );
                    }
                    final teachers = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'Proxy Teacher *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: teachers
                          .map((t) => DropdownMenuItem(
                                value: t['id'] as String,
                                child: Text(t['full_name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => selectedTeacherId = v);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    prefixIcon: Icon(Icons.message),
                    hintText: 'e.g. Personal leave',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (selectedTeacherId != null && !saving)
                        ? () async {
                            setSheetState(() => saving = true);
                            final success = await ref
                                .read(proxyControllerProvider.notifier)
                                .assignProxy(
                                  entry.id,
                                  selectedTeacherId!,
                                  reasonCtrl.text.isNotEmpty
                                      ? reasonCtrl.text
                                      : null,
                                );
                            if (ctx.mounted) {
                              if (success) {
                                ref.invalidate(teacherTimetableProvider);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Proxy request sent'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                setSheetState(() => saving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to assign proxy'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Assign Proxy'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
