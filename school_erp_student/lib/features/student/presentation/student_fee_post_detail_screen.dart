import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
import 'package:school_erp_student/features/student/presentation/providers/student_fees_provider.dart';

class StudentFeePostDetailScreen extends ConsumerWidget {
  final String postId;

  const StudentFeePostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(studentFeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Details')),
      body: feesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (data) {
          final post = data.posts.where((p) => p.id == postId).firstOrNull;

          if (post == null) {
            return const Center(child: Text('Fee post not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerCard(context, post),
                const SizedBox(height: 16),
                _summaryCard(context, post),
                const SizedBox(height: 16),
                Text('Fee Breakdown',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...post.structures.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _structureCard(context, s),
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
                      child: _paymentCard(context, p),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerCard(BuildContext context, FeePost post) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.title,
              style: Theme.of(context).textTheme.titleLarge),
          if (post.description != null && post.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (post.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Due: ${post.dueDate}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, FeePost post) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              context,
              icon: Icons.check_circle,
              color: AppColors.success,
              label: 'Paid',
              amount: post.totalPaid,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _summaryItem(
              context,
              icon: Icons.pending,
              color: AppColors.warning,
              label: 'Pending',
              amount: post.totalPending,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            )),
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                )),
      ],
    );
  }

  Widget _structureCard(BuildContext context, FeeDetail fee) {
    return GlassCard(
      child: Row(
        children: [
          Icon(
            fee.paid ? Icons.check_circle : Icons.pending,
            color: fee.paid ? AppColors.success : AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fee.feeType,
                    style: Theme.of(context).textTheme.titleMedium),
                if (fee.paidDate != null)
                  Text('Paid: ${fee.paidDate}',
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Text(
            '₹${fee.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: fee.paid ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(BuildContext context, FeePayment payment) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.receipt_long,
              color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${payment.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(payment.paymentDate,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (payment.paymentMethod != null)
            Text(payment.paymentMethod!,
                style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
