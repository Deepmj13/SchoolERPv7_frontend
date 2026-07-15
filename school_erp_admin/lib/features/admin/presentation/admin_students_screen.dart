import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/data_table_widget.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/student_detail_screen.dart';

final studentsProvider = FutureProvider<List<Student>>((ref) {
  return ref.watch(adminRepositoryProvider).getStudents().timeout(const Duration(seconds: 30));
});

class AdminStudentsScreen extends ConsumerWidget {
  const AdminStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final isMobile = context.isMobile;

    return studentsAsync.when(
      loading: () => const ListSkeletonLoader(),
      error: (e, _) => ErrorRetryWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentsProvider),
      ),
      data: (students) => isMobile
          ? _buildMobile(context, ref, students)
          : _buildDesktop(context, ref, students),
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, List<Student> students) {
    final padding = 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          CustomButton(
            label: 'Add Student',
            icon: Icons.add,
            onPressed: () => _showStudentDialog(context, ref, null),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: DataTableWidget<Student>(
          searchHint: 'Search students...',
          items: students,
          emptyMessage: 'No students found',
          columns: [
            ColumnDefinition<Student>(
              header: 'Name',
              sortable: true,
              displayValue: (s) => s.fullName,
            ),
            ColumnDefinition<Student>(
              header: 'Roll No',
              sortable: true,
              displayValue: (s) => s.rollNumber ?? '-',
            ),
            ColumnDefinition<Student>(
              header: 'Class',
              sortable: true,
              displayValue: (s) => s.className ?? '-',
            ),
            ColumnDefinition<Student>(
              header: 'Section',
              sortable: true,
              displayValue: (s) => s.classSection ?? '-',
            ),
            ColumnDefinition<Student>(
              header: 'Contact',
              displayValue: (s) => s.parentPhone ?? '-',
              width: 140,
            ),
            ColumnDefinition<Student>(
              header: 'Status',
              sortable: true,
              displayValue: (s) => s.isActive ? 'Active' : 'Inactive',
              displayWidget: (s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: s.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: s.isActive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ),
          ],
          actionsBuilder: (student) => PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _showStudentDialog(context, ref, student);
              } else if (action == 'delete') {
                _confirmDeleteDesktop(context, ref, student);
              } else if (action == 'toggle_active') {
                _toggleActive(context, ref, student);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle_active',
                child: Text(student.isActive ? 'Deactivate' : 'Activate'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref, List<Student> students) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentsProvider.future),
        child: _buildMobileContent(context, ref, students),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context, WidgetRef ref, List<Student> students) {
    if (students.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64,
                      color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No students found',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSearchBar(context, ref),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _buildStudentCard(context, ref, student);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (query) {
          // Local search handled by filtering in the provider or locally
        },
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, WidgetRef ref, Student student) {
    return Dismissible(
      key: ValueKey(student.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDeleteMobile(context, ref, student),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openStudentDetail(context, ref, student),
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
                  child: Center(
                    child: Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.fullName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: student.isActive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: student.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student.className ?? '-'} ${student.classSection ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                      ),
                      if (student.rollNumber != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Roll No: ${student.rollNumber}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openStudentDetail(BuildContext context, WidgetRef ref, Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(
          student: student,
          onUpdated: () => ref.invalidate(studentsProvider),
        ),
      ),
    );
  }

  Future<void> _showStudentSheet(
      BuildContext context, WidgetRef ref, Student? existing) async {
    final isEdit = existing != null;
    final repo = ref.read(adminRepositoryProvider);
    final classes = await repo.getClasses();
    if (!context.mounted) return;

    final classOptions = classes.map((c) => '${c.name} - ${c.section}').toList();
    final classMap = <String, String>{};
    for (final c in classes) {
      classMap['${c.name} - ${c.section}'] = c.id;
    }

    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final passwordCtrl = TextEditingController(
      text: isEdit ? '' : defaultUserPassword,
    );
    final rollCtrl = TextEditingController(text: existing?.rollNumber ?? '');
    final parentNameCtrl = TextEditingController(text: existing?.parentName ?? '');
    final parentPhoneCtrl = TextEditingController(text: existing?.parentPhone ?? '');
    String? selectedClass;
    if (existing?.classId != null) {
      final match = classes.where((c) => c.id == existing!.classId);
      if (match.isNotEmpty) {
        selectedClass = '${match.first.name} - ${match.first.section}';
      }
    }
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
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
                  isEdit ? 'Edit Student' : 'Add Student',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                if (isEdit)
                  const SizedBox(height: 12)
                else ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class *',
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: classOptions.map((c) => DropdownMenuItem(
                      value: c, child: Text(c))).toList(),
                  onChanged: (v) => setSheetState(() => selectedClass = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rollCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: parentNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Parent Name',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: parentPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Parent Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
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
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                emailCtrl.text.trim().isEmpty ||
                                selectedClass == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill required fields'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final values = <String, dynamic>{
                                'full_name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'roll_number': rollCtrl.text.trim(),
                                'parent_name': parentNameCtrl.text.trim(),
                                'parent_phone': parentPhoneCtrl.text.trim(),
                                'class_id': classMap[selectedClass],
                              };
                              if (isEdit) {
                                await repo.updateStudent(existing.id, values);
                              } else {
                                values['password'] = passwordCtrl.text.trim();
                                await repo.createStudent(values);
                              }
                              ref.invalidate(studentsProvider);
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => saving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEdit ? 'Update' : 'Add Student'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Student updated' : 'Student added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmDeleteMobile(
      BuildContext context, WidgetRef ref, Student student) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Student',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete ${student.fullName}? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    await ref.read(adminRepositoryProvider).deleteStudent(student.id);
                    ref.invalidate(studentsProvider);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  void _showStudentDialog(
      BuildContext context, WidgetRef ref, Student? existing) {
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (_) => FutureBuilder<List<ClassModel>>(
        future: ref.read(adminRepositoryProvider).getClasses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final classes = snapshot.data!;
          final classOptions = classes.map((c) => '${c.name} - ${c.section}').toList();
          final classMap = <String, String>{};
          for (final c in classes) {
            classMap['${c.name} - ${c.section}'] = c.id;
          }
          return AdminFormDialog(
            title: isEdit ? 'Edit Student' : 'Add Student',
            submitLabel: isEdit ? 'Update' : 'Add',
            fields: [
              FormFieldConfig(
                key: 'full_name',
                label: 'Full Name',
                required: true,
                initialValue: existing?.fullName,
              ),
              FormFieldConfig(
                key: 'email',
                label: 'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
                initialValue: existing?.email,
              ),
              if (!isEdit)
                FormFieldConfig(
                  key: 'password',
                  label: 'Password',
                  required: true,
                  obscureText: true,
                  initialValue: defaultUserPassword,
                ),
              FormFieldConfig(
                key: 'class_id',
                label: 'Class',
                required: true,
                isDropdown: true,
                dropdownOptions: classOptions,
                initialValue: () {
                  if (existing == null) return null;
                  final match = classes.where((c) => c.id == existing.classId);
                  return match.isNotEmpty
                      ? '${match.first.name} - ${match.first.section}'
                      : null;
                }(),
              ),
              FormFieldConfig(
                key: 'roll_number',
                label: 'Roll Number',
                initialValue: existing?.rollNumber,
              ),
              FormFieldConfig(
                key: 'parent_name',
                label: 'Parent Name',
                initialValue: existing?.parentName,
              ),
              FormFieldConfig(
                key: 'parent_phone',
                label: 'Parent Phone',
                initialValue: existing?.parentPhone,
                keyboardType: TextInputType.phone,
              ),
            ],
            onSave: (values) async {
              final repo = ref.read(adminRepositoryProvider);
              final classLabel = values.remove('class_id');
              final resolvedClassId = classLabel != null ? classMap[classLabel] : null;
              if (isEdit) {
                final updateValues = Map<String, dynamic>.from(values);
                if (resolvedClassId != null) updateValues['class_id'] = resolvedClassId;
                await repo.updateStudent(existing.id, updateValues);
              } else {
                if (resolvedClassId != null) values['class_id'] = resolvedClassId;
                await repo.createStudent(values);
              }
              ref.invalidate(studentsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Student updated successfully' : 'Student added successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteDesktop(BuildContext context, WidgetRef ref, Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Delete ${student.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Delete',
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteStudent(student.id);
              ref.invalidate(studentsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _toggleActive(BuildContext context, WidgetRef ref, Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student.isActive ? 'Deactivate Student' : 'Activate Student'),
        content: Text('${student.isActive ? 'Deactivate' : 'Activate'} ${student.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: student.isActive ? 'Deactivate' : 'Activate',
            onPressed: () async {
              await ref.read(adminRepositoryProvider).activateStudent(student.id);
              ref.invalidate(studentsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(student.isActive
                        ? 'Student deactivated'
                        : 'Student activated'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}