import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/data/teacher_repository.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_attendance_provider.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return TeacherRepository(api);
});

final teacherDashboardProvider =
    FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(teacherRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final teacherId = authState.user?.teacherId ?? '';

  final classes = await repo.getTeacherClasses(teacherId);

  String teacherName = '';
  ClassModel? classTeacherClass;
  try {
    final profile = await repo.getTeacherProfile(teacherId);
    teacherName = profile.fullName;
    classTeacherClass = await repo.getClassTeacherClass(teacherId);
  } catch (_) {}

  final now = DateTime.now();
  final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final todayDay = days[now.weekday - 1];

  List<TimetableEntry> todaySchedule = [];
  for (final tc in classes) {
    try {
      final tt = await repo.getClassTimetable(tc.classId);
      todaySchedule.addAll(tt.where((e) => e.day == todayDay));
    } catch (_) {}
  }

  return DashboardData(
    teacherName: teacherName,
    assignedClasses: classes,
    todaySchedule: todaySchedule,
    classTeacherClass: classTeacherClass,
  );
});

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: dashboardAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text('Failed to load: $e',
                  style: const TextStyle(color: AppColors.error))),
          data: (data) => _buildContent(context, ref, data),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      DashboardData data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.teacherName.isNotEmpty ? 'Welcome, ${data.teacherName}' : 'Welcome',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your day at a glance',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _quickAttendanceCard(context, ref, data.todaySchedule, data.assignedClasses),
          const SizedBox(height: 24),
          if (data.classTeacherClass != null)
            _classTeacherClass(context, data.classTeacherClass!),
          if (data.classTeacherClass != null) const SizedBox(height: 24),
          _todaySchedule(context, data.todaySchedule),
          const SizedBox(height: 12),
          _timetableButton(context),
          const SizedBox(height: 24),
          _quickActions(context),
        ],
      ),
    );
  }
}

Widget _classTeacherClass(BuildContext context, ClassModel cls) {
  return GlassCard(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 4),
              Text('Class Teacher',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cls.display,
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${cls.studentCount} students',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _timetableButton(BuildContext context) {
  return Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () => context.go('/teacher/timetable'),
      icon: const Icon(Icons.schedule_rounded, size: 18),
      label: const Text('View Full Timetable'),
    ),
  );
}

Widget _quickAttendanceCard(
    BuildContext context, WidgetRef ref, List<TimetableEntry> entries,
    List<TeacherClass> assignedClasses) {
  if (entries.isEmpty) return const SizedBox.shrink();

  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;

  TimetableEntry? ongoing;
  TimetableEntry? upcoming;

  for (final e in entries) {
    final startParts = e.startTime.split(':');
    final endParts = e.endTime.split(':');
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (currentMinutes >= startMin && currentMinutes <= endMin) {
      ongoing = e;
      break;
    }
    if (currentMinutes < startMin) {
      if (upcoming == null || startMin < (int.parse(upcoming.startTime.split(':')[0]) * 60 + int.parse(upcoming.startTime.split(':')[1]))) {
        upcoming = e;
      }
    }
  }

  final target = ongoing ?? upcoming;
  if (target == null) return const SizedBox.shrink();

  TeacherClass? matchingClass;
  for (final tc in assignedClasses) {
    if (tc.classId == target.classId && tc.subjectId == target.subjectId) {
      matchingClass = tc;
      break;
    }
  }
  if (matchingClass == null && assignedClasses.isNotEmpty) {
    matchingClass = assignedClasses.firstWhere(
      (tc) => tc.classId == target.classId,
      orElse: () => assignedClasses.first,
    );
  }

  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ongoing != null
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ongoing != null
                  ? Icons.play_circle_filled_rounded
                  : Icons.notifications_active_rounded,
              color: ongoing != null ? AppColors.success : AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ongoing != null ? 'Ongoing Lecture' : 'Upcoming Lecture',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(target.subjectName ?? 'Class',
                    style: Theme.of(context).textTheme.titleMedium),
                if (matchingClass != null)
                  Text(matchingClass.display,
                      style: Theme.of(context).textTheme.bodyMedium),
                Text('${target.startTime} - ${target.endTime}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              final cls = matchingClass ?? TeacherClass(
                classId: target.classId,
                className: '',
                section: '',
                subjectId: target.subjectId,
                subjectName: target.subjectName ?? '',
              );
              ref.read(attendanceStateProvider.notifier).quickSelectClass(cls);
              context.go('/teacher/attendance');
            },
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Mark'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _quickActions(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Quick Actions',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: GlassCard(
              onTap: () => context.go('/teacher/attendance'),
              child: Column(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: AppColors.info, size: 32),
                  const SizedBox(height: 8),
                  Text('Mark Attendance',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              onTap: () => context.go('/teacher/assignments'),
              child: Column(
                children: [
                  Icon(Icons.assignment_rounded,
                      color: AppColors.success, size: 32),
                  const SizedBox(height: 8),
                  Text('Assignments',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: GlassCard(
              onTap: () => context.go('/teacher/announcements'),
              child: Column(
                children: [
                  Icon(Icons.campaign_rounded,
                      color: AppColors.warning, size: 32),
                  const SizedBox(height: 8),
                  Text('Announcements',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _todaySchedule(BuildContext context, List<TimetableEntry> entries) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Today's Schedule",
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (entries.isEmpty)
        GlassCard(
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Text('No classes scheduled for today',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        )
      else
        ...entries.map(
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
        ),
    ],
  );
}


