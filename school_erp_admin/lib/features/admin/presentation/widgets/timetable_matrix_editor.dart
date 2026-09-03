import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/timetable_form_sheet.dart';

class CellData {
  String? subjectId;
  String? teacherId;
  String room;
  final String? existingEntryId;

  CellData({this.subjectId, this.teacherId, this.room = '', this.existingEntryId});

  bool get isFilled => subjectId != null && teacherId != null;
  bool get isNew => existingEntryId == null;
  bool get isModified => existingEntryId != null;
}

class TimetableSaveResult {
  final List<Map<String, dynamic>> toCreate;
  final List<({String id, Map<String, dynamic> body})> toUpdate;
  final List<String> toDelete;

  TimetableSaveResult({required this.toCreate, required this.toUpdate, required this.toDelete});

  bool get isEmpty => toCreate.isEmpty && toUpdate.isEmpty && toDelete.isEmpty;
}

class TimetableMatrixEditor extends StatefulWidget {
  final List<TimetableEntry> existingEntries;
  final List<Subject> subjects;
  final List<Teacher> teachers;
  final ValueChanged<TimetableSaveResult> onSave;
  final VoidCallback onCancel;
  final String classId;

  const TimetableMatrixEditor({
    super.key,
    required this.existingEntries,
    required this.subjects,
    required this.teachers,
    required this.onSave,
    required this.onCancel,
    required this.classId,
  });

  @override
  State<TimetableMatrixEditor> createState() => _TimetableMatrixEditorState();
}

class _TimetableMatrixEditorState extends State<TimetableMatrixEditor> {
  late Map<String, Map<String, CellData>> _matrix;
  bool _saving = false;
  String? _error;
  int _changeCount = 0;

  static const _dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  static const _dayLabels = {
    'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
    'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday',
  };

  List<PeriodTemplate> get _periods =>
      defaultPeriodTemplates.where((p) => p.label != 'Recess').toList();

  @override
  void initState() {
    super.initState();
    _buildMatrixFromEntries();
  }

  void _buildMatrixFromEntries() {
    _matrix = {};
    for (final day in _dayOrder) {
      _matrix[day] = {};
      for (final period in _periods) {
        _matrix[day]![period.startTimeStr] = CellData();
      }
    }

    for (final entry in widget.existingEntries) {
      final day = entry.day;
      final startKey = entry.startTime.length >= 5 ? entry.startTime.substring(0, 5) : entry.startTime;
      if (_matrix[day] != null && _matrix[day]![startKey] != null) {
        _matrix[day]![startKey] = CellData(
          subjectId: entry.subjectId,
          teacherId: entry.teacherId,
          room: entry.room ?? '',
          existingEntryId: entry.id,
        );
      }
    }
  }

  void _updateCell(String day, String slotKey, {String? subjectId, String? teacherId, String? room}) {
    final cell = _matrix[day]![slotKey]!;
    if (subjectId != null) cell.subjectId = subjectId;
    if (teacherId != null) cell.teacherId = teacherId;
    if (room != null) cell.room = room;
    _recalcChanges();
    setState(() {});
  }

  void _clearCell(String day, String slotKey) {
    final cell = _matrix[day]![slotKey]!;
    cell.subjectId = null;
    cell.teacherId = null;
    cell.room = '';
    _recalcChanges();
    setState(() {});
  }

  void _recalcChanges() {
    int count = 0;
    for (final day in _dayOrder) {
      for (final period in _periods) {
        final cell = _matrix[day]![period.startTimeStr]!;
        if (cell.isNew && cell.isFilled) count++;
        else if (cell.isModified) {
          final orig = widget.existingEntries.where((e) =>
              e.id == cell.existingEntryId).firstOrNull;
          if (orig != null && (orig.subjectId != cell.subjectId || orig.teacherId != cell.teacherId || (orig.room ?? '') != cell.room)) {
            count++;
          }
        }
      }
    }
    final deleted = widget.existingEntries.where((e) {
      final day = e.day;
      final startKey = e.startTime.length >= 5 ? e.startTime.substring(0, 5) : e.startTime;
      final cell = _matrix[day]?[startKey];
      return cell != null && !cell.isFilled && cell.existingEntryId == e.id;
    }).length;
    count += deleted;
    _changeCount = count;
  }

