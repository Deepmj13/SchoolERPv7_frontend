import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';
import 'package:school_erp_admin/features/admin/data/admin_repository.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';

class TeacherDetailScreen extends ConsumerWidget {
  final Teacher teacher;
  final VoidCallback onUpdated;

  const TeacherDetailScreen({
    super.key,
    required this.teacher,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(teacher.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _showEditDialog(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'assignments') {
                _showAssignments(context, ref);
              } else if (action == 'assign_subject') {
                _showAssignSubject(context, ref);
              } else if (action == 'delete') {
                _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'assignments', child: Text('View Assignments')),
              const PopupMenuItem(
                  value: 'assign_subject', child: Text('Assign Subject')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildSection(context, 'Personal Information', [
              _infoRow(context, 'Full Name', teacher.fullName),
              _infoRow(context, 'Email', teacher.email ?? '-'),
              _infoRow(context, 'Phone', teacher.phone ?? '-'),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Account', [
              _infoRow(context, 'Teacher ID', teacher.id),
              _infoRow(context, 'Status',
                  teacher.isActive ? 'Active' : 'Inactive'),
            ]),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.book_outlined),
                    label: const Text('Assign Subject'),
                    onPressed: () => _showAssignSubject(context, ref),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                teacher.fullName.isNotEmpty
                    ? teacher.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  teacher.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: teacher.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    teacher.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: teacher.isActive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> rows) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
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
            initialValue: teacher.fullName,
          ),
          FormFieldConfig(
            key: 'email',
            label: 'Email',
            required: true,
            keyboardType: TextInputType.emailAddress,
            initialValue: teacher.email,
          ),
          FormFieldConfig(
            key: 'phone',
            label: 'Phone',
            initialValue: teacher.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
        onSave: (values) async {
          final repo = ref.read(adminRepositoryProvider);
          await repo.updateTeacher(teacher.id, values);
          onUpdated();
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Teacher updated'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
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
              onUpdated();
              if (context.mounted) {
                Navigator.pop(context);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teacher deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAssignments(BuildContext context, WidgetRef ref) {
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
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
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

  void _showAssignSubject(BuildContext context, WidgetRef ref) {
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
              onUpdated();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subject assigned'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
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