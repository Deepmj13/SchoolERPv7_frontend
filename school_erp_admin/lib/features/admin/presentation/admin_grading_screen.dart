import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_sheet.dart';

final gradingSystemsProvider = FutureProvider<List<GradingSystem>>((ref) {
  return ref.watch(adminRepositoryProvider).getGradingSystems().timeout(const Duration(seconds: 30));
});

class AdminGradingScreen extends ConsumerWidget {
  const AdminGradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(gradingSystemsProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grading Systems'),
        actions: isMobile ? null : [
          CustomButton(
            label: 'Add System',
            icon: Icons.add,
            onPressed: () => _showAddDialog(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: systemsAsync.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(gradingSystemsProvider),
        ),
        data: (systems) => isMobile
            ? _buildMobile(context, ref, systems)
            : _buildDesktop(context, ref, systems),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showAddSheet(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDesktop(
      BuildContext context, WidgetRef ref, List<GradingSystem> systems) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: systems.isEmpty
          ? Center(
              child: Text('No grading systems defined',
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          : ListView.builder(
              itemCount: systems.length,
              itemBuilder: (_, i) => _buildSystemCard(context, ref, systems[i]),
            ),
    );
  }

  Widget _buildMobile(
      BuildContext context, WidgetRef ref, List<GradingSystem> systems) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(gradingSystemsProvider.future),
      child: systems.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grade_outlined, size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No grading systems defined',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: systems.length,
              itemBuilder: (_, i) => _buildSystemCard(context, ref, systems[i]),
            ),
    );
  }

  Widget _buildSystemCard(
      BuildContext context, WidgetRef ref, GradingSystem system) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.grade, color: AppColors.primary, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(system.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: system.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                system.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      system.isActive ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        children: [
          if (system.ranges.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No grade ranges defined'),
            )
          else
            DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Min %', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Max %', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('GP', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: system.ranges
                  .map((r) => DataRow(cells: [
                        DataCell(Text(r.grade)),
                        DataCell(Text(r.minPercentage.toString())),
                        DataCell(Text(r.maxPercentage.toString())),
                        DataCell(Text(r.gradePoint?.toString() ?? '-')),
                      ]))
                  .toList(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => _showEditDialog(context, ref, system),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref, system),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AdminFormSheet(
        title: 'Add Grading System',
        submitLabel: 'Create',
        fields: [
          FormFieldConfig(
            key: 'name',
            label: 'System Name',
            required: true,
            prefixIcon: const Icon(Icons.grade_outlined),
          ),
        ],
        onSave: (values) async {
          await ref
              .read(adminRepositoryProvider)
              .createGradingSystem({'name': values['name']!.trim()});
          ref.invalidate(gradingSystemsProvider);
        },
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grading system created'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Grading System'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'System Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          CustomButton(
            label: 'Create',
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await ref.read(adminRepositoryProvider).createGradingSystem({'name': name});
                ref.invalidate(gradingSystemsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grading system created'), behavior: SnackBarBehavior.floating),
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

  void _showEditDialog(BuildContext context, WidgetRef ref, GradingSystem system) {
    final nameCtrl = TextEditingController(text: system.name);
    final ranges = system.ranges
        .map((r) => _RangeEntry(
              gradeCtrl: TextEditingController(text: r.grade),
              minCtrl: TextEditingController(text: r.minPercentage.toString()),
              maxCtrl: TextEditingController(text: r.maxPercentage.toString()),
              gpCtrl: TextEditingController(text: r.gradePoint?.toString() ?? ''),
            ))
        .toList();
    if (ranges.isEmpty) ranges.add(_RangeEntry.empty());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Grading System'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'System Name'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Grade Ranges',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...ranges.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                              child: TextField(
                                  controller: r.gradeCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Grade', isDense: true),
                                  style: const TextStyle(fontSize: 13))),
                          const SizedBox(width: 4),
                          Expanded(
                              child: TextField(
                                  controller: r.minCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Min %', isDense: true),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13))),
                          const SizedBox(width: 4),
                          Expanded(
                              child: TextField(
                                  controller: r.maxCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Max %', isDense: true),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13))),
                          const SizedBox(width: 4),
                          Expanded(
                              child: TextField(
                                  controller: r.gpCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'GP', isDense: true),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13))),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18, color: AppColors.error),
                            onPressed: ranges.length > 1
                                ? () {
                                    ranges.removeAt(i);
                                    setDialogState(() {});
                                  }
                                : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Range'),
                    onPressed: () {
                      ranges.add(_RangeEntry.empty());
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            CustomButton(
              label: 'Save',
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  await ref.read(adminRepositoryProvider).updateGradingSystem(
                    system.id,
                    {
                      'name': name,
                      'ranges': ranges
                          .where((r) =>
                              r.gradeCtrl.text.trim().isNotEmpty)
                          .map((r) => {
                                'grade': r.gradeCtrl.text.trim(),
                                'min_percentage': double.parse(
                                    r.minCtrl.text.trim()),
                                'max_percentage': double.parse(
                                    r.maxCtrl.text.trim()),
                                'grade_point': r.gpCtrl.text.trim().isNotEmpty
                                    ? double.parse(r.gpCtrl.text.trim())
                                    : null,
                              })
                          .toList(),
                    },
                  );
                  ref.invalidate(gradingSystemsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Grading system updated'),
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, GradingSystem system) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Grading System'),
        content: Text('Delete "${system.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          CustomButton(
            label: 'Delete',
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).deleteGradingSystem(system.id);
                ref.invalidate(gradingSystemsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grading system deleted'),
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
}

class _RangeEntry {
  final TextEditingController gradeCtrl;
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final TextEditingController gpCtrl;

  _RangeEntry({
    required this.gradeCtrl,
    required this.minCtrl,
    required this.maxCtrl,
    required this.gpCtrl,
  });

  factory _RangeEntry.empty() => _RangeEntry(
        gradeCtrl: TextEditingController(),
        minCtrl: TextEditingController(),
        maxCtrl: TextEditingController(),
        gpCtrl: TextEditingController(),
      );
}
