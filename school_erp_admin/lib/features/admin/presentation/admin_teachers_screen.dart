import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/data/admin_repository.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/data_table_widget.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/teacher_detail_screen.dart';

final teachersProvider = FutureProvider<List<Teacher>>((ref) {
  return ref.watch(adminRepositoryProvider).getTeachers().timeout(const Duration(seconds: 30));
});

class AdminTeachersScreen extends ConsumerWidget {
  const AdminTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider);
    final isMobile = context.isMobile;

    return teachersAsync.when(
      loading: () => const ListSkeletonLoader(),
      error: (e, _) => ErrorRetryWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(teachersProvider),
      ),
      data: (teachers) => isMobile
          ? _buildMobile(context, ref, teachers)
          : _buildDesktop(context, ref, teachers),
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, List<Teacher> teachers) {
    final padding = 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          CustomButton(
            label: 'Add Teacher',
            icon: Icons.add,
            onPressed: () { _showTeacherDialog(context, ref, null); },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: DataTableWidget<Teacher>(
          searchHint: 'Search teachers...',
          items: teachers,
          emptyMessage: 'No teachers found',
          columns: [
            ColumnDefinition<Teacher>(
              header: 'Name',
              sortable: true,
              displayValue: (t) => t.fullName,
            ),
            ColumnDefinition<Teacher>(
              header: 'Email',
              sortable: true,
              displayValue: (t) => t.email ?? '-',
            ),
            ColumnDefinition<Teacher>(
              header: 'Phone',
              sortable: true,
              displayValue: (t) => t.phone ?? '-',
              width: 140,
            ),
            ColumnDefinition<Teacher>(
              header: 'Status',
              sortable: true,
              displayValue: (t) => t.isActive ? 'Active' : 'Inactive',
              displayWidget: (t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: t.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.isActive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ),
          ],
          actionsBuilder: (teacher) => PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _showTeacherDialog(context, ref, teacher);
              } else if (action == 'assignments') {
                _showAssignmentsDialog(context, ref, teacher);
              } else if (action == 'assign_subject') {
                _showAssignSubjectDialog(context, ref, teacher);
              } else if (action == 'delete') {
                _confirmDeleteDesktop(context, ref, teacher);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'assignments', child: Text('Assignments')),
              const PopupMenuItem(
                  value: 'assign_subject', child: Text('Assign Subject')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref, List<Teacher> teachers) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(teachersProvider.future),
        child: _buildMobileContent(context, ref, teachers),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeacherSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context, WidgetRef ref, List<Teacher> teachers) {
    if (teachers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, size: 64,
                      color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No teachers found',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return _buildTeacherCard(context, ref, teacher);
      },
    );
  }

  Widget _buildTeacherCard(BuildContext context, WidgetRef ref, Teacher teacher) {
    return Dismissible(
      key: ValueKey(teacher.id),
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
      confirmDismiss: (_) => _confirmDeleteMobile(context, ref, teacher),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openTeacherDetail(context, ref, teacher),
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
                      teacher.fullName.isNotEmpty
                          ? teacher.fullName[0].toUpperCase()
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
                              teacher.fullName,
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
                              color: teacher.isActive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              teacher.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: teacher.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (teacher.email != null)
                        Text(
                          teacher.email!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                        ),
                      if (teacher.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          teacher.phone!,
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

  void _openTeacherDetail(BuildContext context, WidgetRef ref, Teacher teacher) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherDetailScreen(
          teacher: teacher,
          onUpdated: () => ref.invalidate(teachersProvider),
        ),
      ),
    );
  }

  Future<void> _showTeacherSheet(
      BuildContext context, WidgetRef ref, Teacher? existing) async {
    final isEdit = existing != null;
    final repo = ref.read(adminRepositoryProvider);
    final subjects = isEdit ? <Subject>[] : await repo.getSubjects();
    if (!context.mounted) return;

    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final passwordCtrl = TextEditingController(
      text: isEdit ? '' : defaultUserPassword,
    );
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final selectedSubjectIds = <String>{};
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
                  isEdit ? 'Edit Teacher' : 'Add Teacher',
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
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Subjects they can teach',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (subjects.isEmpty)
                    Text('No subjects available',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: subjects.map((s) => FilterChip(
                        label: Text(s.name),
                        selected: selectedSubjectIds.contains(s.id),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedSubjectIds.add(s.id);
                            } else {
                              selectedSubjectIds.remove(s.id);
                            }
                          });
                        },
                      )).toList(),
                    ),
                ],
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
                                emailCtrl.text.trim().isEmpty) {
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
                                'phone': phoneCtrl.text.trim(),
                              };
                              if (isEdit) {
                                await repo.updateTeacher(existing.id, values);
                              } else {
                                values['password'] = passwordCtrl.text.trim();
                                final teacher =
                                    await repo.createTeacher(values);
                                if (selectedSubjectIds.isNotEmpty) {
                                  await repo.setTeacherSubjects(
                                      teacher.id,
                                      selectedSubjectIds.toList());
                                }
                              }
                              ref.invalidate(teachersProvider);
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
                        : Text(isEdit ? 'Update' : 'Add Teacher'),
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
          content: Text(isEdit ? 'Teacher updated' : 'Teacher added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmDeleteMobile(
      BuildContext context, WidgetRef ref, Teacher teacher) async {
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
              'Delete Teacher',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete ${teacher.fullName}? This action cannot be undone.',
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
                    await ref.read(adminRepositoryProvider).deleteTeacher(teacher.id);
                    ref.invalidate(teachersProvider);
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

  Future<void> _showTeacherDialog(
      BuildContext context, WidgetRef ref, Teacher? existing) async {
    final isEdit = existing != null;
    final repo = ref.read(adminRepositoryProvider);

    if (isEdit) {
      showDialog(
        context: context,
        builder: (_) => AdminFormDialog(
          title: 'Edit Teacher',
          submitLabel: 'Update',
          fields: [
            FormFieldConfig(
              key: 'full_name',
              label: 'Full Name',
              required: true,
              initialValue: existing.fullName,
            ),
            FormFieldConfig(
              key: 'email',
              label: 'Email',
              required: true,
              keyboardType: TextInputType.emailAddress,
              initialValue: existing.email,
            ),
            FormFieldConfig(
              key: 'phone',
              label: 'Phone',
              initialValue: existing.phone,
              keyboardType: TextInputType.phone,
            ),
          ],
          onSave: (values) async {
            await repo.updateTeacher(existing.id, values);
            ref.invalidate(teachersProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Teacher updated successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      );
      return;
    }

    final subjects = await repo.getSubjects();
    if (!context.mounted) return;

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: defaultUserPassword);
    final phoneCtrl = TextEditingController();
    final selectedSubjectIds = <String>{};
    var saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Teacher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Subjects they can teach',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (subjects.isEmpty)
                  Text('No subjects available',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: subjects.map((s) => FilterChip(
                      label: Text(s.name),
                      selected: selectedSubjectIds.contains(s.id),
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedSubjectIds.add(s.id);
                          } else {
                            selectedSubjectIds.remove(s.id);
                          }
                        });
                      },
                    )).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CustomButton(
              label: 'Add',
              loading: saving,
              onPressed: nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty ? () async {
                setDialogState(() => saving = true);
                try {
                  final teacher = await repo.createTeacher({
                    'full_name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'password': passwordCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  });
                  if (selectedSubjectIds.isNotEmpty) {
                    await repo.setTeacherSubjects(teacher.id, selectedSubjectIds.toList());
                  }
                  ref.invalidate(teachersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teacher added successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    setDialogState(() => saving = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDesktop(BuildContext context, WidgetRef ref, Teacher teacher) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Delete ${teacher.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Delete',
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteTeacher(teacher.id);
              ref.invalidate(teachersProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teacher deleted successfully'),
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

  void _showAssignSubjectDialog(
      BuildContext context, WidgetRef ref, Teacher teacher) {
    final repo = ref.read(adminRepositoryProvider);
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: Future.wait([repo.getSubjects(), repo.getClasses()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final subjects = snapshot.data![0] as List<Subject>;
          final classes = snapshot.data![1] as List<ClassModel>;
          return _AssignSubjectForm(
            teacher: teacher,
            subjects: subjects,
            classes: classes,
            repo: repo,
            onAssigned: () {
              ref.invalidate(teachersProvider);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subject assigned successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAssignmentsDialog(
      BuildContext context, WidgetRef ref, Teacher teacher) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<List<TeacherAssignment>>(
        future: ref.read(adminRepositoryProvider).getTeacherAssignments(teacher.id),
        builder: (context, snapshot) {
          return AlertDialog(
            title: Text('${teacher.fullName}\'s Classes'),
            content: SizedBox(
              width: double.maxFinite,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : snapshot.hasError
                      ? Text('Error: ${snapshot.error}')
                      : snapshot.hasData && snapshot.data!.isEmpty
                          ? const Center(
                              child: Text('No class assignments'),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: snapshot.data?.length ?? 0,
                              separatorBuilder: (_, _) => const Divider(
                                  height: 1),
                              itemBuilder: (context, index) {
                                final a = snapshot.data![index];
                                return ListTile(
                                  leading: const Icon(Icons.school,
                                      color: AppColors.primary),
                                  title: Text(
                                      '${a.className} - ${a.section}'),
                                  subtitle: Text(a.subjectName),
                                );
                              },
                            ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AssignSubjectForm extends StatefulWidget {
  final Teacher teacher;
  final List<Subject> subjects;
  final List<ClassModel> classes;
  final AdminRepository repo;
  final VoidCallback onAssigned;

  const _AssignSubjectForm({
    required this.teacher,
    required this.subjects,
    required this.classes,
    required this.repo,
    required this.onAssigned,
  });

  @override
  State<_AssignSubjectForm> createState() => _AssignSubjectFormState();
}

class _AssignSubjectFormState extends State<_AssignSubjectForm> {
  Subject? _selectedSubject;
  ClassModel? _selectedClass;
  bool _saving = false;

  Future<void> _handleAssign() async {
    if (_selectedSubject == null || _selectedClass == null) return;
    setState(() => _saving = true);
    try {
      await widget.repo.assignSubjectToTeacher(
        _selectedSubject!.id,
        widget.teacher.id,
        _selectedClass!.id,
      );
      widget.onAssigned();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Subject to ${widget.teacher.fullName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Subject>(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.book),
                ),
                items: widget.subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSubject = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ClassModel>(
                initialValue: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  prefixIcon: Icon(Icons.school),
                ),
                items: widget.classes
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text('${c.name} - ${c.section}')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedClass = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          label: 'Assign',
          loading: _saving,
          onPressed: _selectedSubject != null && _selectedClass != null
              ? _handleAssign
              : null,
        ),
      ],
    );
  }
}