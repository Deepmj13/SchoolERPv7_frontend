import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_erp_student/core/theme/app_colors.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/features/student/domain/student_models.dart';
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
                Text('Fee Posts',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...data.posts.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _postCard(context, p),
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
          ),
        ),
      ),
    );
  }

  Widget _postCard(BuildContext context, FeePost post) {
    final allPaid = post.structures.every((s) => s.paid);
    return GlassCard(
      onTap: post.id != null
          ? () => context.go('/student/fees/${post.id}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(post.title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (post.id != null)
                const Icon(Icons.chevron_right, size: 20,
                    color: AppColors.textSecondary),
            ],
          ),
          if (post.description != null && post.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(post.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                allPaid ? Icons.check_circle : Icons.pending,
                size: 16,
                color: allPaid ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                allPaid ? 'All Paid' : '${post.structures.length} item${post.structures.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: allPaid ? AppColors.success : AppColors.warning,
                      fontSize: 12,
                    ),
              ),
              const Spacer(),
              Text(
                '₹${post.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: allPaid ? AppColors.success : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (post.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Due: ${post.dueDate}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        )),
              ],
            ),
          ],
        ],
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
