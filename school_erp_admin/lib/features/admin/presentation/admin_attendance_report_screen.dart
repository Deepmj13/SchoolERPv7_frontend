import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/data_table_widget.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final classesForFilterProvider = FutureProvider<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses().timeout(const Duration(seconds: 30));
});

final attendanceRecordsProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((ref, classId) {
  final date = ref.watch(_attendanceDateProvider);
  if (date == null) return [];
  return ref
      .watch(adminRepositoryProvider)
      .getAttendance(classId, date)
      .timeout(const Duration(seconds: 30));
});

final _attendanceDateProvider = StateProvider<String?>((ref) => null);

class AdminAttendanceReportScreen extends ConsumerStatefulWidget {
  const AdminAttendanceReportScreen({super.key});

  @override
  ConsumerState<AdminAttendanceReportScreen> createState() =>
      _AdminAttendanceReportScreenState();
}

class _AdminAttendanceReportScreenState
    extends ConsumerState<AdminAttendanceReportScreen> {
  String? _selectedClassId;
  DateTime? _selectedDate;

  Future<void> _refresh() async {
    if (_selectedClassId != null && _selectedDate != null) {
      ref.invalidate(attendanceRecordsProvider(_selectedClassId!));
    } else {
      ref.invalidate(classesForFilterProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesForFilterProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load classes: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
        data: (classes) => RefreshIndicator(
          onRefresh: _refresh,
          child: isMobile
              ? _buildMobile(context, classes)
              : _buildDesktop(context, classes),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, List<ClassModel> classes) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Attendance Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Class',
                    prefixIcon: Icon(Icons.filter_list),
                    filled: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...classes.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.display),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _selectedClassId = v;
                    if (v == null) {
                      ref.read(_attendanceDateProvider.notifier).state = null;
                    }
                  }),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                      : 'Select Date',
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                    final formatted =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    ref.read(_attendanceDateProvider.notifier).state = formatted;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _selectedClassId != null && _selectedDate != null
                ? _attendanceDetailDesktop()
                : _classSummaryDesktop(classes),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context, List<ClassModel> classes) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'School Attendance Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: _selectedClassId,
          decoration: const InputDecoration(
            labelText: 'Filter by Class',
            prefixIcon: Icon(Icons.filter_list),
            filled: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Classes'),
            ),
            ...classes.map(
              (c) => DropdownMenuItem<String?>(
                value: c.id,
                child: Text(c.display),
              ),
            ),
          ],
          onChanged: (v) => setState(() {
            _selectedClassId = v;
            if (v == null) {
              ref.read(_attendanceDateProvider.notifier).state = null;
            }
          }),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                final formatted =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                ref.read(_attendanceDateProvider.notifier).state = formatted;
              }
            },
            icon: const Icon(Icons.date_range),
            label: Text(
              _selectedDate != null
                  ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                  : 'Select Date',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._selectedClassId != null && _selectedDate != null
            ? [_attendanceDetailMobile()]
            : classes.map((c) => _buildClassCard(context, c)),
      ],
    );
  }

  Widget _buildClassCard(BuildContext context, ClassModel c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedClassId = c.id;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Section ${c.section}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${c.studentCount}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('students',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classSummaryDesktop(List<ClassModel> classes) {
    return DataTableWidget<ClassModel>(
      items: classes,
      emptyMessage: 'No classes found',
      columns: [
        ColumnDefinition<ClassModel>(
          header: 'Class',
          sortable: true,
          displayValue: (c) => c.name,
        ),
        ColumnDefinition<ClassModel>(
          header: 'Section',
          displayValue: (c) => c.section,
        ),
        ColumnDefinition<ClassModel>(
          header: 'Class Teacher',
          displayValue: (c) => c.classTeacherName ?? 'Unassigned',
        ),
        ColumnDefinition<ClassModel>(
          header: 'Total Students',
          displayValue: (c) => '${c.studentCount}',
          width: 140,
        ),
      ],
    );
  }

  Widget _attendanceDetailDesktop() {
    final recordsAsync = ref.watch(attendanceRecordsProvider(_selectedClassId!));
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fact_check_outlined,
                    size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'No attendance records for this date',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        return DataTableWidget<AttendanceRecord>(
          items: records,
          emptyMessage: 'No attendance records',
          columns: [
            ColumnDefinition<AttendanceRecord>(
              header: 'Student Name',
              sortable: true,
              displayValue: (r) => r.studentName,
            ),
            ColumnDefinition<AttendanceRecord>(
              header: 'Roll No',
              displayValue: (r) => r.rollNumber ?? '-',
              width: 100,
            ),
            ColumnDefinition<AttendanceRecord>(
              header: 'Status',
              displayValue: (r) => r.status,
              displayWidget: (r) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(r.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(r.status),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load attendance: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _attendanceDetailMobile() {
    final recordsAsync = ref.watch(attendanceRecordsProvider(_selectedClassId!));
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fact_check_outlined,
                      size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'No attendance records for this date',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('${records.length} students',
                    style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back'),
                  onPressed: () => setState(() {
                    _selectedClassId = null;
                    ref.read(_attendanceDateProvider.notifier).state = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...records.map((r) => _buildAttendanceCard(r)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text('Failed to load attendance: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord r) {
    final color = _statusColor(r.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                r.status == 'present'
                    ? Icons.check_circle
                    : r.status == 'absent'
                        ? Icons.cancel
                        : Icons.access_time,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.studentName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (r.rollNumber != null) ...[
                    const SizedBox(height: 2),
                    Text('Roll No: ${r.rollNumber}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 13)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}