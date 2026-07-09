import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final _departmentFilterProvider = StateProvider<String?>((ref) => null);

final _staffProvider = FutureProvider.autoDispose<PaginatedResponse<StaffMember>>((ref) {
  final department = ref.watch(_departmentFilterProvider);
  return ref.watch(adminRepositoryProvider).getStaffPage(department: department);
});

final _departmentsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(adminRepositoryProvider).getStaffDepartments();
});

class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  void _load() => ref.invalidate(_staffProvider);

  Future<void> _showStaffForm(StaffMember? existing) async {
    final fullNameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final deptCtrl = TextEditingController(text: existing?.department ?? '');
    final desigCtrl = TextEditingController(text: existing?.designation ?? '');
    final salaryCtrl = TextEditingController(text: existing?.salary?.toString() ?? '');
    final joinDateCtrl = TextEditingController(text: existing?.joiningDate ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    bool isActive = existing?.isActive ?? true;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Staff' : 'Add Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existing == null) ...[
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                ],
                TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department', hintText: 'e.g. Accounts', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: desigCtrl, decoration: const InputDecoration(labelText: 'Designation', hintText: 'e.g. Accountant', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: salaryCtrl, decoration: const InputDecoration(labelText: 'Salary', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: joinDateCtrl, decoration: const InputDecoration(labelText: 'Joining Date (YYYY-MM-DD)', border: OutlineInputBorder())),
                if (existing != null) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() { isActive = v ?? true; }),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (fullNameCtrl.text.trim().isEmpty || (existing == null && emailCtrl.text.trim().isEmpty)) return;
                setDialogState(() { saving = true; });
                try {
                  final repo = ref.read(adminRepositoryProvider);
                  final email = existing?.email ?? emailCtrl.text.trim();
                  final fullName = fullNameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim();
                  final department = deptCtrl.text.trim().isEmpty ? null : deptCtrl.text.trim();
                  final designation = desigCtrl.text.trim().isEmpty ? null : desigCtrl.text.trim();
                  final salaryStr = salaryCtrl.text.trim();
                  final salary = salaryStr.isEmpty ? null : double.tryParse(salaryStr);
                  final joiningDate = joinDateCtrl.text.trim().isEmpty ? null : joinDateCtrl.text.trim();

                  if (existing != null) {
                    final body = StaffMember(
                      id: existing.id,
                      userId: existing.userId,
                      fullName: fullName,
                      email: email,
                      phone: phone,
                      department: department,
                      designation: designation,
                      salary: salary,
                      joiningDate: joiningDate,
                      isActive: isActive,
                    ).toUpdateJson();
                    await repo.updateStaff(existing.id, body);
                  } else {
                    final body = StaffMember(
                      id: '',
                      userId: '',
                      fullName: fullName,
                      email: email,
                      phone: phone,
                      department: department,
                      designation: designation,
                      salary: salary,
                      joiningDate: joiningDate,
                      isActive: true,
                    ).toCreateJson();
                    await repo.createStaff(body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setDialogState(() { saving = false; });
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(existing != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteStaff(StaffMember s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Delete "${s.fullName}"? This will also remove their user account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).deleteStaff(s.id);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(_staffProvider);
    final deptsAsync = ref.watch(_departmentsProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Staff',
              onPressed: () => _showStaffForm(null),
            ),
        ],
      ),
      body: Column(
        children: [
          deptsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (depts) => depts.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('All', null),
                          ...depts.map((d) => _filterChip(d, d)),
                        ],
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: staffAsync.when(
              loading: () => const ListSkeletonLoader(),
              error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: _load),
              data: (result) {
                final staffList = result.items;
                if (staffList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No staff members found', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        CustomButton(label: 'Add Staff', icon: Icons.add, onPressed: () => _showStaffForm(null)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async { _load(); },
                  child: isMobile
                      ? _mobileList(staffList)
                      : _desktopTable(staffList),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(onPressed: () => _showStaffForm(null), child: const Icon(Icons.add))
          : null,
    );
  }

  Widget _filterChip(String label, String? value) {
    final currentFilter = ref.watch(_departmentFilterProvider);
    final selected = currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          ref.read(_departmentFilterProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _desktopTable(List<StaffMember> staff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Department')),
          DataColumn(label: Text('Designation')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('')),
        ],
        rows: staff.map((s) => DataRow(cells: [
          DataCell(Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w500))),
          DataCell(Text(s.email ?? '-')),
          DataCell(Text(s.department ?? '-')),
          DataCell(Text(s.designation ?? '-')),
          DataCell(Text(s.phone ?? '-')),
          DataCell(_statusChip(s.isActive)),
          DataCell(PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') _showStaffForm(s);
              if (action == 'delete') _deleteStaff(s);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          )),
        ])).toList(),
      ),
    );
  }

  Widget _mobileList(List<StaffMember> staff) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final s = staff[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: s.isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
              child: Text(s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?',
                  style: TextStyle(color: s.isActive ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
            ),
            title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              [s.department, s.designation, s.email].where((e) => e != null && e.isNotEmpty).join('  |  '),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!s.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Inactive', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') _showStaffForm(s);
                    if (action == 'delete') _deleteStaff(s);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.success.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(fontSize: 12, color: active ? AppColors.success : Colors.grey, fontWeight: FontWeight.w600),
      ),
    );
  }
}
