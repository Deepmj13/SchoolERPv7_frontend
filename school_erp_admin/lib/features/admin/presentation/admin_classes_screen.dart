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

final classesProvider = FutureProvider<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses().timeout(const Duration(seconds: 30));
});

class AdminClassesScreen extends ConsumerWidget {
  const AdminClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        actions: isMobile
            ? null
            : [
                CustomButton(
                  label: 'Add Class',
                  icon: Icons.add,
                  onPressed: () => _showClassDialog(context, ref, null),
                ),
                const SizedBox(width: 16),
              ],
      ),
      body: classesAsync.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(classesProvider),
        ),
        data: (classes) => isMobile
            ? _buildMobile(context, ref, classes)
            : _buildDesktop(context, ref, classes),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showClassSheet(context, ref, null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, List<ClassModel> classes) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: DataTableWidget<ClassModel>(
        searchHint: 'Search classes...',
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
            sortable: true,
            displayValue: (c) => c.section,
          ),
          ColumnDefinition<ClassModel>(
            header: 'Class Teacher',
            sortable: true,
            displayValue: (c) => c.classTeacherName ?? 'Unassigned',
          ),
          ColumnDefinition<ClassModel>(
            header: 'Students',
            sortable: true,
            displayValue: (c) => '${c.studentCount}',
            width: 100,
          ),
        ],
        actionsBuilder: (cls) => PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') {
              _showClassDialog(context, ref, cls);
            } else if (action == 'delete') {
              _confirmDeleteDesktop(context, ref, cls);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref, List<ClassModel> classes) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(classesProvider.future),
      child: classes.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined, size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No classes found',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final cls = classes[index];
                return _buildClassCard(context, ref, cls);
              },
            ),
    );
  }

  Widget _buildClassCard(BuildContext context, WidgetRef ref, ClassModel cls) {
    return Dismissible(
      key: ValueKey(cls.id),
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
      confirmDismiss: (_) => _confirmDeleteMobile(context, ref, cls),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showClassSheet(context, ref, cls),
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
                      cls.name.isNotEmpty ? cls.name[0].toUpperCase() : '?',
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
                      Text(
                        '${cls.name} - ${cls.section}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cls.classTeacherName ?? 'No teacher assigned',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cls.studentCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showClassSheet(
      BuildContext context, WidgetRef ref, ClassModel? existing) async {
    final isEdit = existing != null;
    final repo = ref.read(adminRepositoryProvider);
    final teachers = await repo.getTeachers();
    if (!context.mounted) return;

    final activeTeachers = teachers.where((t) => t.isActive).toList();
    final teacherOptions = activeTeachers.map((t) => t.fullName).toList();
    final teacherMap = <String, String>{};
    for (final t in activeTeachers) {
      teacherMap[t.fullName] = t.userId;
    }

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final sectionCtrl = TextEditingController(text: existing?.section ?? '');
    String? selectedTeacher = existing?.classTeacherName;
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
                  isEdit ? 'Edit Class' : 'Add Class',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Class Name *',
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sectionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Section *',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),
                if (teacherOptions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedTeacher,
                    decoration: const InputDecoration(
                      labelText: 'Class Teacher',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('None')),
                      ...teacherOptions.map((t) =>
                          DropdownMenuItem(value: t, child: Text(t))),
                    ],
                    onChanged: (v) =>
                        setSheetState(() => selectedTeacher = v),
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
                                sectionCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please fill required fields'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final body = <String, dynamic>{
                                'name': nameCtrl.text.trim(),
                                'section': sectionCtrl.text.trim(),
                                'class_teacher_id': selectedTeacher != null
                                    ? teacherMap[selectedTeacher]
                                    : null,
                              };
                              if (isEdit) {
                                await repo.updateClass(existing.id, body);
                              } else {
                                await repo.createClass(body);
                              }
                              ref.invalidate(classesProvider);
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
                        : Text(isEdit ? 'Update' : 'Add Class'),
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
          content:
              Text(isEdit ? 'Class updated' : 'Class added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmDeleteMobile(
      BuildContext context, WidgetRef ref, ClassModel cls) async {
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
              'Delete Class',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete ${cls.display}? This action cannot be undone.',
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
                    await ref
                        .read(adminRepositoryProvider)
                        .deleteClass(cls.id);
                    ref.invalidate(classesProvider);
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

  Future<void> _showClassDialog(
      BuildContext context, WidgetRef ref, ClassModel? existing) async {
    final isEdit = existing != null;

    final teachers = await ref.read(adminRepositoryProvider).getTeachers();
    final teacherOptions = teachers
        .where((t) => t.isActive)
        .map((t) => t.fullName)
        .toList();
    final teacherMap = <String, String>{};
    for (final t in teachers.where((t) => t.isActive)) {
      teacherMap[t.fullName] = t.userId;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AdminFormDialog(
        title: isEdit ? 'Edit Class' : 'Add Class',
        submitLabel: isEdit ? 'Update' : 'Add',
        fields: [
          FormFieldConfig(
            key: 'name',
            label: 'Class Name',
            required: true,
            initialValue: existing?.name,
          ),
          FormFieldConfig(
            key: 'section',
            label: 'Section',
            required: true,
            initialValue: existing?.section,
          ),
          if (teacherOptions.isNotEmpty)
            FormFieldConfig(
              key: 'class_teacher_id',
              label: 'Class Teacher',
              isDropdown: true,
              dropdownOptions: [
                'None',
                ...teacherOptions,
              ],
              initialValue: existing?.classTeacherName ?? 'None',
            ),
        ],
        onSave: (values) async {
          final repo = ref.read(adminRepositoryProvider);
          final teacherName = values.remove('class_teacher_id');
          final resolvedTeacherId =
              teacherName != null && teacherName != 'None'
                  ? teacherMap[teacherName]
                  : null;
          final body = Map<String, dynamic>.from(values);
          if (resolvedTeacherId != null) {
            body['class_teacher_id'] = resolvedTeacherId;
          } else {
            body['class_teacher_id'] = null;
          }
          if (isEdit) {
            await repo.updateClass(existing.id, body);
          } else {
            await repo.createClass(body);
          }
          ref.invalidate(classesProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEdit ? 'Class updated successfully' : 'Class added successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteDesktop(BuildContext context, WidgetRef ref, ClassModel cls) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete ${cls.display}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Delete',
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteClass(cls.id);
              ref.invalidate(classesProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Class deleted successfully'),
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