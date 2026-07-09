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

const _dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const _dayLabels = {'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu', 'fri': 'Fri', 'sat': 'Sat'};

const _subjectColors = [
  Color(0xFF4F6EF7),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
  Color(0xFF84CC16),
];

Color _colorForSubject(String subjectId) {
  final hash = subjectId.hashCode;
  return _subjectColors[hash.abs() % _subjectColors.length];
}

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
                Row(
                  children: [
                    CustomButton(
                      label: 'Add Entry',
                      icon: Icons.add,
                      onPressed: () => _showEntryForm(null),
                    ),
                    const Spacer(),
                    if (entriesAsync.isLoading)
                      const CircularProgressIndicator(strokeWidth: 2),
                  ],
                ),
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
                      : _buildWeeklyGrid(entries, isMobile),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _extractTimeSlots(List<TimetableEntry> entries) {
    final times = <String>{};
    for (final e in entries) {
      final start = e.startTime.length >= 5 ? e.startTime.substring(0, 5) : e.startTime;
      final end = e.endTime.length >= 5 ? e.endTime.substring(0, 5) : e.endTime;
      times.add(start);
      times.add(end);
    }
    final sorted = times.toList()..sort();
    return sorted;
  }

  Map<String, List<TimetableEntry>> _groupByDay(List<TimetableEntry> entries) {
    final grouped = <String, List<TimetableEntry>>{};
    for (final d in _dayOrder) grouped[d] = [];
    for (final e in entries) {
      grouped[e.day]?.add(e);
    }
    for (final d in _dayOrder) {
      grouped[d]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return grouped;
  }

  Widget _buildWeeklyGrid(List<TimetableEntry> entries, bool isMobile) {
    final slots = _extractTimeSlots(entries);
    final grouped = _groupByDay(entries);
    final hasEntries = entries.any((e) => e.room != null && e.room!.isNotEmpty);

    return Column(
      children: [
        if (isMobile)
          ..._dayOrder.map((day) {
            final dayEntries = grouped[day]!;
            if (dayEntries.isEmpty) return const SizedBox.shrink();
            return _buildDayColumn(day, dayEntries, slots, isMobile, hasEntries);
          })
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildDesktopGrid(slots, grouped, hasEntries),
          ),
      ],
    );
  }

  Widget _buildDesktopGrid(List<String> slots, Map<String, List<TimetableEntry>> grouped, bool showRoom) {
    const cellW = 160.0;
    const timeColW = 60.0;
    final rowH = 56.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: timeColW),
            ..._dayOrder.map((day) => SizedBox(
              width: cellW,
              child: Center(
                child: Text(
                  _dayLabels[day] ?? day,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            )),
          ],
        ),
        const Divider(height: 1),
        ...slots.asMap().entries.map((entry) {
          final slotIdx = entry.key;
          final slot = entry.value;
          final nextSlot = slotIdx + 1 < slots.length ? slots[slotIdx + 1] : null;
          return Column(
            children: [
              SizedBox(
                height: rowH,
                child: Row(
                  children: [
                    SizedBox(
                      width: timeColW,
                      child: Center(
                        child: Text(slot, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    ..._dayOrder.map((day) {
                      final dayEntries = grouped[day]!;
                      final matching = dayEntries.where((e) {
                        final s = e.startTime.length >= 5 ? e.startTime.substring(0, 5) : e.startTime;
                        return s == slot;
                      }).toList();
                      return SizedBox(
                        width: cellW,
                        child: matching.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: matching.map((e) {
                                  final color = _colorForSubject(e.subjectId);
                                  final span = nextSlot != null ? _calcSpan(e, slot, nextSlot, slots) : 1;
                                  return GestureDetector(
                                    onTap: () => _showEntryForm(e),
                                    child: Container(
                                      height: rowH * span - 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border(left: BorderSide(color: color, width: 3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            e.subjectName ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (showRoom && e.room != null && e.room!.isNotEmpty)
                                            Text(
                                              e.room!,
                                              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
                                              maxLines: 1,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      );
                    }),
                  ],
                ),
              ),
              if (slotIdx < slots.length - 1) const Divider(height: 1, indent: timeColW),
            ],
          );
        }),
      ],
    );
  }

  int _calcSpan(TimetableEntry entry, String currentSlot, String nextSlot, List<String> allSlots) {
    final end = entry.endTime.length >= 5 ? entry.endTime.substring(0, 5) : entry.endTime;
    int span = 1;
    for (int i = allSlots.indexOf(currentSlot) + 1; i < allSlots.length; i++) {
      if (allSlots[i].compareTo(end) < 0) span++;
      else break;
    }
    return span;
  }

  Widget _buildDayColumn(String day, List<TimetableEntry> entries, List<String> slots, bool isMobile, bool showRoom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayLabels[day] ?? day,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const Divider(),
            ...entries.map((e) {
              final color = _colorForSubject(e.subjectId);
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
                confirmDismiss: (_) => _confirmDelete(e),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.book_rounded, color: color, size: 18),
                    ),
                    title: Text(e.subjectName ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      '${e.startTime} - ${e.endTime}${showRoom && e.room != null && e.room!.isNotEmpty ? '  Room: ${e.room}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showEntryForm(e);
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
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showEntryForm(TimetableEntry? existing) async {
    final repo = ref.read(adminRepositoryProvider);
    final subjects = await repo.getSubjects();
    final teachers = await repo.getTeachers();
    if (!mounted) return;

    Subject? selSubject;
    Teacher? selTeacher;
    String selDay = existing?.day ?? 'mon';
    final startCtrl = TextEditingController(text: existing?.startTime ?? '');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '');
    final roomCtrl = TextEditingController(text: existing?.room ?? '');
    bool saving = false;

    if (existing != null) {
      selSubject = subjects.where((s) => s.id == existing.subjectId).firstOrNull;
      selTeacher = teachers.where((t) => t.id == existing.teacherId).firstOrNull;
    }

    final selectedClass = ref.read(selectedClassProvider);
    final isMobile = context.isMobile;

    final saved = await (isMobile
        ? _showBottomSheet(subjects, teachers, selSubject, selTeacher, selDay, startCtrl, endCtrl, roomCtrl, saving, existing, selectedClass)
        : _showDialog(subjects, teachers, selSubject, selTeacher, selDay, startCtrl, endCtrl, roomCtrl, saving, existing, selectedClass));

    if (saved == true) ref.invalidate(timetableEntriesProvider);
  }

  Future<bool?> _showDialog(
    List<Subject> subjects,
    List<Teacher> teachers,
    Subject? selSubject,
    Teacher? selTeacher,
    String selDay,
    TextEditingController startCtrl,
    TextEditingController endCtrl,
    TextEditingController roomCtrl,
    bool saving,
    TimetableEntry? existing,
    ClassModel? selectedClass,
  ) {
    return showDialog<bool>(
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
                  decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book)),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) => setDialogState(() => selSubject = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Teacher>(
                  initialValue: selTeacher,
                  decoration: const InputDecoration(labelText: 'Teacher', prefixIcon: Icon(Icons.person)),
                  items: teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                  onChanged: (v) => setDialogState(() => selTeacher = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selDay,
                  decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_today)),
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
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time (HH:MM)', hintText: 'e.g. 09:00')),
                const SizedBox(height: 12),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time (HH:MM)', hintText: 'e.g. 10:00')),
                const SizedBox(height: 12),
                TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room (optional)', hintText: 'e.g. 101')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            CustomButton(
              label: existing != null ? 'Update' : 'Add',
              onPressed: saving ? null : () => _saveEntry(ctx, setDialogState, saving, existing, selectedClass, selSubject, selTeacher, selDay, startCtrl, endCtrl, roomCtrl),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showBottomSheet(
    List<Subject> subjects,
    List<Teacher> teachers,
    Subject? selSubject,
    Teacher? selTeacher,
    String selDay,
    TextEditingController startCtrl,
    TextEditingController endCtrl,
    TextEditingController roomCtrl,
    bool saving,
    TimetableEntry? existing,
    ClassModel? selectedClass,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(existing != null ? 'Edit Entry' : 'Add Entry', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<Subject>(
                  initialValue: selSubject,
                  decoration: const InputDecoration(labelText: 'Subject *', prefixIcon: Icon(Icons.book)),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) => setSheetState(() => selSubject = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Teacher>(
                  initialValue: selTeacher,
                  decoration: const InputDecoration(labelText: 'Teacher *', prefixIcon: Icon(Icons.person)),
                  items: teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                  onChanged: (v) => setSheetState(() => selTeacher = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selDay,
                  decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_today)),
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
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time (HH:MM)', hintText: 'e.g. 09:00', prefixIcon: Icon(Icons.access_time))),
                const SizedBox(height: 12),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time (HH:MM)', hintText: 'e.g. 10:00', prefixIcon: Icon(Icons.access_time))),
                const SizedBox(height: 12),
                TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room (optional)', hintText: 'e.g. 101', prefixIcon: Icon(Icons.meeting_room))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: saving ? null : () => _saveEntry(ctx, setSheetState, saving, existing, selectedClass, selSubject, selTeacher, selDay, startCtrl, endCtrl, roomCtrl),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(existing != null ? 'Update' : 'Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEntry(
    BuildContext ctx,
    void Function(void Function()) setStateFn,
    bool saving,
    TimetableEntry? existing,
    ClassModel? selectedClass,
    Subject? selSubject,
    Teacher? selTeacher,
    String selDay,
    TextEditingController startCtrl,
    TextEditingController endCtrl,
    TextEditingController roomCtrl,
  ) async {
    if (selSubject == null || selTeacher == null || startCtrl.text.isEmpty || endCtrl.text.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    setStateFn(() { saving = true; });
    final body = <String, dynamic>{
      'class_id': selectedClass!.id,
      'subject_id': selSubject.id,
      'teacher_id': selTeacher.id,
      'day': selDay,
      'start_time': startCtrl.text,
      'end_time': endCtrl.text,
    };
    if (roomCtrl.text.trim().isNotEmpty) body['room'] = roomCtrl.text.trim();
    final controller = ref.read(timetableControllerProvider.notifier);
    final success = existing != null
        ? await controller.updateEntry(existing.id, body)
        : await controller.createEntry(body);
    if (ctx.mounted) {
      if (success) {
        Navigator.pop(ctx, true);
      } else {
        setStateFn(() { saving = false; });
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to save entry'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<bool> _confirmDelete(TimetableEntry entry) async {
    final isMobile = context.isMobile;
    final result = isMobile
        ? await showModalBottomSheet<bool>(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_outline, color: AppColors.error, size: 28)),
                  const SizedBox(height: 16),
                  Text('Delete Entry', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Delete ${entry.subjectName ?? 'this'} entry on ${entry.dayLabel} at ${entry.startTime}?', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async {
                    await ref.read(timetableControllerProvider.notifier).deleteEntry(entry.id);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  }, child: const Text('Delete'))),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                ],
              ),
            ),
          )
        : await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Entry'),
              content: Text('Delete ${entry.subjectName ?? 'this'} entry on ${entry.dayLabel} at ${entry.startTime}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                CustomButton(label: 'Delete', onPressed: () async {
                  await ref.read(timetableControllerProvider.notifier).deleteEntry(entry.id);
                  if (mounted) Navigator.pop(context, true);
                }),
              ],
            ),
          );
    if (result == true) ref.invalidate(timetableEntriesProvider);
    return result ?? false;
  }
}
