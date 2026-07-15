import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_sheet.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/data_table_widget.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final subjectsProvider = FutureProvider<List<Subject>>((ref) {
  return ref.watch(adminRepositoryProvider).getSubjects().timeout(const Duration(seconds: 30));
});

final subjectsByClassProvider = FutureProvider<List<ClassSubjects>>((ref) {
  return ref.watch(adminRepositoryProvider).getSubjectsByClass().timeout(const Duration(seconds: 30));
});

class AdminSubjectsScreen extends ConsumerStatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  ConsumerState<AdminSubjectsScreen> createState() => _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends ConsumerState<AdminSubjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final subjectsByClassAsync = ref.watch(subjectsByClassProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Subjects'),
            Tab(text: 'Class Wise'),
          ],
        ),
        actions: isMobile
            ? null
            : [
                CustomButton(
                  label: 'Add Subject',
                  icon: Icons.add,
                  onPressed: () => _showAddDialog(context, ref),
                ),
                const SizedBox(width: 16),
              ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          subjectsAsync.when(
            loading: () => const ListSkeletonLoader(),
            error: (e, _) => ErrorRetryWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(subjectsProvider),
            ),
            data: (subjects) => isMobile
                ? _buildMobile(context, ref, subjects)
                : _buildDesktop(context, ref, subjects),
          ),
          subjectsByClassAsync.when(
            loading: () => const ListSkeletonLoader(),
            error: (e, _) => ErrorRetryWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(subjectsByClassProvider),
            ),
            data: (classes) => isMobile
                ? _buildClassWiseMobile(context, ref, classes)
                : _buildClassWiseDesktop(context, classes),
          ),
        ],
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
      BuildContext context, WidgetRef ref, List<Subject> subjects) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: DataTableWidget<Subject>(
        searchHint: 'Search subjects...',
        items: subjects,
        emptyMessage: 'No subjects found',
        columns: [
          ColumnDefinition<Subject>(
            header: 'Subject Name',
            sortable: true,
            displayValue: (s) => s.name,
          ),
        ],
        actionsBuilder: (_) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMobile(
      BuildContext context, WidgetRef ref, List<Subject> subjects) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(subjectsProvider.future),
      child: subjects.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book_outlined, size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No subjects found',
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
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                          child: const Icon(Icons.book_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildClassWiseDesktop(
      BuildContext context, List<ClassSubjects> classes) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: DataTableWidget<ClassSubjects>(
        searchHint: 'Search classes...',
        items: classes,
        emptyMessage: 'No class-subject assignments found',
        columns: [
          ColumnDefinition<ClassSubjects>(
            header: 'Class',
            sortable: true,
            displayValue: (c) => c.className,
          ),
          ColumnDefinition<ClassSubjects>(
            header: 'Section',
            displayValue: (c) => c.section,
          ),
          ColumnDefinition<ClassSubjects>(
            header: 'Subjects',
            displayValue: (c) => '${c.subjects.length} subject${c.subjects.length == 1 ? '' : 's'}',
          ),
          ColumnDefinition<ClassSubjects>(
            header: 'Subject Names',
            displayValue: (c) => c.subjects.map((s) => s.name).join(', '),
          ),
        ],
        actionsBuilder: (_) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildClassWiseMobile(
      BuildContext context, WidgetRef ref, List<ClassSubjects> classes) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(subjectsByClassProvider.future),
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
                        Icon(Icons.book_outlined, size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No class-subject assignments found',
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
                final classSubjects = classes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  Text(
                                    classSubjects.displayName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${classSubjects.subjects.length} subject${classSubjects.subjects.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (classSubjects.subjects.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: classSubjects.subjects.map((s) =>
                              Chip(
                                label: Text(s.name, style: const TextStyle(fontSize: 13)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
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
        title: 'Add Subject',
        submitLabel: 'Add Subject',
        fields: [
          FormFieldConfig(
            key: 'name',
            label: 'Subject Name',
            required: true,
            prefixIcon: const Icon(Icons.book_outlined),
          ),
        ],
        onSave: (values) async {
          final name = values['name']!.trim();
          await ref.read(adminRepositoryProvider).createSubject(name);
          ref.invalidate(subjectsProvider);
        },
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            hintText: 'e.g. Mathematics',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Add',
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                await ref.read(adminRepositoryProvider).createSubject(name);
                ref.invalidate(subjectsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subject added successfully'),
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
