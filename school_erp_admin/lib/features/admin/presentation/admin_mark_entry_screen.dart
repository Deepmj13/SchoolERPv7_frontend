import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final examDetailProvider = FutureProvider.family<Exam, String>((ref, examId) {
  return ref.read(adminRepositoryProvider).getExam(examId).timeout(const Duration(seconds: 30));
});

final examSubjectsProvider = FutureProvider.family<List<ExamSubject>, String>((ref, examId) {
  return ref.read(adminRepositoryProvider).getExamSubjects(examId).timeout(const Duration(seconds: 30));
});

final classesForFilterProvider = FutureProvider.family<List<ExamClass>, String>((ref, examId) {
  return ref.watch(adminRepositoryProvider).getExamClasses(examId).timeout(const Duration(seconds: 30));
});

final classStudentsProvider = FutureProvider.family<List<Student>, String>((ref, classId) {
  return ref.read(adminRepositoryProvider).getClassStudents(classId).timeout(const Duration(seconds: 30));
});

class AdminMarkEntryScreen extends ConsumerStatefulWidget {
  final String examId;

  const AdminMarkEntryScreen({super.key, required this.examId});

  @override
  ConsumerState<AdminMarkEntryScreen> createState() => _AdminMarkEntryScreenState();
}

class _AdminMarkEntryScreenState extends ConsumerState<AdminMarkEntryScreen> {
  String? _selectedSubjectId;
  String? _selectedClassId;
  final Map<String, TextEditingController> _markControllers = {};

  @override
  void dispose() {
    for (final c in _markControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMarks() async {
    if (_selectedSubjectId == null || _selectedClassId == null) return;
    final marks = _markControllers.entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map((e) => {
              'studentId': e.key,
              'marksObtained': double.parse(e.value.text.trim()),
            })
        .toList();
    if (marks.isEmpty) return;
    try {
      await ref.read(adminRepositoryProvider).bulkSaveResults(
        widget.examId,
        _selectedSubjectId!,
        marks,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final examAsync = ref.watch(examDetailProvider(widget.examId));
    final subjectsAsync = ref.watch(examSubjectsProvider(widget.examId));
    final classesAsync = ref.watch(classesForFilterProvider(widget.examId));
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: examAsync.when(
          data: (e) => Text('Mark Entry — ${e.name}'),
          loading: () => const Text('Mark Entry'),
          error: (_, __) => const Text('Mark Entry'),
        ),
        actions: [
          if (_selectedSubjectId != null && _selectedClassId != null)
            CustomButton(
              label: 'Save',
              icon: Icons.save,
              onPressed: _saveMarks,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                subjectsAsync.when(
                  data: (subjects) => DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: subjects
                        .map((s) => DropdownMenuItem(
                            value: s.subjectId, child: Text(s.subjectName)))
                        .toList(),
                    onChanged: (id) => setState(() => _selectedSubjectId = id),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  loading: () => const SizedBox(width: 140, child: LinearProgressIndicator()),
                ),
                classesAsync.when(
                  data: (classes) => DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: classes
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.displayName)))
                        .toList(),
                    onChanged: (id) => setState(() {
                      _selectedClassId = id;
                      _markControllers.clear();
                    }),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  loading: () => const SizedBox(width: 140, child: LinearProgressIndicator()),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedSubjectId == null || _selectedClassId == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_outlined, size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Select a subject and class to enter marks',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  )
                : _buildMarkTable(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkTable(bool isMobile) {
    final studentsAsync = ref.watch(classStudentsProvider(_selectedClassId!));

    return studentsAsync.when(
      loading: () => const ListSkeletonLoader(),
      error: (e, _) => ErrorRetryWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(classStudentsProvider(_selectedClassId!)),
      ),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No students in this class',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return isMobile
            ? ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s = students[i];
                  _markControllers.putIfAbsent(s.id, () => TextEditingController());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (s.rollNumber != null)
                                  Text('Roll: ${s.rollNumber}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _markControllers[s.id],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Marks',
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
                  columns: const [
                    DataColumn(label: Text('Roll No', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Marks', style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                  rows: students.map((s) {
                    _markControllers.putIfAbsent(s.id, () => TextEditingController());
                    return DataRow(cells: [
                      DataCell(Text(s.rollNumber ?? '-')),
                      DataCell(Text(s.fullName)),
                      DataCell(SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _markControllers[s.id],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Marks',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )),
                    ]);
                  }).toList(),
                ),
              );
      },
    );
  }
}
