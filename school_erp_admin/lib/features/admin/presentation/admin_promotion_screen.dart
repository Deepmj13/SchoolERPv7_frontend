import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final classesForFilterProvider = FutureProvider<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses().timeout(const Duration(seconds: 15));
});

final classStudentsProvider = FutureProvider.family<List<Student>, String>((ref, classId) {
  return ref.watch(adminRepositoryProvider).getClassStudents(classId).timeout(const Duration(seconds: 15));
});

class AdminPromotionScreen extends ConsumerStatefulWidget {
  const AdminPromotionScreen({super.key});

  @override
  ConsumerState<AdminPromotionScreen> createState() => _AdminPromotionScreenState();
}

class _AdminPromotionScreenState extends ConsumerState<AdminPromotionScreen> {
  String? _fromClassId;
  String? _toClassId;
  final _academicYearCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isPromoting = false;
  String? _resultMessage;

  @override
  void dispose() {
    _academicYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _promote() async {
    if (_fromClassId == null || _toClassId == null || _selectedIds.isEmpty) return;
    final year = _academicYearCtrl.text.trim();
    if (year.isEmpty) return;

    setState(() {
      _isPromoting = true;
      _resultMessage = null;
    });

    try {
      final result = await ref.read(adminRepositoryProvider).promoteStudents({
        'from_class_id': _fromClassId,
        'to_class_id': _toClassId,
        'academic_year': year,
        'student_ids': _selectedIds.toList(),
      });
      setState(() {
        _resultMessage = result['message'] as String? ?? 'Promotion successful';
        _selectedIds.clear();
      });
      ref.invalidate(classStudentsProvider(_fromClassId!));
    } catch (e) {
      setState(() => _resultMessage = 'Failed: $e');
    } finally {
      setState(() => _isPromoting = false);
    }
  }

  void _selectAll(List<Student> students) {
    setState(() {
      if (_selectedIds.length == students.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(students.map((s) => s.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesForFilterProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(title: const Text('Promote Students')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 200,
                      child: classesAsync.when(
                        data: (classes) => DropdownButtonFormField<String>(
                          initialValue: _fromClassId,
                          decoration: const InputDecoration(
                            labelText: 'From Class',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: classes.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name}${c.section.isNotEmpty ? ' - ${c.section}' : ''}'),
                          )).toList(),
                          onChanged: (id) => setState(() {
                            _fromClassId = id;
                            _selectedIds.clear();
                            _resultMessage = null;
                          }),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        loading: () => const SizedBox(width: 200, child: LinearProgressIndicator()),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: classesAsync.when(
                        data: (classes) => DropdownButtonFormField<String>(
                          initialValue: _toClassId,
                          decoration: const InputDecoration(
                            labelText: 'To Class',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: classes
                              .where((c) => c.id != _fromClassId)
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.name}${c.section.isNotEmpty ? ' - ${c.section}' : ''}'),
                                  ))
                              .toList(),
                          onChanged: (id) => setState(() {
                            _toClassId = id;
                            _resultMessage = null;
                          }),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        loading: () => const SizedBox(width: 200, child: LinearProgressIndicator()),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _academicYearCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          hintText: 'e.g. 2024-25',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_resultMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _resultMessage!.startsWith('Failed')
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _resultMessage!.startsWith('Failed')
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: _resultMessage!.startsWith('Failed')
                              ? AppColors.error
                              : AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_resultMessage!,
                              style: TextStyle(
                                color: _resultMessage!.startsWith('Failed')
                                    ? AppColors.error
                                    : AppColors.success,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_fromClassId != null)
            Expanded(child: _buildStudentList(isMobile))
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64,
                        color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Select a class to view students',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _fromClassId != null && _selectedIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  label: 'Promote ${_selectedIds.length} Student${_selectedIds.length == 1 ? '' : 's'}',
                  icon: Icons.arrow_forward,
                  onPressed: _isPromoting ? null : _promote,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStudentList(bool isMobile) {
    final studentsAsync = ref.watch(classStudentsProvider(_fromClassId!));

    return studentsAsync.when(
      loading: () => const ListSkeletonLoader(),
      error: (e, _) => ErrorRetryWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(classStudentsProvider(_fromClassId!)),
      ),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64,
                    color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No students in this class',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('${students.length} students',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _selectAll(students),
                    child: Text(
                      _selectedIds.length == students.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isMobile
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final s = students[i];
                        final selected = _selectedIds.contains(s.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: CheckboxListTile(
                            value: selected,
                            onChanged: (val) => setState(() {
                              if (val == true) {
                                _selectedIds.add(s.id);
                              } else {
                                _selectedIds.remove(s.id);
                              }
                            }),
                            title: Text(s.fullName,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('Roll: ${s.rollNumber ?? '-'}'),
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                            AppColors.primary.withValues(alpha: 0.08)),
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('Roll No',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Student Name',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                        rows: students.map((s) {
                          final selected = _selectedIds.contains(s.id);
                          return DataRow(
                            selected: selected,
                            onSelectChanged: (val) => setState(() {
                              if (val == true) {
                                _selectedIds.add(s.id);
                              } else {
                                _selectedIds.remove(s.id);
                              }
                            }),
                            cells: [
                              DataCell(selected
                                  ? const Icon(Icons.check_circle,
                                        color: AppColors.primary, size: 20)
                                  : const Icon(Icons.radio_button_unchecked,
                                        size: 20)),
                              DataCell(Text(s.rollNumber ?? '-')),
                              DataCell(Text(s.fullName)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
