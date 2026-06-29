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

final feeStructuresProvider = FutureProvider<List<FeeStructure>>((ref) {
  return ref.watch(adminRepositoryProvider).getFeeStructures().timeout(const Duration(seconds: 15));
});

final pendingFeesProvider = FutureProvider<List<FeePayment>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingFees().timeout(const Duration(seconds: 15));
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
            Tab(text: 'Structures'),
            Tab(text: 'Pending Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _structuresTab(isMobile),
          _pendingTab(isMobile),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showAddStructureSheet(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _structuresTab(bool isMobile) {
    final async = ref.watch(feeStructuresProvider);

    return Scaffold(
      body: async.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(feeStructuresProvider),
        ),
        data: (structures) =>
            isMobile ? _mobileStructures(structures) : _desktopStructures(structures),
      ),
    );
  }

  Widget _desktopStructures(List<FeeStructure> structures) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              CustomButton(
                label: 'Add Structure',
                icon: Icons.add,
                onPressed: () => _showAddStructureDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DataTableWidget<FeeStructure>(
              searchHint: 'Search structures...',
              items: structures,
              emptyMessage: 'No fee structures defined',
              columns: [
                ColumnDefinition<FeeStructure>(
                  header: 'Fee Type',
                  sortable: true,
                  displayValue: (s) => s.feeType,
                ),
                ColumnDefinition<FeeStructure>(
                  header: 'Amount',
                  sortable: true,
                  displayValue: (s) => '\$${s.amount.toStringAsFixed(2)}',
                ),
                ColumnDefinition<FeeStructure>(
                  header: 'Class',
                  displayValue: (s) => s.className ?? 'All Classes',
                ),
              ],
              actionsBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStructures(List<FeeStructure> structures) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(feeStructuresProvider.future),
      child: structures.isEmpty
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
                        Text('No fee structures defined',
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
              itemCount: structures.length,
              itemBuilder: (context, index) {
                final s = structures[index];
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
                              Text(s.feeType,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(s.className ?? 'All Classes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(
                          '\$${s.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _pendingTab(bool isMobile) {
    final async = ref.watch(pendingFeesProvider);

    return Scaffold(
      body: async.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(pendingFeesProvider),
        ),
        data: (payments) =>
            isMobile ? _mobilePending(payments) : _desktopPending(payments),
      ),
    );
  }

  Widget _desktopPending(List<FeePayment> payments) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: DataTableWidget<FeePayment>(
        searchHint: 'Search payments...',
        items: payments,
        emptyMessage: 'No pending payments',
        columns: [
          ColumnDefinition<FeePayment>(
            header: 'Student',
            sortable: true,
            displayValue: (p) => p.studentName ?? '-',
          ),
          ColumnDefinition<FeePayment>(
            header: 'Fee Type',
            displayValue: (p) => p.feeType ?? '-',
          ),
          ColumnDefinition<FeePayment>(
            header: 'Amount',
            sortable: true,
            displayValue: (p) => '\$${p.amountPaid.toStringAsFixed(2)}',
          ),
          ColumnDefinition<FeePayment>(
            header: 'Date',
            displayValue: (p) => p.paymentDate,
            width: 120,
          ),
        ],
        actionsBuilder: (_) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _mobilePending(List<FeePayment> payments) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(pendingFeesProvider.future),
      child: payments.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No pending payments',
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
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final p = payments[index];
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
                              Text(p.studentName ?? '-',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${p.feeType ?? '-'}  •  ${p.paymentDate}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${p.amountPaid.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddStructureSheet() async {
    final typeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    ClassModel? selClass;
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
                  'Add Fee Structure',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: typeCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Fee Type *',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClassModel>(
                  initialValue: selClass,
                  decoration: const InputDecoration(
                    labelText: 'Class (optional)',
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Classes')),
                    ...classes.map((c) => DropdownMenuItem(
                        value: c, child: Text(c.display))),
                  ],
                  onChanged: (v) =>
                      setSheetState(() => selClass = v),
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
                            final type = typeCtrl.text.trim();
                            final amountStr = amountCtrl.text.trim();
                            if (type.isEmpty || amountStr.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Fill all required fields'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            final amount = double.tryParse(amountStr);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter a valid amount'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            final body = <String, dynamic>{
                              'fee_type': type,
                              'amount': amount,
                            };
                            if (selClass != null) body['class_id'] = selClass!.id;
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .createFeeStructure(body);
                              ref.invalidate(feeStructuresProvider);
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
                        : const Text('Add Structure'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddStructureDialog() {
    final typeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    ClassModel? selClass;

    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<ClassModel>>(
        future: ref.read(adminRepositoryProvider).getClasses(),
        builder: (context, snapshot) {
          final classes = snapshot.data ?? [];
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              title: const Text('Add Fee Structure'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: typeCtrl,
                      decoration: const InputDecoration(labelText: 'Fee Type'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ClassModel>(
                      initialValue: selClass,
                      decoration: const InputDecoration(
                        labelText: 'Class (optional)',
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Classes')),
                        ...classes.map((c) => DropdownMenuItem(
                            value: c, child: Text(c.display))),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selClass = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                CustomButton(
                  label: 'Add',
                  onPressed: () async {
                    final type = typeCtrl.text.trim();
                    final amountStr = amountCtrl.text.trim();
                    if (type.isEmpty || amountStr.isEmpty) return;
                    final amount = double.tryParse(amountStr);
                    if (amount == null || amount <= 0) return;
                    final body = <String, dynamic>{
                      'fee_type': type,
                      'amount': amount,
                    };
                    if (selClass != null) body['class_id'] = selClass!.id;
                    try {
                      await ref
                          .read(adminRepositoryProvider)
                          .createFeeStructure(body);
                      ref.invalidate(feeStructuresProvider);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fee structure added'),
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