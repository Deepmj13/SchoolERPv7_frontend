import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';

class StudentDetailScreen extends ConsumerWidget {
  final Student student;
  final VoidCallback onUpdated;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _showEditDialog(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'toggle_active') {
                _toggleActive(context, ref);
              } else if (action == 'delete') {
                _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle_active',
                child: Text(student.isActive ? 'Deactivate' : 'Activate'),
              ),
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
              _infoRow(context, 'Full Name', student.fullName),
              _infoRow(context, 'Email', student.email ?? '-'),
              _infoRow(context, 'Date of Birth', student.dob ?? '-'),
              _infoRow(context, 'Roll Number', student.rollNumber ?? '-'),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Academic', [
              _infoRow(context, 'Class', student.className ?? '-'),
              _infoRow(context, 'Section', student.classSection ?? '-'),
              _infoRow(context, 'Status',
                  student.isActive ? 'Active' : 'Inactive'),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Parent Details', [
              _infoRow(context, 'Parent Name', student.parentName ?? '-'),
              _infoRow(context, 'Parent Phone', student.parentPhone ?? '-'),
              _infoRow(context, 'Emergency Contact',
                  student.emergencyContact ?? '-'),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Account', [
              _infoRow(context, 'Student ID', student.id),
              _infoRow(context, 'User ID', student.userId),
            ]),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: student.isActive
                          ? AppColors.warning
                          : AppColors.success,
                      side: BorderSide(
                        color: student.isActive
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(student.isActive
                        ? Icons.block
                        : Icons.check_circle_outline),
                    label: Text(student.isActive
                        ? 'Deactivate'
                        : 'Activate'),
                    onPressed: () => _toggleActive(context, ref),
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
                student.fullName.isNotEmpty
                    ? student.fullName[0].toUpperCase()
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
                  student.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: student.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    student.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: student.isActive
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
    final repo = ref.read(adminRepositoryProvider);
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<List<ClassModel>>(
        future: repo.getClasses(),
        builder: (ctx, snapshot) {
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
            title: 'Edit Student',
            submitLabel: 'Update',
            fields: [
              FormFieldConfig(
                key: 'full_name',
                label: 'Full Name',
                required: true,
                initialValue: student.fullName,
              ),
              FormFieldConfig(
                key: 'email',
                label: 'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
                initialValue: student.email,
              ),
              FormFieldConfig(
                key: 'class_id',
                label: 'Class',
                required: true,
                isDropdown: true,
                dropdownOptions: classOptions,
                initialValue: () {
                  if (student.classId == null) return null;
                  final match = classes.where((c) => c.id == student.classId);
                  return match.isNotEmpty
                      ? '${match.first.name} - ${match.first.section}'
                      : null;
                }(),
              ),
              FormFieldConfig(
                key: 'roll_number',
                label: 'Roll Number',
                initialValue: student.rollNumber,
              ),
              FormFieldConfig(
                key: 'parent_name',
                label: 'Parent Name',
                initialValue: student.parentName,
              ),
              FormFieldConfig(
                key: 'parent_phone',
                label: 'Parent Phone',
                initialValue: student.parentPhone,
                keyboardType: TextInputType.phone,
              ),
            ],
            onSave: (values) async {
              final classLabel = values.remove('class_id');
              final resolvedClassId = classLabel != null ? classMap[classLabel] : null;
              final updateValues = Map<String, dynamic>.from(values);
              if (resolvedClassId != null) updateValues['class_id'] = resolvedClassId;
              await repo.updateStudent(student.id, updateValues);
              onUpdated();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student updated'),
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

  void _toggleActive(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminRepositoryProvider).activateStudent(student.id);
      onUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                student.isActive ? 'Student deactivated' : 'Student activated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
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
              onUpdated();
              if (context.mounted) {
                Navigator.pop(context);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student deleted'),
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
}