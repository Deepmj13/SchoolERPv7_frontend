import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/data_table_widget.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final _allSubjectsProvider = FutureProvider<List<Subject>>((ref) {
  return ref.watch(adminRepositoryProvider).getSubjects().timeout(const Duration(seconds: 30));
});

final _allClassesProvider = FutureProvider<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses().timeout(const Duration(seconds: 30));
});

final examsProvider = FutureProvider<List<Exam>>((ref) {
  return ref.watch(adminRepositoryProvider).getExams().timeout(const Duration(seconds: 30));
});

class AdminExamsScreen extends ConsumerWidget {
  const AdminExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        actions: isMobile ? null : [
          CustomButton(
            label: 'Add Exam',
            icon: Icons.add,
            onPressed: () => _showAddDialog(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: examsAsync.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(examsProvider),
        ),
        data: (exams) => isMobile
            ? _buildMobile(context, ref, exams)
            : _buildDesktop(context, ref, exams),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showAddSheet(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, List<Exam> exams) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: DataTableWidget<Exam>(
        searchHint: 'Search exams...',
        items: exams,
        emptyMessage: 'No exams found',
        columns: [
          ColumnDefinition<Exam>(
            header: 'Exam Name',
            sortable: true,
            displayValue: (e) => e.name,
          ),
          ColumnDefinition<Exam>(
            header: 'Date',
            sortable: true,
            displayValue: (e) => e.examDate ?? '-',
            width: 130,
          ),
          ColumnDefinition<Exam>(
            header: 'Classes',
            displayValue: (e) => e.classes.map((c) => c.displayName).join(', '),
            displayWidget: (e) => e.classes.isEmpty
                ? const Text('-', style: TextStyle(color: AppColors.textSecondary))
                : Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: e.classes
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(c.displayName, style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                  ),
          ),
          ColumnDefinition<Exam>(
            header: 'Status',
            sortable: true,
            displayValue: (e) => e.isPublished ? 'Published' : 'Draft',
            displayWidget: (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: e.isPublished
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                e.isPublished ? 'Published' : 'Draft',
                style: TextStyle(
                  fontSize: 12,
                  color: e.isPublished ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ),
        ],
        actionsBuilder: (exam) => PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'subjects') {
              _showSubjectsDialog(context, ref, exam);
            } else if (action == 'marks') {
              context.push('/admin/mark-entry/${exam.id}');
            } else if (action == 'publish') {
              _togglePublish(context, ref, exam);
            } else if (action == 'delete') {
              _confirmDeleteDesktop(context, ref, exam);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'subjects', child: Text('Subjects')),
            const PopupMenuItem(value: 'marks', child: Text('Enter Marks')),
            PopupMenuItem(
              value: 'publish',
              child: Text(exam.isPublished ? 'Unpublish' : 'Publish'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref, List<Exam> exams) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(examsProvider.future),
      child: exams.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No exams found',
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
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return _buildExamCard(context, ref, exam);
              },
            ),
    );
  }

  Widget _buildExamCard(BuildContext context, WidgetRef ref, Exam exam) {
    return Dismissible(
      key: ValueKey(exam.id),
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
      confirmDismiss: (_) => _confirmDeleteMobile(context, ref, exam),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _togglePublish(context, ref, exam),
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
                  child: const Icon(Icons.assignment_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (exam.examDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          exam.examDate!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 13),
                        ),
                      ],
                      if (exam.classes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: exam.classes
                              .map((c) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(c.displayName,
                                        style: const TextStyle(fontSize: 11)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _togglePublish(context, ref, exam),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: exam.isPublished
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          exam.isPublished
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 14,
                          color: exam.isPublished
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exam.isPublished ? 'Published' : 'Draft',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: exam.isPublished
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
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

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final selectedClassIds = <String>{};
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
                  'Add Exam',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Exam Name *',
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateCtrl,
                  decoration: InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    hintText: 'e.g. 2024-12-15',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          dateCtrl.text =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Assign Classes *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                _buildClassSelector(ctx, ref, selectedClassIds, setSheetState),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: saving ? null : () => _submitExam(
                          ctx, ref, nameCtrl, dateCtrl, selectedClassIds,
                          publishNow: false,
                          setSheetState: setSheetState,
                          setState: () => saving = !saving,
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: saving ? null : () => _submitExam(
                          ctx, ref, nameCtrl, dateCtrl, selectedClassIds,
                          publishNow: true,
                          setSheetState: setSheetState,
                          setState: () => saving = !saving,
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Publish'),
                      ),
                    ),
                  ],
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
        const SnackBar(
          content: Text('Exam added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitExam(
    BuildContext ctx,
    WidgetRef ref,
    TextEditingController nameCtrl,
    TextEditingController dateCtrl,
    Set<String> selectedClassIds, {
    required bool publishNow,
    required StateSetter setSheetState,
    required VoidCallback setState,
  }) async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Please enter an exam name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one class'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState();
    setSheetState(() {});
    try {
      final body = <String, dynamic>{
        'name': nameCtrl.text.trim(),
        'class_ids': selectedClassIds.toList(),
        'publish_now': publishNow,
      };
      final date = dateCtrl.text.trim();
      if (date.isNotEmpty) body['exam_date'] = date;
      await ref.read(adminRepositoryProvider).createExam(body);
      ref.invalidate(examsProvider);
      if (ctx.mounted) Navigator.pop(ctx, true);
    } catch (e) {
      if (ctx.mounted) {
        setState();
        setSheetState(() {});
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildClassSelector(
      BuildContext context, WidgetRef ref, Set<String> selectedIds, StateSetter setSheetState) {
    final classesAsync = ref.watch(_allClassesProvider);
    return classesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Failed to load classes: $e', style: const TextStyle(fontSize: 12)),
      data: (classes) {
        if (classes.isEmpty) {
          return const Text('No classes available', style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
        }
        final allSelected = selectedIds.length == classes.length;
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilterChip(
              label: Text(allSelected ? 'Deselect All' : 'Select All', style: const TextStyle(fontSize: 13)),
              selected: allSelected,
              onSelected: (_) {
                setSheetState(() {
                  if (allSelected) {
                    selectedIds.clear();
                  } else {
                    selectedIds.addAll(classes.map((c) => c.id));
                  }
                });
              },
            ),
            ...classes.map((c) {
              final isSelected = selectedIds.contains(c.id);
              return FilterChip(
                label: Text(c.displayName, style: const TextStyle(fontSize: 13)),
                selected: isSelected,
                onSelected: (selected) {
                  setSheetState(() {
                    if (selected) {
                      selectedIds.add(c.id);
                    } else {
                      selectedIds.remove(c.id);
                    }
                  });
                },
              );
            }),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDeleteMobile(
      BuildContext context, WidgetRef ref, Exam exam) async {
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
              'Delete Exam',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete "${exam.name}"? This action cannot be undone.',
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
                        .deleteExam(exam.id);
                    ref.invalidate(examsProvider);
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final selectedClassIds = <String>{};
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Exam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Exam Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    hintText: 'e.g. 2024-12-15',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Assign Classes *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildClassSelector(ctx, ref, selectedClassIds, setDialogState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => _submitExamDialog(
                context, ref, nameCtrl, dateCtrl, selectedClassIds,
                publishNow: false,
              ),
              child: const Text('Save Draft'),
            ),
            CustomButton(
              label: 'Publish',
              onPressed: () => _submitExamDialog(
                context, ref, nameCtrl, dateCtrl, selectedClassIds,
                publishNow: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitExamDialog(
    BuildContext context,
    WidgetRef ref,
    TextEditingController nameCtrl,
    TextEditingController dateCtrl,
    Set<String> selectedClassIds, {
    required bool publishNow,
  }) async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an exam name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one class'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final body = <String, dynamic>{
      'name': name,
      'class_ids': selectedClassIds.toList(),
      'publish_now': publishNow,
    };
    final date = dateCtrl.text.trim();
    if (date.isNotEmpty) body['exam_date'] = date;
    try {
      await ref.read(adminRepositoryProvider).createExam(body);
      ref.invalidate(examsProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publishNow ? 'Exam published successfully' : 'Exam saved as draft'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _togglePublish(
      BuildContext context, WidgetRef ref, Exam exam) async {
    if (!exam.isPublished && exam.classes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assign classes before publishing'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    try {
      await ref
          .read(adminRepositoryProvider)
          .publishExam(exam.id, !exam.isPublished);
      ref.invalidate(examsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                exam.isPublished ? 'Exam unpublished' : 'Exam published'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteDesktop(BuildContext context, WidgetRef ref, Exam exam) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Delete "${exam.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Delete',
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteExam(exam.id);
              ref.invalidate(examsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exam deleted successfully'),
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

  void _showSubjectsDialog(BuildContext context, WidgetRef ref, Exam exam) {
    final subjectsAsync = ref.watch(examSubjectsProvider(exam.id));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Subjects — ${exam.name}'),
        content: SizedBox(
          width: 400,
          child: subjectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (subjects) {
              if (subjects.isEmpty) {
                return const Text('No subjects added yet');
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: subjects
                    .map((s) => ListTile(
                          dense: true,
                          title: Text(s.subjectName),
                          subtitle: Text('Max: ${s.maxMarks.toInt()}${s.passingMarks != null ? ', Pass: ${s.passingMarks!.toInt()}' : ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            onPressed: () async {
                              await ref.read(adminRepositoryProvider).removeExamSubject(exam.id, s.subjectId);
                              ref.invalidate(examSubjectsProvider(exam.id));
                            },
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showAddSubjectDialog(context, ref, exam),
            child: const Text('Add Subject'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, Exam exam) {
    final subjectsAsync = ref.watch(_allSubjectsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject to Exam'),
        content: subjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (allSubjects) {
            return SizedBox(
              width: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allSubjects.length,
                itemBuilder: (_, i) {
                  final s = allSubjects[i];
                  return ListTile(
                    dense: true,
                    title: Text(s.name),
                    onTap: () async {
                      await ref.read(adminRepositoryProvider).addExamSubject(exam.id, {
                        'subject_id': s.id,
                        'max_marks': 100,
                        'passing_marks': 40,
                      });
                      ref.invalidate(examSubjectsProvider(exam.id));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

final examSubjectsProvider = FutureProvider.family<List<ExamSubject>, String>((ref, examId) {
  return ref.read(adminRepositoryProvider).getExamSubjects(examId).timeout(const Duration(seconds: 30));
});
