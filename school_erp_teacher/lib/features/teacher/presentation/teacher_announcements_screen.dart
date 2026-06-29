import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';
import 'package:school_erp_teacher/core/widgets/custom_button.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

final teacherAnnouncementsProvider =
    FutureProvider<List<Announcement>>((ref) {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getTeacherAnnouncements(teacherId);
});

final teacherClassesForAnnouncementsProvider =
    FutureProvider<List<TeacherClass>>((ref) {
  final teacherId = ref.watch(authStateProvider).user?.teacherId ?? '';
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getTeacherClasses(teacherId);
});

class TeacherAnnouncementsScreen extends ConsumerStatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  ConsumerState<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends ConsumerState<TeacherAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final Set<String> _selectedClassIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one class')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(teacherRepositoryProvider);
      for (final classId in _selectedClassIds) {
          await repo.createAnnouncement(
            _titleController.text.trim(),
            _bodyController.text.trim().isEmpty
                ? null
                : _bodyController.text.trim(),
            classId,
          );
        }
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _isSubmitting = false;
        _selectedClassIds.clear();
      });
      ref.invalidate(teacherAnnouncementsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Announcement posted successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(teacherAnnouncementsProvider);
    final classesAsync = ref.watch(teacherClassesForAnnouncementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Announcement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message (optional)',
                      prefixIcon: Icon(Icons.message),
                    ),
                  ),
                  const SizedBox(height: 16),
                  classesAsync.when(
                    loading: () =>
                        const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (classes) {
                      final unique = <String, String>{};
                      for (final c in classes) {
                        unique[c.classId] = c.display;
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: unique.entries.map((e) {
                          final selected =
                              _selectedClassIds.contains(e.key);
                          return FilterChip(
                            label: Text(e.value),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedClassIds.add(e.key);
                                } else {
                                  _selectedClassIds.remove(e.key);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Post Announcement',
                    onPressed: _createAnnouncement,
                    loading: _isSubmitting,
                    icon: Icons.send,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('My Announcements',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            announcementsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Failed to load: $e',
                      style: const TextStyle(color: AppColors.error)),
              data: (announcements) {
                if (announcements.isEmpty) {
                  return const GlassCard(
                    child: Center(
                      child: Text('No announcements yet'),
                    ),
                  );
                }
                return Column(
                  children: announcements.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            if (a.body != null &&
                                a.body!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(a.body!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (!a.isSchoolWide)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.info
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                        'Class-specific',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.info)),
                                  ),
                                if (!a.isSchoolWide)
                                  const SizedBox(width: 8),
                                Text(
                                  _formatDate(a.createdAt),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
