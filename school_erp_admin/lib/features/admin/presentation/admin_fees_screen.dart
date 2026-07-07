import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/data_table_widget.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

class UnpaidFilterState {
  final String? classId;
  final String paymentFilter;

  const UnpaidFilterState({this.classId, this.paymentFilter = 'all'});
}

final unpaidFilterProvider = StateProvider.autoDispose<UnpaidFilterState>((ref) => const UnpaidFilterState());

final feePostsProvider = FutureProvider.autoDispose<List<FeePost>>((ref) {
  return ref.watch(adminRepositoryProvider).getFeePosts().timeout(const Duration(seconds: 15));
});

final pendingFeesProvider = FutureProvider.autoDispose<List<FeePayment>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingFees().timeout(const Duration(seconds: 15));
});

final _classesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getClasses();
});

final unpaidFeesProvider = FutureProvider.autoDispose<List<UnpaidFeeItem>>((ref) {
  final filter = ref.watch(unpaidFilterProvider);
  return ref.watch(adminRepositoryProvider).getUnpaidFees(
    classId: filter.classId,
    paymentFilter: filter.paymentFilter,
  ).timeout(const Duration(seconds: 15));
});

class AdminFeesScreen extends ConsumerStatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  ConsumerState<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends ConsumerState<AdminFeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Fee Posts'),
            Tab(text: 'Pending Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _postsTab(isMobile),
          _pendingTab(isMobile),
        ],
      ),

    );
  }

  Widget _postsTab(bool isMobile) {
    final async = ref.watch(feePostsProvider);

    return Scaffold(
      body: async.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(feePostsProvider),
        ),
        data: (posts) =>
            isMobile ? _mobilePosts(posts) : _desktopPosts(posts),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showCreatePostSheet(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _desktopPosts(List<FeePost> posts) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              CustomButton(
                label: 'Create Fee Post',
                icon: Icons.add,
                onPressed: () => _showCreatePostDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DataTableWidget<FeePost>(
              searchHint: 'Search posts...',
              items: posts,
              emptyMessage: 'No fee posts created yet',
              columns: [
                ColumnDefinition<FeePost>(
                  header: 'Title',
                  sortable: true,
                  displayValue: (p) => p.title,
                ),
                ColumnDefinition<FeePost>(
                  header: 'Items',
                  displayValue: (p) => '${p.structures.length}',
                ),
                ColumnDefinition<FeePost>(
                  header: 'Total',
                  sortable: true,
                  displayValue: (p) =>
                      '₹${p.structures.fold(0.0, (sum, s) => sum + s.amount).toStringAsFixed(2)}',
                ),
                ColumnDefinition<FeePost>(
                  header: 'Due Date',
                  displayValue: (p) => p.dueDate ?? '-',
                ),
              ],
              actionsBuilder: (post) => IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: 'View details',
                onPressed: () => _showPostDetail(post),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobilePosts(List<FeePost> posts) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(feePostsProvider.future),
      child: posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No fee posts created yet',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final p = posts[index];
                final total = p.structures.fold(0.0, (sum, s) => sum + s.amount);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showPostDetail(p),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.structures.length} item${p.structures.length == 1 ? '' : 's'}${p.dueDate != null ? '  •  Due: ${p.dueDate}' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showPostDetail(FeePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                ),
              ],
            ),
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
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Due: ${post.dueDate}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text('Fee Items (${post.structures.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 8),
            ...post.structures.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.feeType,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(s.className ?? 'All Classes',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('₹${s.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingTab(bool isMobile) {
    final feesAsync = ref.watch(unpaidFeesProvider);
    final filter = ref.watch(unpaidFilterProvider);
    final classesAsync = ref.watch(_classesProvider);

    return Scaffold(
      body: Column(
        children: [
          _unpaidFilterBar(isMobile, feesAsync, classesAsync, filter),
          Expanded(
            child: feesAsync.when(
              loading: () => const ListSkeletonLoader(),
              error: (e, _) => ErrorRetryWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(unpaidFeesProvider),
              ),
              data: (items) =>
                  isMobile ? _mobileUnpaid(items) : _desktopUnpaid(items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unpaidFilterBar(bool isMobile, AsyncValue<List<UnpaidFeeItem>> feesAsync, AsyncValue<List<ClassModel>> classesAsync, UnpaidFilterState filter) {
    final filterWidgets = <Widget>[
      SizedBox(
        width: isMobile ? 150 : 200,
        child: classesAsync.when(
          loading: () => const SizedBox(height: 40),
          error: (_, _) => const SizedBox(height: 40),
            data: (classes) => DropdownButtonFormField<String?>(
                key: ValueKey('class_${filter.classId}'),
                initialValue: filter.classId,
            decoration: const InputDecoration(
              labelText: 'Class',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            items: [
              const DropdownMenuItem(child: Text('All Classes')),
              ...classes.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.display, overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (v) => ref.read(unpaidFilterProvider.notifier).state = UnpaidFilterState(
              classId: v,
              paymentFilter: filter.paymentFilter,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: isMobile ? 150 : 200,
        child: DropdownButtonFormField<String>(
          key: ValueKey('status_${filter.paymentFilter}'),
          initialValue: filter.paymentFilter,
          decoration: const InputDecoration(
            labelText: 'Status',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Unpaid')),
            DropdownMenuItem(value: 'none', child: Text('Fully Unpaid')),
            DropdownMenuItem(value: 'partial', child: Text('Partially Paid')),
          ],
          onChanged: (v) {
            if (v != null) {
              ref.read(unpaidFilterProvider.notifier).state = UnpaidFilterState(
                classId: filter.classId,
                paymentFilter: v,
              );
            }
          },
        ),
      ),
      const SizedBox(width: 12),
      CustomButton(
        label: 'Export Excel',
        icon: Icons.file_download_outlined,
        onPressed: feesAsync.when(
          data: (items) => items.isNotEmpty ? () => _exportExcel(items) : null,
          loading: () => null,
          error: (_, _) => null,
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 12, isMobile ? 16 : 24, 0),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: filterWidgets),
            )
          : Row(children: filterWidgets),
    );
  }

  Widget _desktopUnpaid(List<UnpaidFeeItem> items) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${items.length} unpaid item${items.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      )),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DataTableWidget<UnpaidFeeItem>(
              searchHint: 'Search students...',
              items: items,
              emptyMessage: 'All fees are paid',
              columns: [
                ColumnDefinition<UnpaidFeeItem>(
                  header: 'Student',
                  sortable: true,
                  displayValue: (i) => i.studentName,
                ),
                ColumnDefinition<UnpaidFeeItem>(
                  header: 'Class',
                  displayValue: (i) => i.className,
                ),
                ColumnDefinition<UnpaidFeeItem>(
                  header: 'Fee Type',
                  sortable: true,
                  displayValue: (i) => i.feeType,
                ),
                ColumnDefinition<UnpaidFeeItem>(
                  header: 'Amount',
                  sortable: true,
                  displayValue: (i) => '₹${i.amount.toStringAsFixed(2)} / ₹${i.totalAmount.toStringAsFixed(2)}',
                ),
                ColumnDefinition<UnpaidFeeItem>(
                  header: 'Status',
                  displayValue: (i) => i.paymentStatus,
                  width: 100,
                  displayWidget: (i) => _buildStatusChip(i.paymentStatus),
                ),
                ColumnDefinition<UnpaidFeeItem>(
                  header: 'Due Date',
                  displayValue: (i) => i.dueDate ?? '-',
                  width: 120,
                  displayWidget: (i) {
                    final isOverdue = i.dueDate != null && _isOverdue(i.dueDate!);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          i.dueDate ?? '-',
                          style: TextStyle(
                            color: isOverdue ? AppColors.error : null,
                            fontWeight: isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                        ],
                      ],
                    );
                  },
                ),
              ],
              actionsBuilder: (item) => FilledButton.tonalIcon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Pay'),
                onPressed: () => _recordPaymentDialog(item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileUnpaid(List<UnpaidFeeItem> items) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(unpaidFeesProvider.future),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('All fees are paid',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.pending_actions_rounded,
                              color: AppColors.warning, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.studentName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${item.feeType}  •  ${item.className}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.dueDate != null && _isOverdue(item.dueDate!))
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Overdue',
                                      style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                              const SizedBox(height: 6),
                              _buildStatusChip(item.paymentStatus),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${item.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.amount < item.totalAmount
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                            ),
                            if (item.amount < item.totalAmount)
                              Text(
                                '/ ₹${item.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.withValues(alpha: 0.7),
                                ),
                              ),
                            const SizedBox(height: 4),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline,
                                  color: AppColors.success, size: 22),
                              tooltip: 'Mark as Paid',
                              onPressed: () => _recordPaymentDialog(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _recordPaymentDialog(UnpaidFeeItem item) async {
    DateTime paymentDate = DateTime.now();
    String paymentMode = 'cash';
    String paymentStatus = 'paid';
    bool saving = false;
    final amountCtrl = TextEditingController(text: item.amount.toStringAsFixed(2));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Text('Record Payment'),
              const Spacer(),
              if (item.dueDate != null) ...[
                _buildOverdueChip(item.dueDate!),
              ],
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Student', item.studentName),
                _detailRow('Class', item.className),
                _detailRow('Fee Type', item.feeType),
                _detailRow('Total Fee', '₹${item.totalAmount.toStringAsFixed(2)}'),
                if (item.dueDate != null) _detailRow('Due Date', item.dueDate!),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  decoration: InputDecoration(
                    labelText: 'Amount Paid *',
                    prefixText: '₹ ',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    helperText: item.amount < item.totalAmount
                        ? 'Remaining: ₹${item.amount.toStringAsFixed(2)}'
                        : null,
                    helperStyle: TextStyle(
                      color: item.amount < item.totalAmount
                          ? AppColors.warning
                          : AppColors.success,
                      fontSize: 12,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid (Done)')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => paymentStatus = v);
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => paymentDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Payment Date *',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => paymentMode = v);
                  },
                ),
              ],
            ),
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amt = double.tryParse(amountCtrl.text.trim());
                      if (amt == null || amt <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid amount'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      final dateStr =
                          '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}';
                      try {
                        await ref.read(adminRepositoryProvider).recordFeePayment({
                          'student_id': item.studentId,
                          'fee_structure_id': item.feeStructureId,
                          'amount_paid': amt,
                          'payment_date': dateStr,
                          'payment_mode': paymentMode,
                          'status': paymentStatus,
                        });
                        ref.invalidate(unpaidFeesProvider);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Payment recorded'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isOverdue(String dueDateStr) {
    try {
      final parts = dueDateStr.split('-');
      if (parts.length != 3) return false;
      final due = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return due.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Widget _buildOverdueChip(String dueDateStr) {
    if (_isOverdue(dueDateStr)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
            SizedBox(width: 4),
            Text('Overdue', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusChip(String status) {
    if (status == 'partial') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline, size: 12, color: AppColors.warning),
            SizedBox(width: 4),
            Text('Partial', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel_outlined, size: 12, color: AppColors.error),
          SizedBox(width: 4),
          Text('Unpaid', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _exportExcel(List<UnpaidFeeItem> items) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Unpaid Fees'];

      sheet.appendRow([
        TextCellValue('Student Name'),
        TextCellValue('Class'),
        TextCellValue('Fee Type'),
        TextCellValue('Total Amount'),
        TextCellValue('Paid Amount'),
        TextCellValue('Remaining'),
        TextCellValue('Status'),
        TextCellValue('Due Date'),
      ]);

      for (final item in items) {
        final paid = item.totalAmount - item.amount;
        sheet.appendRow([
          TextCellValue(item.studentName),
          TextCellValue(item.className),
          TextCellValue(item.feeType),
          DoubleCellValue(item.totalAmount),
          DoubleCellValue(paid),
          DoubleCellValue(item.amount),
          TextCellValue(item.isPartial ? 'Partially Paid' : 'Unpaid'),
          TextCellValue(item.dueDate ?? ''),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate file'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }

      final fileNameCtrl = TextEditingController(text: 'unpaid_fees.xlsx');
      if (!mounted) return;
      final fileName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Excel Report'),
          content: TextField(
            controller: fileNameCtrl,
            decoration: const InputDecoration(
              labelText: 'File name',
              suffixText: '.xlsx',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, fileNameCtrl.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      String? result;
      if (fileName != null) {
        final name = fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx';
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final file = File('${dir.path}/$name');
          await file.writeAsBytes(fileBytes);
          result = file.path;
        }
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $result'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _showCreatePostSheet() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;
    final items = <_FeeLineItem>[];
    bool saving = false;

    final classes = await ref.read(adminRepositoryProvider).getClasses();
    if (!mounted) return;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Fee Post',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Term 1 Fees',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Brief description of this fee post',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setSheetState(() => dueDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date (optional)',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: dueDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setSheetState(() => dueDate = null),
                            )
                          : null,
                    ),
                    child: Text(
                      dueDate != null
                          ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Fee Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Item'),
                      onPressed: () {
                        setSheetState(() {
                          items.add(_FeeLineItem(typeCtrl: TextEditingController(), amountCtrl: TextEditingController()));
                        });
                      },
                    ),
                  ],
                ),
                ...items.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text('Item ${entry.key + 1}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 18, color: AppColors.error),
                                    onPressed: () {
                                      setSheetState(() => items.removeAt(entry.key));
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: entry.value.typeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Fee Type *',
                                  hintText: 'e.g. Tuition',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: entry.value.amountCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Amount *',
                                  prefixText: '₹ ',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<ClassModel>(
                                initialValue: entry.value.selectedClass,
                                decoration: const InputDecoration(
                                  labelText: 'Class (optional)',
                                ),
                                items: [
                                  const DropdownMenuItem(child: Text('All Classes')),
                                  ...classes.map((c) => DropdownMenuItem(
                                      value: c, child: Text(c.display))),
                                ],
                                onChanged: (v) {
                                  setSheetState(() => entry.value.selectedClass = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Add at least one fee item',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty || items.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Title and at least one fee item are required'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            for (final item in items) {
                              if (item.typeCtrl.text.trim().isEmpty ||
                                  item.amountCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fill all item fields or remove empty items'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                            }
                            setSheetState(() => saving = true);
                            final structures = items.map((item) {
                              final amt = double.tryParse(item.amountCtrl.text.trim());
                              return {
                                'fee_type': item.typeCtrl.text.trim(),
                                'amount': amt ?? 0,
                                if (item.selectedClass != null) 'class_id': item.selectedClass!.id,
                              };
                            }).toList();
                            final body = <String, dynamic>{
                              'title': title,
                              'structures': structures,
                            };
                            if (descCtrl.text.trim().isNotEmpty) {
                              body['description'] = descCtrl.text.trim();
                            }
                            if (dueDate != null) {
                              body['due_date'] =
                                  '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}';
                            }
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .createFeePost(body);
                              ref.invalidate(feePostsProvider);
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => saving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;
    final items = <_FeeLineItem>[];

    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<ClassModel>>(
        future: ref.read(adminRepositoryProvider).getClasses(),
        builder: (context, snapshot) {
          final classes = snapshot.data ?? [];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              title: const Text('Create Fee Post'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title *'),
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due Date (optional)',
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: dueDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () =>
                                        setDialogState(() => dueDate = null),
                                  )
                                : null,
                          ),
                          child: Text(
                            dueDate != null
                                ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                                : 'Select date',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Fee Items',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            onPressed: () {
                              setDialogState(() {
                                items.add(_FeeLineItem(
                                    typeCtrl: TextEditingController(),
                                    amountCtrl: TextEditingController()));
                              });
                            },
                          ),
                        ],
                      ),
                      ...items.asMap().entries.map(
                            (entry) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text('Item ${entry.key + 1}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 16, color: AppColors.error),
                                        onPressed: () {
                                          setDialogState(() => items.removeAt(entry.key));
                                        },
                                      ),
                                    ],
                                  ),
                                  TextField(
                                    controller: entry.value.typeCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Fee Type',
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: entry.value.amountCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                      prefixText: '₹ ',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<ClassModel>(
                                    initialValue: entry.value.selectedClass,
                                    decoration: const InputDecoration(
                                      labelText: 'Class',
                                    ),
                                    items: [
                                      const DropdownMenuItem(child: Text('All Classes')),
                                      ...classes.map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c.display))),
                                    ],
                                    onChanged: (v) {
                                      setDialogState(
                                          () => entry.value.selectedClass = v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text('Add at least one fee item',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.textSecondary)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                CustomButton(
                  label: 'Create',
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty || items.isEmpty) return;
                    for (final item in items) {
                      if (item.typeCtrl.text.trim().isEmpty ||
                          item.amountCtrl.text.trim().isEmpty) {
                        return;
                      }
                    }
                    final structures = items.map((item) {
                      final amt = double.tryParse(item.amountCtrl.text.trim());
                      return {
                        'fee_type': item.typeCtrl.text.trim(),
                        'amount': amt ?? 0,
                        if (item.selectedClass != null) 'class_id': item.selectedClass!.id,
                      };
                    }).toList();
                    final body = <String, dynamic>{
                      'title': title,
                      'structures': structures,
                    };
                    if (descCtrl.text.trim().isNotEmpty) {
                      body['description'] = descCtrl.text.trim();
                    }
                    if (dueDate != null) {
                      body['due_date'] =
                          '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}';
                    }
                    try {
                      await ref
                          .read(adminRepositoryProvider)
                          .createFeePost(body);
                      ref.invalidate(feePostsProvider);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fee post created'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeeLineItem {
  final TextEditingController typeCtrl;
  final TextEditingController amountCtrl;
  ClassModel? selectedClass;

  _FeeLineItem({
    required this.typeCtrl,
    required this.amountCtrl,
  });
}
