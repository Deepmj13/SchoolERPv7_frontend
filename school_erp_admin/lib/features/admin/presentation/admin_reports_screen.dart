import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_erp_admin/core/api/endpoints.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

class _ReportType {
  final String id;
  final String label;
  final IconData icon;
  final String endpoint;
  final bool hasClassFilter;
  final bool hasDateRange;
  final bool hasGroupBy;

  const _ReportType({
    required this.id,
    required this.label,
    required this.icon,
    required this.endpoint,
    this.hasClassFilter = false,
    this.hasDateRange = false,
    this.hasGroupBy = false,
  });
}

const _reportTypes = [
  _ReportType(
    id: 'student-strength',
    label: 'Student Strength',
    icon: Icons.people_rounded,
    endpoint: Endpoints.reportStudentStrength,
    hasClassFilter: true,
  ),
  _ReportType(
    id: 'attendance',
    label: 'Attendance Report',
    icon: Icons.trending_up_rounded,
    endpoint: Endpoints.reportAttendance,
    hasClassFilter: true,
    hasDateRange: true,
    hasGroupBy: true,
  ),
  _ReportType(
    id: 'fee-collection',
    label: 'Fee Collection',
    icon: Icons.payments_rounded,
    endpoint: Endpoints.reportFeeCollection,
    hasClassFilter: true,
    hasDateRange: true,
  ),
  _ReportType(
    id: 'teacher-workload',
    label: 'Teacher Workload',
    icon: Icons.person_rounded,
    endpoint: Endpoints.reportTeacherWorkload,
    hasClassFilter: true,
  ),
  _ReportType(
    id: 'admissions',
    label: 'Admissions',
    icon: Icons.person_add_rounded,
    endpoint: Endpoints.reportAdmissions,
    hasClassFilter: true,
    hasDateRange: true,
  ),
];

final classesForFilterProvider = FutureProvider<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses().timeout(const Duration(seconds: 15));
});

final reportDataProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, endpoint) {
  final state = ref.watch(_reportFilterStateProvider);
  return ref.watch(adminRepositoryProvider).getReportJson(
    endpoint,
    classId: state.classId,
    startDate: state.startDate,
    endDate: state.endDate,
    groupBy: state.groupBy,
  ).timeout(const Duration(seconds: 30));
});

class _ReportFilterState {
  final String? classId;
  final String? startDate;
  final String? endDate;
  final String? groupBy;

  const _ReportFilterState({this.classId, this.startDate, this.endDate, this.groupBy});

  _ReportFilterState copyWith({String? classId, String? startDate, String? endDate, String? groupBy}) {
    return _ReportFilterState(
      classId: classId ?? this.classId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      groupBy: groupBy ?? this.groupBy,
    );
  }
}

