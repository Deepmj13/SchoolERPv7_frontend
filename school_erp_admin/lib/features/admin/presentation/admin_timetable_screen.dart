import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/data/admin_repository.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/timetable_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/timetable_form_sheet.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/timetable_matrix_editor.dart';

final _classesProvider = FutureProvider<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses().timeout(const Duration(seconds: 30));
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
  bool _editMode = false;
  List<Subject> _subjects = [];
  List<Teacher> _teachers = [];

  Future<void> _enterEditMode() async {
    final repo = ref.read(adminRepositoryProvider);
    final subjects = await repo.getSubjects();
    final teachers = await repo.getTeachers();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _teachers = teachers;
      _editMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(_classesProvider);
    final entriesAsync = ref.watch(timetableEntriesProvider);
    final selectedClass = ref.watch(selectedClassProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Timetable' : 'Timetable'),
        actions: [
          if (_editMode)
            TextButton(
              onPressed: () => setState(() => _editMode = false),
              child: const Text('Done'),
            ),
        ],
      ),
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
                  if (_editMode) setState(() => _editMode = false);
                },
              ),
              const SizedBox(height: 16),
              if (selectedClass != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!_editMode) ...[
                      CustomButton(
                        label: 'Add Entry',
                        icon: Icons.add,
                        onPressed: () => _showEntryForm(null),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (!_editMode && !(entriesAsync.valueOrNull?.isEmpty ?? true))
                      CustomButton(
                        label: 'Edit Timetable',
                        icon: Icons.edit_calendar,
                        onPressed: _enterEditMode,
                      ),
                    if (entriesAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              if (selectedClass == null)
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a class',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a class above to view or build its timetable',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
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
                  data: (entries) {
                    if (_editMode) {
                      return SizedBox(
                        height: 500,
                        child: TimetableMatrixEditor(
                          existingEntries: entries,
                          subjects: _subjects,
                          teachers: _teachers,
                          classId: selectedClass.id,
                          onSave: (result) => _saveBulkChanges(result),
                          onCancel: () => setState(() => _editMode = false),
                        ),
                      );
                    }
                    if (entries.isEmpty) {
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.event_busy_rounded, color: AppColors.warning, size: 32),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No entries yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Start building the timetable by adding your first entry.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _showEntryForm(null),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add First Entry'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return _buildWeeklyGrid(entries, isMobile);
                  },
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
                                    onLongPress: () => _showAssignProxySheet(e),
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  e.subjectName ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: color,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (e.hasProxy && _isToday(e.day))
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warning.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'PROXY',
                                                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: AppColors.warning),
                                                  ),
                                                ),
                                            ],
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
                  child: GestureDetector(
                    onLongPress: () => _showAssignProxySheet(e),
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
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(e.subjectName ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          if (e.hasProxy && _isToday(e.day))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PROXY',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.warning),
                              ),
                            ),
                        ],
                      ),
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

    final selectedClass = ref.read(selectedClassProvider);
    if (selectedClass == null) return;

    final result = await showTimetableEntryForm(
      context: context,
      subjects: subjects,
      teachers: teachers,
      existing: existing,
    );

    if (result == null || !mounted) return;

    final body = {...result.body, 'class_id': selectedClass.id};

    try {
      final controller = ref.read(timetableControllerProvider.notifier);
      final success = existing != null
          ? await controller.updateEntry(existing.id, body)
          : await controller.createEntry(body);
      if (success) {
        ref.invalidate(timetableEntriesProvider);
      } else if (mounted) {
        _showError('Failed to save entry');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('409') || msg.toLowerCase().contains('conflict')) {
        _showError('Time conflict — this teacher or time slot is already assigned.');
      } else {
        _showError('Failed to save entry. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveBulkChanges(TimetableSaveResult diff) async {
    if (!mounted) return;
    final controller = ref.read(timetableControllerProvider.notifier);
    int created = 0, updated = 0, deleted = 0;
    String? firstError;

    for (final entry in diff.toCreate) {
      try {
        final ok = await controller.createEntry(entry);
        if (ok) created++;
      } catch (e) {
        firstError ??= e.toString();
      }
    }

    for (final entry in diff.toUpdate) {
      try {
        final ok = await controller.updateEntry(entry.id, entry.body);
        if (ok) updated++;
      } catch (e) {
        firstError ??= e.toString();
      }
    }

    for (final id in diff.toDelete) {
      try {
        final ok = await controller.deleteEntry(id);
        if (ok) deleted++;
      } catch (e) {
        firstError ??= e.toString();
      }
    }

    ref.invalidate(timetableEntriesProvider);

    if (!mounted) return;
    setState(() => _editMode = false);

    final parts = <String>[];
    if (created > 0) parts.add('$created added');
    if (updated > 0) parts.add('$updated updated');
    if (deleted > 0) parts.add('$deleted removed');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          firstError != null
              ? 'Saved with errors: ${parts.join(", ")}'
              : 'Timetable updated: ${parts.join(", ")}',
        ),
        backgroundColor: firstError != null ? AppColors.warning : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    final todayDay = days[now.weekday - 1];
    return day == todayDay;
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _nextDateForDay(String day) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    final target = days.indexOf(day);
    final now = DateTime.now();
    int diff = target - (now.weekday - 1);
    if (diff <= 0) diff += 7;
    return _formatDate(now.add(Duration(days: diff)));
  }

  String _defaultDateForDay(String day) {
    if (_isToday(day)) return _formatDate(DateTime.now());
    return _nextDateForDay(day);
  }

  Future<ProxyAssignment?> _findCurrentProxy(
      AdminRepository repo, String timetableId, String date) async {
    final proxies = await repo.getAdminProxies(date);
    for (final p in proxies) {
      if (p.timetableId == timetableId &&
          (p.status == 'pending' || p.status == 'accepted')) {
        return p;
      }
    }
    return null;
  }

  Future<({Map<String, dynamic> teachers, ProxyAssignment? current})>
      _loadSheetData(
          AdminRepository repo, TimetableEntry entry, String date) async {
    final teachers = await repo.getProxyTeachers(entry.id, date: date);
    final current = await _findCurrentProxy(repo, entry.id, date);
    return (teachers: teachers, current: current);
  }

  Future<DateTime?> _pickProxyDate(TimetableEntry entry) async {
    final now = DateTime.now();
    final initial = DateTime.parse(_defaultDateForDay(entry.day));
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      selectableDayPredicate: (day) {
        const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
        return day.weekday >= 1 && day.weekday <= 6 && days[day.weekday - 1] == entry.day;
      },
    );
  }

  void _showAssignProxySheet(TimetableEntry entry) {
    final repo = ref.read(adminRepositoryProvider);
    String selectedDate = _defaultDateForDay(entry.day);
    String? selectedTeacherId;
    final reasonCtrl = TextEditingController();
    bool saving = false;
    bool canceling = false;
    late Future<({Map<String, dynamic> teachers, ProxyAssignment? current})>
        sheetDataFuture;
    sheetDataFuture = _loadSheetData(repo, entry, selectedDate);

    showModalBottomSheet(
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
                  entry.hasProxy ? 'Manage Proxy' : 'Assign Proxy',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.subjectName ?? "Lecture"} - ${entry.classDisplay}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.startTime} - ${entry.endTime}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await _pickProxyDate(entry);
                    if (picked != null) {
                      final newDate = _formatDate(picked);
                      setSheetState(() {
                        selectedDate = newDate;
                        selectedTeacherId = null;
                        saving = false;
                        sheetDataFuture = _loadSheetData(repo, entry, newDate);
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Proxy Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedDate,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<
                    ({Map<String, dynamic> teachers, ProxyAssignment? current})>(
                  future: sheetDataFuture,
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          snapshot.hasError
                              ? 'Failed to load teachers'
                              : 'No teachers found',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      );
                    }
                    final teachers = snapshot.data!.teachers;
                    final current = snapshot.data!.current;
                    final available = (teachers['available'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    final busy = (teachers['busy'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (current != null) ...[
                          _buildCurrentProxySection(
                            proxy: current,
                            canceling: canceling,
                            onCancel: () async {
                              setSheetState(() => canceling = true);
                              try {
                                await repo.cancelProxy(current.id);
                                ref.invalidate(timetableEntriesProvider);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Proxy cancelled'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => canceling = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to cancel: $e'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (available.isEmpty && busy.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No teachers found for this slot',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        if (available.isNotEmpty)
                          _buildProxyTeacherSection(
                            title: 'Available',
                            teachers: available,
                            selectedTeacherId: selectedTeacherId,
                            onSelect: (v) => setSheetState(() {
                              selectedTeacherId = v;
                            }),
                          ),
                        if (busy.isNotEmpty)
                          _buildProxyTeacherSection(
                            title: 'Busy',
                            teachers: busy,
                            selectedTeacherId: selectedTeacherId,
                            busySubtitle: 'Busy at this slot',
                            onSelect: (v) => setSheetState(() {
                              selectedTeacherId = v;
                            }),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reasonCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Reason (optional)',
                            prefixIcon: Icon(Icons.message),
                            hintText: 'e.g. Teacher leave',
                          ),
                          maxLines: 2,
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
                            onPressed: (selectedTeacherId != null && !saving)
                                ? () async {
                                    setSheetState(() => saving = true);
                                    try {
                                      final data = await sheetDataFuture;
                                      if (data.current != null) {
                                        await repo.cancelProxy(data.current!.id);
                                      }
                                      await repo.assignProxy(
                                        entry.id,
                                        selectedTeacherId!,
                                        reasonCtrl.text.isNotEmpty
                                            ? reasonCtrl.text
                                            : null,
                                        date: selectedDate,
                                      );
                                      ref.invalidate(timetableEntriesProvider);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Proxy assigned successfully'),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => saving = false);
                                      if (ctx.mounted) {
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
                                : null,
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(current != null ? 'Reassign' : 'Assign Proxy'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentProxySection({
    required ProxyAssignment proxy,
    required bool canceling,
    required Future<void> Function() onCancel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, size: 18, color: AppColors.warning),
              const SizedBox(width: 6),
              const Text(
                'Current Proxy',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  proxy.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${proxy.proxyTeacherName} is assigned for this slot',
            style: const TextStyle(fontSize: 13),
          ),
          if (proxy.reason != null && proxy.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${proxy.reason}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: canceling ? null : onCancel,
              icon: canceling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close, size: 16),
              label: const Text('Cancel Proxy'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProxyTeacherSection({
    required String title,
    required List<Map<String, dynamic>> teachers,
    required String? selectedTeacherId,
    bool selectable = true,
    String? busySubtitle,
    required void Function(String?)? onSelect,
  }) {
    if (teachers.isEmpty) return const SizedBox.shrink();
    final isBusy = busySubtitle != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
            '$title (${teachers.length})',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isBusy
                  ? AppColors.warning
                  : (selectable ? AppColors.success : AppColors.textSecondary),
            ),
          ),
        ),
        ...teachers.map((t) {
          final id = t['id'] as String;
          final name = t['full_name'] as String? ?? '';
          final selected = id == selectedTeacherId;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.success : AppColors.textSecondary,
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                color: isBusy ? AppColors.textSecondary : null,
              ),
            ),
            subtitle: busySubtitle != null
                ? Text(
                    busySubtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
            onTap: selectable ? () => onSelect?.call(id) : null,
          );
        }),
      ],
    );
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