  TimetableSaveResult _computeDiff() {
    final toCreate = <Map<String, dynamic>>[];
    final toUpdate = <({String id, Map<String, dynamic> body})>[];
    final toDelete = <String>[];

    for (final day in _dayOrder) {
      for (final period in _periods) {
        final cell = _matrix[day]![period.startTimeStr]!;
        if (cell.isFilled && cell.isNew) {
          toCreate.add({
            'class_id': widget.classId,
            'subject_id': cell.subjectId,
            'teacher_id': cell.teacherId,
            'day': day,
            'start_time': period.startTimeStr,
            'end_time': period.endTimeStr,
            if (cell.room.isNotEmpty) 'room': cell.room,
          });
        } else if (cell.isModified) {
          final orig = widget.existingEntries.where((e) => e.id == cell.existingEntryId).firstOrNull;
          if (orig != null && (orig.subjectId != cell.subjectId || orig.teacherId != cell.teacherId || (orig.room ?? '') != cell.room)) {
            toUpdate.add((
              id: cell.existingEntryId!,
              body: {
                'subject_id': cell.subjectId,
                'teacher_id': cell.teacherId,
                'day': day,
                'start_time': period.startTimeStr,
                'end_time': period.endTimeStr,
                if (cell.room.isNotEmpty) 'room': cell.room,
              },
            ));
          }
        } else if (!cell.isFilled && cell.existingEntryId != null) {
          toDelete.add(cell.existingEntryId!);
        }
      }
    }

    return TimetableSaveResult(toCreate: toCreate, toUpdate: toUpdate, toDelete: toDelete);
  }