final _reportFilterStateProvider = StateProvider<_ReportFilterState>((ref) => const _ReportFilterState(
  groupBy: 'student',
));

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String? _selectedReportId;

  _ReportType? get _selectedType =>
      _reportTypes.firstWhere((r) => r.id == _selectedReportId);

  Future<void> _export(String format) async {
    final type = _selectedType;
    if (type == null) return;
    final state = ref.read(_reportFilterStateProvider);

    try {
      final bytes = await ref.read(adminRepositoryProvider).downloadReport(
        type.endpoint,
        classId: state.classId,
        startDate: state.startDate,
        endDate: state.endDate,
        groupBy: state.groupBy,
        format: format,
      );

      final dir = await getApplicationDocumentsDirectory();
      final ext = format == 'excel' ? 'xlsx' : 'pdf';
      final file = File('${dir.path}/${type.id}_report.$ext');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${format.toUpperCase()} saved to ${file.path}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final classesAsync = ref.watch(classesForFilterProvider);
    final filterState = ref.watch(_reportFilterStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          _buildReportTypeSelector(isMobile),
          if (_selectedReportId != null) ...[
            _buildFilterBar(isMobile, classesAsync, filterState),
            Expanded(child: _buildReportContent()),
          ],
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _reportTypes.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ReportChip(
                    icon: t.icon,
                    label: t.label,
                    selected: _selectedReportId == t.id,
                    onTap: () => setState(() {
                      _selectedReportId = t.id;
                      ref.invalidate(reportDataProvider(t.endpoint));
                    }),
                  ),
                )).toList(),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reportTypes.map((t) => _ReportChip(
                icon: t.icon,
                label: t.label,
                selected: _selectedReportId == t.id,
                onTap: () => setState(() {
                  _selectedReportId = t.id;
                  ref.invalidate(reportDataProvider(t.endpoint));
                }),
              )).toList(),
            ),
    );
  }

  Widget _buildFilterBar(
    bool isMobile,
    AsyncValue<List<ClassModel>> classesAsync,
    _ReportFilterState filterState,
  ) {
    final type = _selectedType;
    if (type == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (type.hasClassFilter)
                  _FilterDropdown<ClassModel>(
                    hint: 'All Classes',
                    itemsAsync: classesAsync,
                    selectedId: filterState.classId,
                    displayName: (c) => '${c.name}${c.section.isNotEmpty ? ' - ${c.section}' : ''}',
                    onChanged: (id) {
                      ref.read(_reportFilterStateProvider.notifier).state =
                          filterState.copyWith(classId: id);
                      ref.invalidate(reportDataProvider(type.endpoint));
                    },
                  ),
                if (type.hasDateRange) ...[
                  const SizedBox(width: 8),
                  _DatePickerButton(
                    label: 'Start',
                    value: filterState.startDate,
                    onPicked: (d) {
                      ref.read(_reportFilterStateProvider.notifier).state =
                          filterState.copyWith(startDate: d);
                      ref.invalidate(reportDataProvider(type.endpoint));
                    },
                  ),
                  const SizedBox(width: 8),
                  _DatePickerButton(
                    label: 'End',
                    value: filterState.endDate,
                    onPicked: (d) {
                      ref.read(_reportFilterStateProvider.notifier).state =
                          filterState.copyWith(endDate: d);
                      ref.invalidate(reportDataProvider(type.endpoint));
                    },
                  ),
                ],
                if (type.hasGroupBy) ...[
                  const SizedBox(width: 8),
                  _FilterDropdown<String>(
                    hint: 'Student',
                    itemsAsync: AsyncValue.data(['student', 'class']),
                    selectedId: filterState.groupBy,
                    displayName: (v) => v == 'class' ? 'By Class' : 'By Student',
                    onChanged: (id) {
                      ref.read(_reportFilterStateProvider.notifier).state =
                          filterState.copyWith(groupBy: id);
                      ref.invalidate(reportDataProvider(type.endpoint));
                    },
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.file_download, size: 20),
                  tooltip: 'Download Excel',
                  onPressed: () => _export('excel'),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  tooltip: 'Download PDF',
                  onPressed: () => _export('pdf'),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    final type = _selectedType;
    if (type == null) return const SizedBox.shrink();

    final dataAsync = ref.watch(reportDataProvider(type.endpoint));

    return dataAsync.when(
      loading: () => const ListSkeletonLoader(),
      error: (e, _) => ErrorRetryWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(reportDataProvider(type.endpoint)),
      ),
      data: (data) {
        final rows = data['data'] as List? ?? [];
        if (rows.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No data found', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }
        return _buildTable(type.id, rows);
      },
    );
  }

  Widget _buildTable(String reportId, List rows) {
    final flatRows = rows.map((r) => r as Map<String, dynamic>).toList();

    switch (reportId) {
      case 'student-strength':
        return _GenericTable(
          rows: flatRows,
          columns: [
            _RCol('Class', 'class_name'),
            _RCol('Section', 'section'),
            _RCol('Total', 'total_students'),
            _RCol('Active', 'active_students'),
            _RCol('Inactive', 'inactive_students'),
          ],
        );
      case 'attendance':
        final groupBy = ref.read(_reportFilterStateProvider).groupBy;
        if (groupBy == 'class') {
          return _GenericTable(
            rows: flatRows,
            columns: [
              _RCol('Class', 'class_name'),
              _RCol('Section', 'section'),
              _RCol('Total', 'total_records'),
              _RCol('Present', 'present_count'),
              _RCol('Absent', 'absent_count'),
              _RCol('Late', 'late_count'),
              _RCol('%', 'attendance_percentage'),
            ],
          );
        }
        return _GenericTable(
          rows: flatRows,
          columns: [
            _RCol('Student', 'student_name'),
            _RCol('Roll No', 'roll_number'),
            _RCol('Class', 'class_name'),
            _RCol('Section', 'section'),
            _RCol('Total', 'total_records'),
            _RCol('Present', 'present_count'),
            _RCol('Absent', 'absent_count'),
            _RCol('Late', 'late_count'),
            _RCol('%', 'attendance_percentage'),
          ],
        );
      case 'fee-collection':
        return _GenericTable(
          rows: flatRows,
          columns: [
            _RCol('Class', 'class_name'),
            _RCol('Section', 'section'),
            _RCol('Fee Type', 'fee_type'),
            _RCol('Payments', 'payment_count'),
            _RCol('Collected', 'total_collected'),
          ],
        );
      case 'teacher-workload':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: flatRows.length,
            itemBuilder: (context, i) {
              final t = flatRows[i];
              final assignments = t['assignments'] as List? ?? [];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(t['teacher_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${t['total_classes']} classes, ${t['total_subjects']} subjects'),
                  children: assignments.map((a) => ListTile(
                    dense: true,
                    title: Text('${a['class_name']} - ${a['section']}'),
                    subtitle: Text(a['subject_name'] ?? ''),
                    leading: const Icon(Icons.book_outlined, size: 18),
                  )).toList(),
                ),
              );
            },
          ),
        );
      case 'admissions':
        return _GenericTable(
          rows: flatRows,
          columns: [
            _RCol('Date', 'date'),
            _RCol('Admissions', 'count'),
          ],
        );
      default:
        return _GenericTable(
          rows: flatRows,
          columns: flatRows.isNotEmpty
              ? flatRows.first.keys.map((k) => _RCol(k, k)).toList()
              : [],
        );
    }
  }
}

