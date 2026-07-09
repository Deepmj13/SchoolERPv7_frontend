import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_teacher/core/theme/app_colors.dart';

import 'package:school_erp_teacher/features/teacher/domain/teacher_models.dart';
import 'package:school_erp_teacher/features/teacher/presentation/teacher_dashboard_screen.dart';

final _holidaysProvider = FutureProvider.autoDispose<List<Holiday>>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.getHolidays();
});

class TeacherHolidaysScreen extends ConsumerWidget {
  const TeacherHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(_holidaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Holidays & Events')),
      body: holidaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load holidays',
                    style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_holidaysProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (holidays) {
          if (holidays.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No holidays or events scheduled',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final grouped = <String, List<Holiday>>{};
          for (final h in holidays) {
            grouped.putIfAbsent(h.date, () => []).add(h);
          }
          final sortedDates = grouped.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayHolidays = grouped[date]!;
              final dt = DateTime.tryParse(date);
              final dayName = dt != null
                  ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      [dt.weekday - 1]
                  : '';
              final formatted = dt != null
                  ? '${dt.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]
                    } $dayName'
                  : date;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatted,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      ...dayHolidays.map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: h.isHoliday
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(h.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      if (h.description != null &&
                                          h.description!.isNotEmpty)
                                        Text(h.description!,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors
                                                    .textSecondary)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (h.isHoliday
                                            ? AppColors.success
                                            : AppColors.warning)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    h.displayType,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: h.isHoliday
                                            ? AppColors.success
                                            : AppColors.warning),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
