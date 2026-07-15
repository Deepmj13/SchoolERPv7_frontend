import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/widgets/adaptive_layout.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';
import 'package:school_erp_admin/core/widgets/error_retry_widget.dart';
import 'package:school_erp_admin/core/widgets/list_skeleton_loader.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';
import 'package:school_erp_admin/features/admin/domain/admin_models.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_sheet.dart';
import 'package:school_erp_admin/features/admin/presentation/providers/admin_repository_provider.dart';

final announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  return ref.watch(adminRepositoryProvider).getAnnouncements().timeout(const Duration(seconds: 30));
});

class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: isMobile ? null : [
          CustomButton(
            label: 'New Post',
            icon: Icons.add,
            onPressed: () => _showCreateDialog(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: announcementsAsync.when(
        loading: () => const ListSkeletonLoader(),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
        data: (announcements) => isMobile
            ? _buildMobile(context, ref, announcements)
            : _buildDesktop(context, ref, announcements),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, List<Announcement> announcements) {
    final padding = context.isMobile ? 16.0 : 24.0;

    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_rounded, size: 64,
                color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No announcements yet'),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: ListView.builder(
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final a = announcements[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (a.isSchoolWide)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'School-wide',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (a.body != null && a.body!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(a.body!, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14,
                          color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        a.createdByEmail ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.primary.withValues(alpha: 0.7),
                        onPressed: () =>
                            _showEditDialog(context, ref, a),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.error.withValues(alpha: 0.7),
                        onPressed: () => _confirmDeleteDesktop(context, ref, a),
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

  Widget _buildMobile(BuildContext context, WidgetRef ref, List<Announcement> announcements) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(announcementsProvider.future),
      child: announcements.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_rounded, size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No announcements yet',
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
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final a = announcements[index];
                return _buildAnnouncementCard(context, ref, a);
              },
            ),
    );
  }

  Widget _buildAnnouncementCard(
      BuildContext context, WidgetRef ref, Announcement a) {
    return Dismissible(
      key: ValueKey(a.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDeleteMobile(context, ref, a),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (a.body != null && a.body!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            a.body!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (a.isSchoolWide)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'School-wide',
                        style: TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 13,
                      color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    a.createdByEmail ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                        ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showEditSheet(context, ref, a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 14,
                              color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Edit',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    _showAnnouncementForm(context, ref, null);
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, Announcement a) {
    _showAnnouncementForm(context, ref, a);
  }

  void _showAnnouncementForm(
      BuildContext context, WidgetRef ref, Announcement? existing) {
    final isEdit = existing != null;
    showDialog(
      context: context,
      builder: (_) => AdminFormDialog(
        title: isEdit ? 'Edit Announcement' : 'New Announcement',
        submitLabel: isEdit ? 'Update' : 'Post',
        fields: [
          FormFieldConfig(
            key: 'title',
            label: 'Title',
            required: true,
            initialValue: existing?.title,
          ),
          FormFieldConfig(
            key: 'body',
            label: 'Message',
            maxLines: 4,
            initialValue: existing?.body,
          ),
        ],
        onSave: (values) async {
          final repo = ref.read(adminRepositoryProvider);
          if (isEdit) {
            await repo.updateAnnouncement(existing.id, values);
          } else {
            await repo.createAnnouncement(values);
          }
          ref.invalidate(announcementsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEdit ? 'Announcement updated successfully' : 'Announcement posted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    _showAnnouncementSheet(context, ref, null);
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Announcement a) {
    _showAnnouncementSheet(context, ref, a);
  }

  Future<void> _showAnnouncementSheet(
      BuildContext context, WidgetRef ref, Announcement? existing) async {
    final isEdit = existing != null;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AdminFormSheet(
        title: isEdit ? 'Edit Announcement' : 'New Announcement',
        submitLabel: isEdit ? 'Update' : 'Post',
        fields: [
          FormFieldConfig(
            key: 'title',
            label: 'Title',
            required: true,
            initialValue: existing?.title,
            prefixIcon: const Icon(Icons.title),
          ),
          FormFieldConfig(
            key: 'body',
            label: 'Message',
            maxLines: 4,
            initialValue: existing?.body,
            prefixIcon: const Icon(Icons.message_outlined),
          ),
        ],
        onSave: (values) async {
          final repo = ref.read(adminRepositoryProvider);
          if (isEdit) {
            await repo.updateAnnouncement(existing.id, values);
          } else {
            await repo.createAnnouncement(values);
          }
          ref.invalidate(announcementsProvider);
        },
      ),
    );
  }

  Future<bool> _confirmDeleteMobile(
      BuildContext context, WidgetRef ref, Announcement a) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Announcement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete "${a.title}"? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    await ref.read(adminRepositoryProvider).deleteAnnouncement(a.id);
                    ref.invalidate(announcementsProvider);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
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
                child: const Text('Delete'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  void _confirmDeleteDesktop(
      BuildContext context, WidgetRef ref, Announcement a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Delete "${a.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Delete',
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteAnnouncement(a.id);
              ref.invalidate(announcementsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}