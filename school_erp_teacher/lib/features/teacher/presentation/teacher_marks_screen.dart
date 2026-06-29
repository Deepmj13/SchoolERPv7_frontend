import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/custom_button.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/providers/teacher_marks_provider.dart';

class TeacherMarksScreen extends ConsumerStatefulWidget {
  const TeacherMarksScreen({super.key});

  @override
  ConsumerState<TeacherMarksScreen> createState() =>
      _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends ConsumerState<TeacherMarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teacherId = ref.read(authStateProvider).user?.teacherId;
      if (teacherId != null) {
        ref.read(marksStateProvider.notifier).loadInitialData(teacherId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MarksState>(marksStateProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(marksStateProvider.notifier).clearMessages();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(marksStateProvider.notifier).clearMessages();
      }
    });

    final state = ref.watch(marksStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Marks')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _classSelector(state, ref),
            const SizedBox(height: 12),
            _examSelector(state, ref),
            if (state.selectedClass != null &&
                state.selectedExam != null &&
                state.selectedSubject != null) ...[
              const SizedBox(height: 16),
              if (state.isLoadingPrevious)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (state.previousResults.isNotEmpty) ...[
                _previousResults(context, state),
                const SizedBox(height: 16),
              ],
              _totalMarksField(state, ref),
              const SizedBox(height: 16),
              _marksTable(state, ref),
              const SizedBox(height: 16),
              CustomButton(
                label: state.previousResults.isNotEmpty
                    ? 'Update Marks'
                    : 'Submit All Marks',
                onPressed: () =>
                    ref.read(marksStateProvider.notifier).submitMarks(),
                loading: state.isSubmitting,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _previousResults(BuildContext context, MarksState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('Previously Entered Marks',
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
      const SizedBox(height: 8),
      ...state.previousResults.map(
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GlassCard(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(r['student_name'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                Text(
                  '${r['marks_obtained'] ?? '-'} / ${r['total_marks'] ?? state.totalMarks.toInt()}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _classSelector(MarksState state, WidgetRef ref) {
  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Class',
            style: Theme.of(ref.context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<TeacherClass>(
          initialValue: state.selectedClass,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.school),
          ),
          hint: const Text('Choose a class'),
          items: state.teacherClasses
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                        '${c.className} - ${c.section} (${c.subjectName})'),
                  ))
              .toList(),
          onChanged: (cls) {
            if (cls != null) {
              ref.read(marksStateProvider.notifier).selectClass(cls);
            }
          },
        ),
      ],
    ),
  );
}

Widget _examSelector(MarksState state, WidgetRef ref) {
  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Exam',
            style: Theme.of(ref.context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<Exam>(
          initialValue: state.selectedExam,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.assignment),
          ),
          hint: const Text('Choose an exam'),
          items: state.exams
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ))
              .toList(),
          onChanged: (exam) {
            if (exam != null) {
              ref.read(marksStateProvider.notifier).selectExam(exam);
            }
          },
        ),
      ],
    ),
  );
}

Widget _totalMarksField(MarksState state, WidgetRef ref) {
  return GlassCard(
    child: Row(
      children: [
        const Text('Max Marks: '),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextFormField(
            initialValue: state.totalMarks.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val > 0) {
                ref
                    .read(marksStateProvider.notifier)
                    .setTotalMarks(val);
              }
            },
          ),
        ),
      ],
    ),
  );
}

Widget _marksTable(MarksState state, WidgetRef ref) {
  return Column(
    children: state.students.map((student) {
      final mark = state.marks[student.id] ?? 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName,
                        style: Theme.of(ref.context)
                            .textTheme
                            .titleMedium),
                    Text(student.rollNumber ?? '',
                        style: Theme.of(ref.context)
                            .textTheme
                            .bodyMedium),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: mark == 0 ? '' : mark.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Marks',
                    suffixText: '/${state.totalMarks.toInt()}',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    if (val != null) {
                      final clamped =
                          val.clamp(0, state.totalMarks).toDouble();
                      ref
                          .read(marksStateProvider.notifier)
                          .setMark(student.id, clamped);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}
