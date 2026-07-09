import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/custom_button.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_remarks_provider.dart';

class TeacherRemarksScreen extends ConsumerStatefulWidget {
  const TeacherRemarksScreen({super.key});

  @override
  ConsumerState<TeacherRemarksScreen> createState() => _TeacherRemarksScreenState();
}

class _TeacherRemarksScreenState extends ConsumerState<TeacherRemarksScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _historySearchController = TextEditingController();
  bool _isMessageValid = false;
  String _searchQuery = '';
  String _historySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _searchController.addListener(_onSearchChanged);
    _historySearchController.addListener(_onHistorySearchChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _historySearchController.removeListener(_onHistorySearchChanged);
    _historySearchController.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    final valid = _messageController.text.trim().isNotEmpty;
    if (valid != _isMessageValid) {
      setState(() => _isMessageValid = valid);
    }
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  void _onHistorySearchChanged() {
    setState(() => _historySearchQuery = _historySearchController.text.trim().toLowerCase());
  }

  List<Student> _filteredStudents(RemarksState state) {
    if (_searchQuery.isEmpty) return state.students;
    return state.students.where((s) {
      return s.fullName.toLowerCase().contains(_searchQuery) ||
          (s.rollNumber?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remarksStateProvider);

    ref.listen<RemarksState>(remarksStateProvider, (prev, next) {
      if (next.successMessage != null) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success),
        );
        ref.read(remarksStateProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(remarksStateProvider.notifier).clearMessages();
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Remarks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Remark'),
              Tab(text: 'History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(remarksStateProvider.notifier).refresh(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildRemarkTab(state),
            _buildHistoryTab(state),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarkTab(RemarksState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _classSelector(state),
          if (state.selectedClass != null) ...[
            const SizedBox(height: 16),
            _studentSelector(state),
          ],
          if (state.selectedStudent != null) ...[
            const SizedBox(height: 16),
            _remarkForm(state),
          ],
          if (state.selectedStudent == null)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text('Select a student to add a remark',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(RemarksState state) {
    final filtered = state.allRemarks.where((r) {
      if (_historySearchQuery.isEmpty) return true;
      return r.message.toLowerCase().contains(_historySearchQuery) ||
          (r.studentName?.toLowerCase().contains(_historySearchQuery) ?? false);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All Remarks', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _historySearchController,
                  decoration: InputDecoration(
                    hintText: 'Search by message or student name',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoadingAllRemarks && state.allRemarks.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (state.allRemarks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No remarks yet', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No remarks match your search', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            Column(
              children: filtered.map((r) => _remarkCard(r, showStudent: true)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _classSelector(RemarksState state) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Class', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.isLoadingClasses)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (state.classes.isEmpty)
            Text('No classes found', style: Theme.of(context).textTheme.bodyMedium)
          else
            DropdownButtonFormField<TeacherClass>(
              key: ValueKey(state.selectedClass),
              initialValue: state.selectedClass,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Class'),
              items: state.classes.map((cls) => DropdownMenuItem(
                value: cls,
                child: Text(cls.display),
              )).toList(),
              onChanged: (cls) {
                if (cls != null) ref.read(remarksStateProvider.notifier).selectClass(cls);
              },
            ),
        ],
      ),
    );
  }

  Widget _studentSelector(RemarksState state) {
    if (state.selectedStudent != null) {
      final student = state.selectedStudent!;
      return GlassCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (student.rollNumber != null)
                    Text('Roll: ${student.rollNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              color: AppColors.textSecondary,
              onPressed: () => ref.read(remarksStateProvider.notifier).clearStudent(),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredStudents(state);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Student', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.students.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or roll number',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          if (state.isLoadingStudents)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (state.students.isEmpty)
            Text('No students found', style: Theme.of(context).textTheme.bodyMedium)
          else if (filtered.isEmpty)
            Text('No students match your search', style: Theme.of(context).textTheme.bodyMedium)
          else
            SizedBox(
              height: (filtered.length * 56).clamp(0, 200).toDouble(),
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = filtered[index];
                  final isSelected = state.selectedStudent?.id == student.id;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected ? AppColors.primary : AppColors.primaryLight,
                      child: Text(
                        student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    title: Text(student.fullName, style: const TextStyle(fontSize: 14)),
                    subtitle: student.rollNumber != null
                        ? Text('Roll: ${student.rollNumber}', style: const TextStyle(fontSize: 12))
                        : null,
                    onTap: () => ref.read(remarksStateProvider.notifier).selectStudent(student),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _remarkForm(RemarksState state) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Remark', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Praise'),
                  selected: state.remarkType == 'praise',
                  selectedColor: AppColors.success.withValues(alpha: 0.2),
                  onSelected: (_) => ref.read(remarksStateProvider.notifier).setRemarkType('praise'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Complaint'),
                  selected: state.remarkType == 'complaint',
                  selectedColor: AppColors.warning.withValues(alpha: 0.2),
                  onSelected: (_) => ref.read(remarksStateProvider.notifier).setRemarkType('complaint'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(state.remarkCategory),
            initialValue: state.remarkCategory,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category (optional)', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(child: Text('None')),
              DropdownMenuItem(value: 'academics', child: Text('Academics')),
              DropdownMenuItem(value: 'behavior', child: Text('Behavior')),
              DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
              DropdownMenuItem(value: 'general', child: Text('General')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (val) => ref.read(remarksStateProvider.notifier).setRemarkCategory(val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Submit Remark',
            loading: state.isSubmitting,
            onPressed: _isMessageValid && !state.isSubmitting
                ? () => ref.read(remarksStateProvider.notifier).submitRemark(_messageController.text)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _remarkCard(StudentRemark remark, {bool showStudent = false}) {
    final isPraise = remark.type == 'praise';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRemarkDetailSheet(remark, showStudent: showStudent),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isPraise ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPraise ? 'Praise' : 'Complaint',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPraise ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  if (remark.category != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        remark.category!,
                        style: const TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(_formatDate(remark.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              if (showStudent && remark.studentName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(remark.studentName!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(remark.message, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.open_in_new, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text('Tap to view', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemarkDetailSheet(StudentRemark remark, {bool showStudent = false}) {
    final isPraise = remark.type == 'praise';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPraise ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPraise ? 'Praise' : 'Complaint',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPraise ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  if (remark.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        remark.category!,
                        style: const TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (showStudent && remark.studentName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(remark.studentName!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_formatDate(remark.createdAt), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_formatDate(remark.createdAt), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 8),
              Text(remark.message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showEditBottomSheet(remark);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _confirmDelete(remark);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditBottomSheet(StudentRemark remark) {
    final typeController = TextEditingController(text: remark.message);
    String selectedType = remark.type;
    String? selectedCategory = remark.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Remark', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Praise'),
                          selected: selectedType == 'praise',
                          selectedColor: AppColors.success.withValues(alpha: 0.2),
                          onSelected: (_) => setSheetState(() => selectedType = 'praise'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Complaint'),
                          selected: selectedType == 'complaint',
                          selectedColor: AppColors.warning.withValues(alpha: 0.2),
                          onSelected: (_) => setSheetState(() => selectedType = 'complaint'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(selectedCategory),
                    initialValue: selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category (optional)', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(child: Text('None')),
                      DropdownMenuItem(value: 'academics', child: Text('Academics')),
                      DropdownMenuItem(value: 'behavior', child: Text('Behavior')),
                      DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                      DropdownMenuItem(value: 'general', child: Text('General')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) => setSheetState(() => selectedCategory = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'Save Changes',
                    onPressed: typeController.text.trim().isEmpty
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            ref.read(remarksStateProvider.notifier).editRemark(
                              remark.id,
                              selectedType,
                              selectedCategory,
                              typeController.text.trim(),
                            );
                          },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(StudentRemark remark) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Remark'),
          content: Text('Are you sure you want to delete this ${remark.type} remark?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(remarksStateProvider.notifier).deleteRemark(remark.id);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