class _RCol {
  final String header;
  final String key;
  const _RCol(this.header, this.key);
}

class _GenericTable extends ConsumerWidget {
  final List<Map<String, dynamic>> rows;
  final List<_RCol> columns;

  const _GenericTable({required this.rows, required this.columns});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;
    if (isMobile) {
      return RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          itemBuilder: (ctx, i) {
            final row = rows[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns.map((col) {
                    final val = row[col.key]?.toString() ?? '-';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(col.header, style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary,
                            )),
                          ),
                          Expanded(child: Text(val, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
          columns: columns.map((c) => DataColumn(
            label: Text(c.header, style: const TextStyle(fontWeight: FontWeight.w600)),
          )).toList(),
          rows: rows.map((row) => DataRow(
            cells: columns.map((c) => DataCell(Text(row[c.key]?.toString() ?? '-'))).toList(),
          )).toList(),
        ),
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : AppColors.primary),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
    );
  }
}

class _FilterDropdown<T> extends ConsumerWidget {
  final String hint;
  final AsyncValue<List<T>> itemsAsync;
  final String? selectedId;
  final String Function(T) displayName;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.itemsAsync,
    required this.selectedId,
    required this.displayName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return itemsAsync.when(
      loading: () => const SizedBox(width: 140, child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        return SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            initialValue: selectedId,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(hint)),
              ...items.map((item) {
                final id = item is String ? item : (item as dynamic).id;
                return DropdownMenuItem(value: id, child: Text(displayName(item)));
              }),
            ],
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onPicked;

  const _DatePickerButton({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null ? DateTime.parse(value!) : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onPicked(picked.toIso8601String().split('T')[0]);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              value ?? label,
              style: TextStyle(fontSize: 13, color: value != null ? null : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