  Subject? _findSubject(String? id) => widget.subjects.where((s) => s.id == id).firstOrNull;
  Teacher? _findTeacher(String? id) => widget.teachers.where((t) => t.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    const double cellW = 200;
    const double periodColW = 110;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.edit_calendar, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Edit Timetable',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_changeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_changeCount change${_changeCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Error banner
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
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
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
              ],
            ),
          ),

        // Matrix grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day header row
                    _buildHeaderRow(periodColW, cellW),
                    const Divider(height: 1),
                    // Period rows
                    ..._periods.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final period = entry.value;
                      return _buildPeriodRow(period, periodColW, cellW, idx < _periods.length - 1);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Legend + action buttons
        Row(
          children: [
            _legendDot(AppColors.success, 'Existing'),
            const SizedBox(width: 12),
            _legendDot(AppColors.primary, 'New'),
            const SizedBox(width: 12),
            _legendDot(AppColors.warning, 'Modified'),
            const Spacer(),
            OutlinedButton(
              onPressed: _saving ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saving || _changeCount == 0 ? null : _onSave,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save All ($_changeCount)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHeaderRow(double periodColW, double cellW) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          SizedBox(
            width: periodColW,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          ..._dayOrder.map((day) => SizedBox(
            width: cellW,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_dayLabels[day] ?? day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(PeriodTemplate period, double periodColW, double cellW, bool showDivider) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Row(
            children: [
              SizedBox(
                width: periodColW,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.label,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${period.startTimeStr}-${period.endTimeStr}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
              ..._dayOrder.map((day) => SizedBox(
                width: cellW,
                child: _buildCell(day, period),
              )),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
      ],
    );
  }

  Widget _buildCell(String day, PeriodTemplate period) {
    final slotKey = period.startTimeStr;
    final cell = _matrix[day]![slotKey]!;
    final subject = _findSubject(cell.subjectId);
    final teacher = _findTeacher(cell.teacherId);

    if (!cell.isFilled) {
      return _buildEmptyCell(day, slotKey);
    }

    final isModified = cell.isModified &&
        widget.existingEntries.any((e) =>
            e.id == cell.existingEntryId &&
            (e.subjectId != cell.subjectId || e.teacherId != cell.teacherId || (e.room ?? '') != cell.room));

    Color borderColor = AppColors.success;
    if (cell.isNew) borderColor = AppColors.primary;
    else if (isModified) borderColor = AppColors.warning;

    return Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject dropdown
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Subject>(
                value: subject,
                isDense: true,
                isExpanded: true,
                menuMaxHeight: 250,
                itemHeight: 48,
                hint: const Text('Subject', style: TextStyle(fontSize: 11)),
                items: widget.subjects.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => _updateCell(day, slotKey, subjectId: v?.id),
              ),
            ),
          ),
          // Teacher dropdown
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Teacher>(
                value: teacher,
                isDense: true,
                isExpanded: true,
                menuMaxHeight: 250,
                itemHeight: 48,
                hint: const Text('Teacher', style: TextStyle(fontSize: 11)),
                items: widget.teachers.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.fullName, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => _updateCell(day, slotKey, teacherId: v?.id),
              ),
            ),
          ),
          // Bottom row: room hint + delete
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showRoomDialog(day, slotKey, cell.room),
                  child: Text(
                    cell.room.isNotEmpty ? 'Room: ${cell.room}' : '+ Room',
                    style: TextStyle(fontSize: 9, color: cell.room.isNotEmpty ? Colors.grey[700] : Colors.grey[400]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _clearCell(day, slotKey),
                child: Icon(Icons.close, size: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell(String day, String slotKey) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1),
      ),
      child: Center(
        child: IconButton(
          icon: Icon(Icons.add_circle_outline, size: 20, color: Colors.grey[350]),
          tooltip: 'Add entry',
          onPressed: () => _showQuickAdd(day, slotKey),
        ),
      ),
    );
  }

  void _showQuickAdd(String day, String slotKey) {
    final period = _periods.firstWhere((p) => p.startTimeStr == slotKey);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _QuickAddSheet(
        day: day,
        period: period,
        subjects: widget.subjects,
        teachers: widget.teachers,
        onConfirm: (subjectId, teacherId, room) {
          _updateCell(day, slotKey, subjectId: subjectId, teacherId: teacherId, room: room);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showRoomDialog(String day, String slotKey, String currentRoom) {
    final ctrl = TextEditingController(text: currentRoom);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. 101', prefixIcon: Icon(Icons.meeting_room)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _updateCell(day, slotKey, room: ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    final diff = _computeDiff();
    if (diff.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      widget.onSave(diff);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Save failed: $e';
        });
      }
    }
  }
}

class _QuickAddSheet extends StatefulWidget {
  final String day;
  final PeriodTemplate period;
  final List<Subject> subjects;
  final List<Teacher> teachers;
  final void Function(String subjectId, String teacherId, String room) onConfirm;

  const _QuickAddSheet({
    required this.day,
    required this.period,
    required this.subjects,
    required this.teachers,
    required this.onConfirm,
  });

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  Subject? _subject;
  Teacher? _teacher;
  final _roomCtrl = TextEditingController();

  static const _dayLabels = {
    'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
    'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday',
  };

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
              'Add Entry',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_dayLabels[widget.day] ?? widget.day} - ${widget.period.label} (${widget.period.startTimeStr} - ${widget.period.endTimeStr})',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Subject *',
                prefixIcon: Icon(Icons.book),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Subject>(
                  value: _subject,
                  isExpanded: true,
                  hint: const Text('Select subject'),
                  items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => _subject = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Teacher *',
                prefixIcon: Icon(Icons.person),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Teacher>(
                  value: _teacher,
                  isExpanded: true,
                  hint: const Text('Select teacher'),
                  items: widget.teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                  onChanged: (v) => setState(() => _teacher = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Room (optional)',
                prefixIcon: Icon(Icons.meeting_room),
                hintText: 'e.g. 101',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_subject != null && _teacher != null)
                    ? () => widget.onConfirm(_subject!.id, _teacher!.id, _roomCtrl.text.trim())
                    : null,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
