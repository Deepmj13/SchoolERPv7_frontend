import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/features/admin/data/admin_repository.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/timetable_provider.dart';

class AdminProxiesScreen extends ConsumerStatefulWidget {
  const AdminProxiesScreen({super.key});

  @override
  ConsumerState<AdminProxiesScreen> createState() => _AdminProxiesScreenState();
}

class _AdminProxiesScreenState extends ConsumerState<AdminProxiesScreen> {
  late DateTime _date;
  List<ProxyAssignment> _proxies = [];
  bool _loading = false;
  String? _error;

  String get _dateStr => _formatDate(_date);

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      _proxies = await repo.getAdminProxies(_dateStr);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  Future<void> _cancelProxy(ProxyAssignment p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Proxy'),
        content: Text(
          'Cancel the proxy for "${p.subjectName ?? 'this lecture'}" (${p.proxyTeacherName})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).cancelProxy(p.id);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Cancel Proxy'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proxy cancelled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _weekdayOf(String dateStr) {
    final parts = dateStr.split('-').map(int.parse).toList();
    final weekday = DateTime(parts[0], parts[1], parts[2]).weekday;
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    if (weekday == 7) return '';
    return days[weekday - 1];
  }

  Future<List<TimetableEntry>> _loadSlots(
      AdminRepository repo, String classId, String dateStr) async {
    final entries = await repo.getClassTimetable(classId, date: dateStr);
    final week = _weekdayOf(dateStr);
    if (week.isEmpty) return [];
    return entries.where((e) => e.day == week).toList();
  }

  Future<ProxyAssignment?> _findCurrentProxy(
      AdminRepository repo, String timetableId, String dateStr) async {
    final proxies = await repo.getAdminProxies(dateStr);
    for (final p in proxies) {
      if (p.timetableId == timetableId &&
          (p.status == 'pending' || p.status == 'accepted')) {
        return p;
      }
    }
    return null;
  }

  Future<({Map<String, dynamic> teachers, ProxyAssignment? current})>
      _loadTeacherData(
          AdminRepository repo, TimetableEntry entry, String dateStr) async {
    final teachers = await repo.getProxyTeachers(entry.id, date: dateStr);
    final current = await _findCurrentProxy(repo, entry.id, dateStr);
    return (teachers: teachers, current: current);
  }

  void _showAssignSheet() {
    final repo = ref.read(adminRepositoryProvider);
    DateTime sheetDate = _date;
    ClassModel? selectedClass;
    TimetableEntry? selectedEntry;
    String? selectedTeacherId;
    final reasonCtrl = TextEditingController();
    bool saving = false;
    bool canceling = false;
    late Future<List<ClassModel>> classesFuture;
    late Future<List<TimetableEntry>> slotsFuture;
    late Future<({Map<String, dynamic> teachers, ProxyAssignment? current})>
        teacherDataFuture;
    classesFuture = repo.getClasses();
    slotsFuture = Future.value(<TimetableEntry>[]);
    teacherDataFuture =
        Future.value((teachers: <String, dynamic>{}, current: null));

    void reloadSlots() {
      if (selectedClass == null) {
        slotsFuture = Future.value(<TimetableEntry>[]);
      } else {
        slotsFuture =
            _loadSlots(repo, selectedClass!.id, _formatDate(sheetDate));
      }
      selectedEntry = null;
      selectedTeacherId = null;
    }

    Widget teacherSection(
      String title,
      List<Map<String, dynamic>> teachers,
      String? busySubtitle,
      void Function(String?) onSelect,
    ) {
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
                color: isBusy ? AppColors.warning : AppColors.success,
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
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: selected
                    ? AppColors.success
                    : AppColors.textSecondary,
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
              onTap: () => onSelect(id),
            );
          }),
        ],
      );
    }

    showModalBottomSheet<void>(
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
                  'Assign Proxy',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: sheetDate,
                      firstDate: now.subtract(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() {
                        sheetDate = picked;
                        reloadSlots();
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Proxy Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _formatDate(sheetDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<ClassModel>>(
                  future: classesFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (snap.hasError || snap.data == null) {
                      return const Text(
                        'Failed to load classes',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    final classes = snap.data!;
                    if (classes.isEmpty) {
                      return const Text(
                        'No classes found',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: selectedClass?.id,
                      decoration: const InputDecoration(
                        labelText: 'Class *',
                        prefixIcon: Icon(Icons.school_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: classes
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.displayName),
                              ))
                          .toList(),
                      onChanged: (v) {
                        final cls = classes.firstWhere((c) => c.id == v);
                        setSheetState(() {
                          selectedClass = cls;
                          reloadSlots();
                        });
                      },
                    );
                  },
                ),
                if (selectedClass != null) const SizedBox(height: 16),
                if (selectedClass != null)
                  FutureBuilder<List<TimetableEntry>>(
                    future: slotsFuture,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (snap.hasError || snap.data == null) {
                        return const Text(
                          'Failed to load lectures',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      final slots = snap.data!;
                      if (slots.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No lectures for this class on ${_formatDate(sheetDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 4),
                            child: Text(
                              'Select lecture',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...slots.map((e) {
                            final selected = e.id == selectedEntry?.id;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: selected
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              title: Text(
                                '${e.subjectName ?? 'Lecture'} · ${e.teacherName ?? ''}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '${e.startTime} - ${e.endTime}'
                                '${e.room != null && e.room!.isNotEmpty ? ' · ${e.room}' : ''}',
                              ),
                              onTap: () {
                                setSheetState(() {
                                  selectedEntry = e;
                                  selectedTeacherId = null;
                                  teacherDataFuture =
                                      _loadTeacherData(
                                          repo, e, _formatDate(sheetDate));
                                });
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                if (selectedEntry != null) const SizedBox(height: 16),
                if (selectedEntry != null)
                  FutureBuilder<
                      ({
                        Map<String, dynamic> teachers,
                        ProxyAssignment? current
                      })>(
                    future: teacherDataFuture,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (snap.hasError || snap.data == null) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Failed to load teachers',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        );
                      }
                      final teachers = snap.data!.teachers;
                      final current = snap.data!.current;
                      final available = (teachers['available'] as List? ?? [])
                          .cast<Map<String, dynamic>>();
                      final busy = (teachers['busy'] as List? ?? [])
                          .cast<Map<String, dynamic>>();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (current != null) ...[
                            _buildCurrentProxyCard(
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          if (available.isNotEmpty)
                            teacherSection(
                              'Available',
                              available,
                              null,
                              (v) => setSheetState(() {
                                selectedTeacherId = v;
                              }),
                            ),
                          if (busy.isNotEmpty)
                            teacherSection(
                              'Busy',
                              busy,
                              'Busy at this slot',
                              (v) => setSheetState(() {
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
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: (selectedTeacherId != null &&
                                      !saving)
                                  ? () async {
                                      setSheetState(() => saving = true);
                                      try {
                                        final data = await teacherDataFuture;
                                        if (data.current != null) {
                                          await repo.cancelProxy(
                                              data.current!.id);
                                        }
                                        await repo.assignProxy(
                                          selectedEntry!.id,
                                          selectedTeacherId!,
                                          reasonCtrl.text.isNotEmpty
                                              ? reasonCtrl.text
                                              : null,
                                          date: _formatDate(sheetDate),
                                        );
                                        ref.invalidate(timetableEntriesProvider);
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        setState(() => _date = sheetDate);
                                        _load();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Proxy assigned successfully',
                                              ),
                                              backgroundColor: AppColors.success,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setSheetState(() => saving = false);
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Failed: $e'),
                                              backgroundColor: AppColors.error,
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                  : Text(current != null
                                      ? 'Reassign'
                                      : 'Assign Proxy'),
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

  Widget _buildCurrentProxyCard({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proxy Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Assign Proxy',
            onPressed: _showAssignSheet,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Change date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _proxies.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Text(
                                'No proxy assignments for $_dateStr',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _proxies.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Proxies for $_dateStr',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return _buildProxyCard(_proxies[index - 1]);
                          },
                        ),
                ),
    );
  }

  Widget _buildProxyCard(ProxyAssignment p) {
    final cancellable = p.status == 'pending' || p.status == 'accepted';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${p.subjectName ?? 'Lecture'} · ${p.classDisplay}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(p),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${p.startTime ?? ''} - ${p.endTime ?? ''} · ${p.dayLabel}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_off, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${p.originalTeacherName} → ${p.proxyTeacherName}',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (p.reason != null && p.reason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${p.reason}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            if (cancellable)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancelProxy(p),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel Proxy'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ProxyAssignment p) {
    final color = switch (p.status) {
      'accepted' => AppColors.success,
      'pending' => AppColors.warning,
      'rejected' => AppColors.error,
      'cancelled' => AppColors.textSecondary,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        p.statusLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
