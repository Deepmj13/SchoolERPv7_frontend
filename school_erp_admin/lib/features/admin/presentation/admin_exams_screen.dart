import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/data_table_widget.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final examsProvider = FutureProvider<List<Exam>>((ref) {
  return ref.watch(adminRepositoryProvider).getExams().timeout(const Duration(seconds: 15));
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
            if (action == 'publish') {
              _togglePublish(context, ref, exam);
            } else if (action == 'delete') {
              _confirmDeleteDesktop(context, ref, exam);
            }
          },
          itemBuilder: (_) => [
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
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please enter an exam name'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final body = <String, dynamic>{
                                'name': nameCtrl.text.trim(),
                              };
                              final date = dateCtrl.text.trim();
                              if (date.isNotEmpty) {
                                body['exam_date'] = date;
                              }
                              await ref
                                  .read(adminRepositoryProvider)
                                  .createExam(body);
                              ref.invalidate(examsProvider);
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
                        : const Text('Add Exam'),
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
        const SnackBar(
          content: Text('Exam added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Exam'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Add',
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final body = <String, dynamic>{'name': name};
              final date = dateCtrl.text.trim();
              if (date.isNotEmpty) body['exam_date'] = date;
              try {
                await ref.read(adminRepositoryProvider).createExam(body);
                ref.invalidate(examsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exam added successfully'),
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
            },
          ),
        ],
      ),
    );
  }

  Future<void> _togglePublish(
      BuildContext context, WidgetRef ref, Exam exam) async {
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
}