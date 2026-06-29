import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

final teacherTimetableProvider =
    FutureProvider.family<List<TimetableEntry>, String>((ref, classId) {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getClassTimetable(classId);
});

final teacherClassesForTimetableProvider =
    FutureProvider<List<TeacherClass>>((ref) {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getTeacherClasses(teacherId);
});

class TeacherTimetableScreen extends ConsumerStatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  ConsumerState<TeacherTimetableScreen> createState() =>
      _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState
    extends ConsumerState<TeacherTimetableScreen> {
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesForTimetableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            classesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) =>
                  Text('Failed to load classes: $e',
                      style: const TextStyle(color: AppColors.error)),
              data: (classes) {
                final uniqueClasses = <String, String>{};
                for (final c in classes) {
                  uniqueClasses[c.classId] = c.display;
                }
                return GlassCard(
                  child:                 DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.school),
                      labelText: 'Select Class',
                    ),
                    items: uniqueClasses.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (id) {
                      setState(() => _selectedClassId = id);
                    },
                  ),
                );
              },
            ),
            if (_selectedClassId != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: ref
                    .watch(teacherTimetableProvider(_selectedClassId!))
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Text('Failed to load timetable: $e'),
                      data: (entries) {
                        final now = DateTime.now();
                        final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
                        final todayDay = days[now.weekday - 1];
                        final todayEntries = entries
                            .where((e) => e.day == todayDay)
                            .toList()
                          ..sort((a, b) =>
                              a.startTime.compareTo(b.startTime));
                        return _todayTimetableView(context, todayEntries);
                      },
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _todayTimetableView(
      BuildContext context, List<TimetableEntry> entries) {
    if (entries.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Text('No classes scheduled for today',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.subjectName ?? 'Subject',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      Text('${e.startTime} - ${e.endTime}',
                          style:
                              Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).toList(),
    );
  }
}
