import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_fees_provider.dart';

class StudentFeesScreen extends ConsumerWidget {
  const StudentFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(studentFeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fees'),
      ),
      body: feesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Failed to load: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (data) => Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryCards(context, data),
                const SizedBox(height: 24),
                Text('Fee Structure',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...data.structures.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Icon(
                            s.paid
                                ? Icons.check_circle
                                : Icons.pending,
                            color: s.paid
                                ? AppColors.success
                                : AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(s.feeType,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                if (s.dueDate != null)
                                  Text('Due: ${s.dueDate}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                              ],
                            ),
                          ),
                          Text(
                            '₹${s.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: s.paid
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (data.payments.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Payment History',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...data.payments.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long,
                                color: AppColors.info, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${p.amount.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(p.paymentDate,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ],
                              ),
                            ),
                            if (p.paymentMethod != null)
                              Text(p.paymentMethod!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCards(BuildContext context, FeesData data) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 32),
                const SizedBox(height: 8),
                Text('₹${data.totalPaid.toStringAsFixed(2)}',
                    style:
                        Theme.of(context).textTheme.titleMedium),
                Text('Paid',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.pending,
                    color: AppColors.warning, size: 32),
                const SizedBox(height: 8),
                Text('₹${data.totalPending.toStringAsFixed(2)}',
                    style:
                        Theme.of(context).textTheme.titleMedium),
                Text('Pending',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
