import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_attendance_provider.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState
    extends ConsumerState<StudentAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentId = ref.read(authStateProvider).user?.studentId ?? '';
      if (studentId.isNotEmpty) {
        ref
            .read(attendancePageProvider.notifier)
            .loadAttendance(studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(attendanceOverviewProvider);
    final recordsState = ref.watch(attendancePageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              overviewAsync.when(
                loading: () =>
                    const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.error)),
                data: (summary) =>
                    _overallCard(context, summary),
              ),
              const SizedBox(height: 24),
              Text('Attendance Records',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (recordsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (recordsState.errorMessage != null)
                Center(
                  child: Text(recordsState.errorMessage!,
                      style:
                          const TextStyle(color: AppColors.error)),
                )
              else if (recordsState.records.isEmpty)
                GlassCard(
                  child: Center(
                    child: Text('No attendance records found',
                        style:
                            Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                _buildRecordsList(context, recordsState.records),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overallCard(
      BuildContext context, AttendanceSummary summary) {
    final percentage = summary.percentage;
    final color = percentage >= 75
        ? AppColors.success
        : percentage >= 60
            ? AppColors.warning
            : AppColors.error;

    return GlassCard(
      child: Row(
        children: [
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Attendance',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _statRow('Present', summary.present, AppColors.success),
                const SizedBox(height: 4),
                _statRow('Absent', summary.absent, AppColors.error),
                const SizedBox(height: 4),
                _statRow(
                    'Total Days', summary.total, AppColors.textPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $value',
            style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildRecordsList(
      BuildContext context, List<AttendanceRecord> records) {
    return Column(
      children: records.map(
        (record) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            child: Row(
              children: [
                Icon(
                  record.status == 'present'
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: record.status == 'present'
                      ? AppColors.success
                      : AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.subjectName ?? 'General',
                        style:
                            Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        record.date,
                        style:
                            Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.status == 'present'
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: record.status == 'present'
                          ? AppColors.success
                          : AppColors.error,
                    ),
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
