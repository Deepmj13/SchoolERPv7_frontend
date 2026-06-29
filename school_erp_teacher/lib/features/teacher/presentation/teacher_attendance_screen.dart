import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/custom_button.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_attendance_provider.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teacherId = ref.read(authStateProvider).user?.teacherId;
      if (teacherId != null) {
        ref.read(attendanceStateProvider.notifier).loadTeacherClasses(teacherId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AttendanceState>(attendanceStateProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(attendanceStateProvider.notifier).clearMessages();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(attendanceStateProvider.notifier).clearMessages();
      }
    });

    final state = ref.watch(attendanceStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _classSelector(state, ref),
            const SizedBox(height: 16),
            _dateSelector(state, ref),
            if (state.selectedClass != null) ...[
              const SizedBox(height: 16),
              if (state.successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(state.successMessage!,
                      style: const TextStyle(color: AppColors.success)),
                ),
                const SizedBox(height: 12),
              ],
              _studentList(state, ref),
              if (state.pastRecords.isNotEmpty) ...[
                const SizedBox(height: 16),
                _pastRecords(context, state),
              ],
              const SizedBox(height: 16),
              CustomButton(
                label: state.pastRecords.isNotEmpty
                    ? 'Update Attendance'
                    : 'Mark Attendance',
                onPressed: () =>
                    ref.read(attendanceStateProvider.notifier).submitAttendance(),
                loading: state.isSubmitting,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _classSelector(AttendanceState state, WidgetRef ref) {
  TeacherClass? initialClass;
  try {
    initialClass = state.selectedClass != null && state.teacherClasses.isNotEmpty
        ? state.teacherClasses.firstWhere(
            (c) =>
                c.classId == state.selectedClass!.classId &&
                c.subjectId == state.selectedClass!.subjectId,
          )
        : null;
  } catch (_) {
    initialClass = null;
  }

  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Class',
            style: Theme.of(ref.context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<TeacherClass>(
          key: ValueKey(
              'class_${state.teacherClasses.length}_${initialClass?.classId ?? ''}_${initialClass?.subjectId ?? ''}'),
          initialValue: initialClass,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.school),
          ),
          hint: const Text('Choose a class'),
          items: state.teacherClasses
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                        '${c.className} - ${c.section} (${c.subjectName})'),
                  ))
              .toList(),
          onChanged: (cls) {
            if (cls != null) {
              ref.read(attendanceStateProvider.notifier).selectClass(cls);
            }
          },
        ),
      ],
    ),
  );
}

Widget _dateSelector(AttendanceState state, WidgetRef ref) {
  return GlassCard(
    child: Row(
      children: [
        const Icon(Icons.calendar_today, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${state.selectedDate.day}/${state.selectedDate.month}/${state.selectedDate.year}',
            style: Theme.of(ref.context).textTheme.titleMedium,
          ),
        ),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: ref.context,
              initialDate: state.selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              ref.read(attendanceStateProvider.notifier).setDate(date);
            }
          },
          child: const Text('Change'),
        ),
      ],
    ),
  );
}

Widget _studentList(AttendanceState state, WidgetRef ref) {
  return Column(
    children: state.students.asMap().entries.map((entry) {
      final i = entry.key;
      final student = entry.value;
      final status = state.statuses[student.id] ?? 'present';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: Theme.of(ref.context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(student.fullName,
                        style: Theme.of(ref.context)
                            .textTheme
                            .titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _statusToggle(status, student.id, ref),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

Widget _statusToggle(
    String currentStatus, String studentId, WidgetRef ref) {
  return SegmentedButton<String>(
    segments: const [
      ButtonSegment(
        value: 'present',
        label: Text('P', style: TextStyle(fontSize: 12)),
        icon: Icon(Icons.check_circle, size: 16),
      ),
      ButtonSegment(
        value: 'absent',
        label: Text('A', style: TextStyle(fontSize: 12)),
        icon: Icon(Icons.cancel, size: 16),
      ),
      ButtonSegment(
        value: 'late',
        label: Text('L', style: TextStyle(fontSize: 12)),
        icon: Icon(Icons.access_time, size: 16),
      ),
    ],
    selected: {currentStatus},
    onSelectionChanged: (selected) {
      ref
          .read(attendanceStateProvider.notifier)
          .setStatus(studentId, selected.first);
    },
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

Widget _pastRecords(BuildContext context, AttendanceState state) {
  if (state.pastRecords.isEmpty) {
    return GlassCard(
      child: Center(
        child: Text('No attendance records found for this date',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Past Records',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...state.pastRecords.map(
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GlassCard(
            child: Row(
              children: [
                Expanded(
                    child: Text(r.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500))),
                _statusBadge(r.status),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _statusBadge(String status) {
  Color color;
  switch (status) {
    case 'present':
      color = AppColors.success;
      break;
    case 'absent':
      color = AppColors.error;
      break;
    case 'late':
      color = AppColors.warning;
      break;
    default:
      color = AppColors.textSecondary;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}
