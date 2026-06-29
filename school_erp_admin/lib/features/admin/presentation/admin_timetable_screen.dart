import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/timetable_provider.dart';

final _classesProvider = FutureProvider<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses().timeout(const Duration(seconds: 15));
});

class AdminTimetableScreen extends ConsumerStatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  ConsumerState<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen> {
  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(_classesProvider);
    final entriesAsync = ref.watch(timetableEntriesProvider);
    final selectedClass = ref.watch(selectedClassProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: classesAsync.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_classesProvider),
        ),
        data: (classes) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(timetableEntriesProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            children: [
              DropdownButtonFormField<ClassModel>(
                initialValue: selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Select Class',
                  prefixIcon: Icon(Icons.school),
                ),
                items: classes
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.display)))
                    .toList(),
                onChanged: (v) {
                  ref.read(selectedClassProvider.notifier).state = v;
                },
              ),
              const SizedBox(height: 16),
              if (selectedClass != null)
                isMobile
                    ? _buildMobileActionBar(entriesAsync)
                    : _buildDesktopActionBar(entriesAsync),
              if (selectedClass == null)
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('Select a class to view timetable',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                entriesAsync.when(
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: ErrorRetryWidget(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(timetableEntriesProvider),
                    ),
                  ),
                  data: (entries) => entries.isEmpty
                      ? SizedBox(
                          height: 200,
                          child: Center(
                            child: Text('No timetable entries for this class',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      : _timetableGrid(isMobile, entries),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: isMobile && selectedClass != null
          ? FloatingActionButton(
              onPressed: () => _showEntrySheet(null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDesktopActionBar(AsyncValue<List<TimetableEntry>> entriesAsync) {
    return Row(
      children: [
        CustomButton(
          label: 'Add Entry',
          icon: Icons.add,
          onPressed: () => _showEntryDialog(null),
        ),
        const Spacer(),
        if (entriesAsync.isLoading)
          const CircularProgressIndicator(strokeWidth: 2),
      ],
    );
  }

  Widget _buildMobileActionBar(AsyncValue<List<TimetableEntry>> entriesAsync) {
    final entries = entriesAsync.valueOrNull ?? [];
    return Row(
      children: [
        Text('${entries.length} entries',
            style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        if (entriesAsync.isLoading) const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _timetableGrid(bool isMobile, List<TimetableEntry> entries) {
    const dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    final grouped = <String, List<TimetableEntry>>{};
    for (final d in dayOrder) {
      grouped[d] = entries.where((e) => e.day == d).toList();
    }

    return Column(
      children: dayOrder.map((day) {
        final dayEntries = grouped[day]!;
        if (dayEntries.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayEntries.first.dayLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Divider(),
                ...dayEntries.map((e) => isMobile
                    ? _buildMobileEntryTile(e)
                    : ListTile(
                        dense: true,
                        title: Text(e.subjectName ?? e.subjectId),
                        subtitle: Text(
                            '${e.startTime} - ${e.endTime}  |  ${e.teacherName ?? e.teacherId}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showEntryDialog(e);
                            } else if (action == 'delete') {
                              _confirmDelete(e);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileEntryTile(TimetableEntry e) {
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDeleteMobile(e),
      child: Card(
        margin: const EdgeInsets.only(bottom: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          dense: true,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.book_rounded,
                color: AppColors.primary, size: 18),
          ),
          title: Text(e.subjectName ?? e.subjectId,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(
              '${e.startTime} - ${e.endTime}  |  ${e.teacherName ?? e.teacherId}',
              style: const TextStyle(fontSize: 12)),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _showEntrySheet(e);
              } else if (action == 'delete') {
                _confirmDelete(e);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEntrySheet(TimetableEntry? existing) async {
    final repo = ref.read(adminRepositoryProvider);
    final subjects = await repo.getSubjects();
    final teachers = await repo.getTeachers();

    if (!mounted) return;

    Subject? selSubject;
    Teacher? selTeacher;
    String selDay = existing?.day ?? 'mon';
    final startCtrl =
        TextEditingController(text: existing?.startTime ?? '');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '');
    bool saving = false;

    if (existing != null) {
      selSubject = subjects.where((s) => s.id == existing.subjectId).firstOrNull;
      selTeacher = teachers.where((t) => t.id == existing.teacherId).firstOrNull;
    }

    final selectedClass = ref.read(selectedClassProvider);

    await showModalBottomSheet<bool>(
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
                  existing != null ? 'Edit Entry' : 'Add Entry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<Subject>(
                  initialValue: selSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    prefixIcon: Icon(Icons.book),
                  ),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selSubject = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Teacher>(
                  initialValue: selTeacher,
                  decoration: const InputDecoration(
                    labelText: 'Teacher *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: teachers
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.fullName)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selTeacher = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selDay,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mon', child: Text('Monday')),
                    DropdownMenuItem(value: 'tue', child: Text('Tuesday')),
                    DropdownMenuItem(value: 'wed', child: Text('Wednesday')),
                    DropdownMenuItem(value: 'thu', child: Text('Thursday')),
                    DropdownMenuItem(value: 'fri', child: Text('Friday')),
                    DropdownMenuItem(value: 'sat', child: Text('Saturday')),
                  ],
                  onChanged: (v) => setSheetState(() => selDay = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (HH:MM)',
                    hintText: 'e.g. 09:00',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                    labelText: 'End Time (HH:MM)',
                    hintText: 'e.g. 10:00',
                    prefixIcon: Icon(Icons.access_time),
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
                            if (selSubject == null ||
                                selTeacher == null ||
                                startCtrl.text.isEmpty ||
                                endCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill all fields'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            final body = {
                              'class_id': selectedClass!.id,
                              'subject_id': selSubject!.id,
                              'teacher_id': selTeacher!.id,
                              'day': selDay,
                              'start_time': startCtrl.text,
                              'end_time': endCtrl.text,
                            };
                            final controller = ref.read(timetableControllerProvider.notifier);
                            final success = existing != null
                                ? await controller.updateEntry(existing.id, body)
                                : await controller.createEntry(body);
                            if (ctx.mounted) {
                              if (success) {
                                Navigator.pop(ctx, true);
                              } else {
                                setSheetState(() => saving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to save entry'),
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
                        : Text(existing != null ? 'Update' : 'Add'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEntryDialog(TimetableEntry? existing) async {
    final repo = ref.read(adminRepositoryProvider);
    final subjects = await repo.getSubjects();
    final teachers = await repo.getTeachers();

    if (!mounted) return;

    Subject? selSubject;
    Teacher? selTeacher;
    String selDay = existing?.day ?? 'mon';
    final startCtrl =
        TextEditingController(text: existing?.startTime ?? '');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '');

    if (existing != null) {
      selSubject = subjects.where((s) => s.id == existing.subjectId).firstOrNull;
      selTeacher = teachers.where((t) => t.id == existing.teacherId).firstOrNull;
    }

    final selectedClass = ref.read(selectedClassProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Entry' : 'Add Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Subject>(
                  initialValue: selSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.book),
                  ),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selSubject = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Teacher>(
                  initialValue: selTeacher,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: teachers
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.fullName)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selTeacher = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selDay,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mon', child: Text('Monday')),
                    DropdownMenuItem(value: 'tue', child: Text('Tuesday')),
                    DropdownMenuItem(value: 'wed', child: Text('Wednesday')),
                    DropdownMenuItem(value: 'thu', child: Text('Thursday')),
                    DropdownMenuItem(value: 'fri', child: Text('Friday')),
                    DropdownMenuItem(value: 'sat', child: Text('Saturday')),
                  ],
                  onChanged: (v) => setDialogState(() => selDay = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (HH:MM)',
                    hintText: 'e.g. 09:00',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                    labelText: 'End Time (HH:MM)',
                    hintText: 'e.g. 10:00',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            CustomButton(
              label: existing != null ? 'Update' : 'Add',
              onPressed: () async {
                if (selSubject == null ||
                    selTeacher == null ||
                    startCtrl.text.isEmpty ||
                    endCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                final body = {
                  'class_id': selectedClass!.id,
                  'subject_id': selSubject!.id,
                  'teacher_id': selTeacher!.id,
                  'day': selDay,
                  'start_time': startCtrl.text,
                  'end_time': endCtrl.text,
                };
                final controller = ref.read(timetableControllerProvider.notifier);
                final success = existing != null
                    ? await controller.updateEntry(existing.id, body)
                    : await controller.createEntry(body);
                if (ctx.mounted) {
                  if (success) {
                    Navigator.pop(ctx, true);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save entry'),
                        backgroundColor: AppColors.error,
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

    if (result == true) {
      ref.invalidate(timetableEntriesProvider);
    }
  }

  Future<bool> _confirmDeleteMobile(TimetableEntry entry) async {
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
              'Delete Entry',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete ${entry.subjectName ?? 'this'} entry on ${entry.dayLabel} at ${entry.startTime}?',
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
                  final controller = ref.read(timetableControllerProvider.notifier);
                  await controller.deleteEntry(entry.id);
                  if (ctx.mounted) Navigator.pop(ctx, true);
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

  void _confirmDelete(TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
            'Delete ${entry.subjectName ?? 'this'} entry on ${entry.dayLabel} at ${entry.startTime}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Delete',
            onPressed: () async {
              final controller = ref.read(timetableControllerProvider.notifier);
              await controller.deleteEntry(entry.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
