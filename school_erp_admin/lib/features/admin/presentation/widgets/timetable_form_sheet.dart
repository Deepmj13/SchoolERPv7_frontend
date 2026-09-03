import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';

class PeriodTemplate {
  final String label;
  final TimeOfDay start;
  final TimeOfDay end;

  const PeriodTemplate({
    required this.label,
    required this.start,
    required this.end,
  });

  String get startTimeStr =>
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  String get endTimeStr =>
      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

  @override
  String toString() => '$label  ($startTimeStr - $endTimeStr)';
}

const defaultPeriodTemplates = [
  PeriodTemplate(label: 'Period 1', start: TimeOfDay(hour: 8, minute: 0), end: TimeOfDay(hour: 8, minute: 45)),
  PeriodTemplate(label: 'Period 2', start: TimeOfDay(hour: 8, minute: 45), end: TimeOfDay(hour: 9, minute: 30)),
  PeriodTemplate(label: 'Period 3', start: TimeOfDay(hour: 9, minute: 40), end: TimeOfDay(hour: 10, minute: 25)),
  PeriodTemplate(label: 'Period 4', start: TimeOfDay(hour: 10, minute: 25), end: TimeOfDay(hour: 11, minute: 10)),
  PeriodTemplate(label: 'Recess', start: TimeOfDay(hour: 11, minute: 10), end: TimeOfDay(hour: 11, minute: 30)),
  PeriodTemplate(label: 'Period 5', start: TimeOfDay(hour: 11, minute: 30), end: TimeOfDay(hour: 12, minute: 15)),
  PeriodTemplate(label: 'Period 6', start: TimeOfDay(hour: 12, minute: 15), end: TimeOfDay(hour: 13, minute: 0)),
  PeriodTemplate(label: 'Period 7', start: TimeOfDay(hour: 13, minute: 30), end: TimeOfDay(hour: 14, minute: 15)),
  PeriodTemplate(label: 'Period 8', start: TimeOfDay(hour: 14, minute: 15), end: TimeOfDay(hour: 15, minute: 0)),
];

Future<TimetableEntryResult?> showTimetableEntryForm({
  required BuildContext context,
  required List<Subject> subjects,
  required List<Teacher> teachers,
  TimetableEntry? existing,
}) {
  return showModalBottomSheet<TimetableEntryResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _TimetableEntryFormBody(
      subjects: subjects,
      teachers: teachers,
      existing: existing,
    ),
  );
}

class TimetableEntryResult {
  final Map<String, dynamic> body;
  TimetableEntryResult(this.body);
}

class _TimetableEntryFormBody extends StatefulWidget {
  final List<Subject> subjects;
  final List<Teacher> teachers;
  final TimetableEntry? existing;

  const _TimetableEntryFormBody({
    required this.subjects,
    required this.teachers,
    this.existing,
  });

  @override
  State<_TimetableEntryFormBody> createState() => _TimetableEntryFormBodyState();
}

class _TimetableEntryFormBodyState extends State<_TimetableEntryFormBody> {
  final _formKey = GlobalKey<FormState>();
  Subject? _selectedSubject;
  Teacher? _selectedTeacher;
  String _selectedDay = 'mon';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _roomCtrl = TextEditingController();
  bool _useCustomTime = false;
  String? _error;

  static const _dayOptions = [
    ('mon', 'Monday'),
    ('tue', 'Tuesday'),
    ('wed', 'Wednesday'),
    ('thu', 'Thursday'),
    ('fri', 'Friday'),
    ('sat', 'Saturday'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedSubject = widget.subjects.where((s) => s.id == e.subjectId).firstOrNull;
      _selectedTeacher = widget.teachers.where((t) => t.id == e.teacherId).firstOrNull;
      _selectedDay = e.day;
      _startTime = _parseTime(e.startTime);
      _endTime = _parseTime(e.endTime);
      _roomCtrl.text = e.room ?? '';
      _useCustomTime = true;
    }
  }

  TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  void _applyTemplate(PeriodTemplate template) {
    setState(() {
      _startTime = template.start;
      _endTime = template.end;
      _useCustomTime = false;
    });
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      setState(() => _error = 'Please select a time slot');
      return;
    }
    if (_selectedSubject == null || _selectedTeacher == null) {
      setState(() => _error = 'Subject and Teacher are required');
      return;
    }

    final body = <String, dynamic>{
      'subject_id': _selectedSubject!.id,
      'teacher_id': _selectedTeacher!.id,
      'day': _selectedDay,
      'start_time': _formatTime(_startTime!),
      'end_time': _formatTime(_endTime!),
    };
    if (_roomCtrl.text.trim().isNotEmpty) {
      body['room'] = _roomCtrl.text.trim();
    }
    Navigator.pop(context, TimetableEntryResult(body));
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditing ? 'Edit Entry' : 'Add Entry',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Day
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_today)),
                items: _dayOptions.map((d) => DropdownMenuItem(value: d.$1, child: Text(d.$2))).toList(),
                onChanged: (v) => setState(() => _selectedDay = v!),
              ),
              const SizedBox(height: 16),

              // Period Template
              Text(
                'Time Slot',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: defaultPeriodTemplates.where((p) => p.label != 'Recess').map((template) {
                  final isSelected = !_useCustomTime &&
                      _startTime != null && _endTime != null &&
                      _startTime == template.start && _endTime == template.end;
                  return ChoiceChip(
                    label: Text(template.label, style: TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => _applyTemplate(template),
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Manual time picker
              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Start',
                      time: _startTime,
                      onTap: () async {
                        final picked = await _pickTime(_startTime ?? const TimeOfDay(hour: 8, minute: 0));
                        if (picked != null) setState(() {
                          _startTime = picked;
                          _useCustomTime = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'End',
                      time: _endTime,
                      onTap: () async {
                        final picked = await _pickTime(_endTime ?? const TimeOfDay(hour: 9, minute: 0));
                        if (picked != null) setState(() {
                          _endTime = picked;
                          _useCustomTime = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subject
              DropdownButtonFormField<Subject>(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(labelText: 'Subject *', prefixIcon: Icon(Icons.book)),
                items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _selectedSubject = v),
                validator: (v) => v == null ? 'Subject required' : null,
              ),
              const SizedBox(height: 12),

              // Teacher
              DropdownButtonFormField<Teacher>(
                initialValue: _selectedTeacher,
                decoration: const InputDecoration(labelText: 'Teacher *', prefixIcon: Icon(Icons.person)),
                items: widget.teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                onChanged: (v) => setState(() => _selectedTeacher = v),
                validator: (v) => v == null ? 'Teacher required' : null,
              ),
              const SizedBox(height: 12),

              // Room
              TextFormField(
                controller: _roomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room (optional)',
                  prefixIcon: Icon(Icons.meeting_room),
                  hintText: 'e.g. 101',
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() => _error = null);
                    _onSave();
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '$label Time',
          prefixIcon: const Icon(Icons.access_time, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? AppColors.glassDark : Colors.white,
        ),
        child: Text(
          time != null ? _fmt(time!) : 'Pick time',
          style: TextStyle(
            fontSize: 14,
            color: time != null ? null : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
