import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

class AdminHolidaysScreen extends ConsumerStatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  ConsumerState<AdminHolidaysScreen> createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends ConsumerState<AdminHolidaysScreen> {
  late int _currentYear;
  late int _currentMonth;
  List<Holiday> _holidays = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final data = await repo.getHolidays(
        year: _currentYear.toString(),
        month: _currentMonth.toString().padLeft(2, '0'),
      );
      _holidays = data;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() { _loading = false; });
  }

  void _prevMonth() {
    if (_currentMonth == 1) {
      _currentMonth = 12;
      _currentYear--;
    } else {
      _currentMonth--;
    }
    _loadHolidays();
  }

  void _nextMonth() {
    if (_currentMonth == 12) {
      _currentMonth = 1;
      _currentYear++;
    } else {
      _currentMonth++;
    }
    _loadHolidays();
  }

  Future<void> _showHolidayDialog({Holiday? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    DateTime selectedDate = existing != null
        ? DateTime.parse(existing.date)
        : DateTime(_currentYear, _currentMonth, 1);
    String selectedType = existing?.type ?? 'holiday';
    bool isRecurring = existing?.isRecurring ?? false;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Holiday' : 'Add Holiday'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDialogState(() { selectedDate = picked; });
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                    DropdownMenuItem(value: 'event', child: Text('Event')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() { selectedType = v; });
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Recurring yearly'),
                  value: isRecurring,
                  onChanged: (v) => setDialogState(() { isRecurring = v ?? false; }),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      setDialogState(() { saving = true; });
                      try {
                        final repo = ref.read(adminRepositoryProvider);
                        final body = {
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          'type': selectedType,
                          'is_recurring': isRecurring,
                        };
                        if (existing != null) {
                          await repo.updateHoliday(existing.id, body);
                        } else {
                          await repo.createHoliday(body);
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() { saving = false; });
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
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
    if (saved == true) _loadHolidays();
  }

  Future<void> _deleteHoliday(Holiday h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Delete "${h.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).deleteHoliday(h.id);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) _loadHolidays();
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final firstWeekday = DateTime(_currentYear, _currentMonth, 1).weekday;

    final holidayDates = <int>{};
    final eventDates = <int>{};
    final dayHolidays = <int, List<Holiday>>{};
    for (final h in _holidays) {
      final day = DateTime.parse(h.date).day;
      (h.isHoliday ? holidayDates : eventDates).add(day);
      dayHolidays.putIfAbsent(day, () => []).add(h);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Holidays'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Holiday/Event',
            onPressed: () => _showHolidayDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    _buildMonthNav(),
                    _buildCalendar(daysInMonth, firstWeekday, holidayDates, eventDates),
                    const Divider(height: 1),
                    if (_holidays.isEmpty)
                      const Expanded(
                        child: Center(child: Text('No holidays or events this month')),
                      )
                    else
                      Expanded(child: _buildHolidayList(dayHolidays)),
                  ],
                ),
    );
  }

  Widget _buildMonthNav() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
          const SizedBox(width: 8),
          Text(
            '${months[_currentMonth - 1]} $_currentYear',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
        ],
      ),
    );
  }

  Widget _buildCalendar(int days, int firstWeekday, Set<int> holidays, Set<int> events) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: dayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(
            ((firstWeekday - 1 + days) / 7).ceil(),
            (weekIndex) => Row(
              children: List.generate(7, (weekday) {
                final day = weekIndex * 7 + weekday - firstWeekday + 2;
                if (day < 1 || day > days) return const Expanded(child: SizedBox());
                final isHoliday = holidays.contains(day);
                final isEvent = events.contains(day);
                final isSunday = weekday == 6;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isHoliday
                          ? Colors.red.shade50
                          : isEvent
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isHoliday || isEvent ? FontWeight.bold : FontWeight.normal,
                          color: isHoliday
                              ? Colors.red
                              : isSunday
                                  ? Colors.grey
                                  : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayList(Map<int, List<Holiday>> dayMap) {
    final sortedDays = dayMap.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final items = dayMap[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((h) {
            final date = DateTime.parse(h.date);
            final dateStr = '${date.day} ${_monthAbbr(date.month)}';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: h.isHoliday ? Colors.red.shade100 : AppColors.primary.withValues(alpha: 0.2),
                  child: Icon(
                    h.isHoliday ? Icons.celebration : Icons.event,
                    color: h.isHoliday ? Colors.red : AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '$dateStr  ${h.displayType}${h.isRecurring ? ' (Recurring)' : ''}${h.description != null ? '\n${h.description}' : ''}',
                ),
                isThreeLine: h.description != null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showHolidayDialog(existing: h),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteHoliday(h),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _monthAbbr(int m) {
    const abbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return abbr[m];
  }
}
