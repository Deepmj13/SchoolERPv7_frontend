import 'package:flutter/material.dart';
import 'package:school_erp_teacher/core/widgets/glass_card.dart';
import 'package:school_erp_teacher/core/widgets/shimmer.dart';
import 'package:school_erp_teacher/core/widgets/skeleton_loader.dart';

class ProfileSkeletonLoader extends StatelessWidget {
  final bool scrollable;
  final double padding;

  const ProfileSkeletonLoader({
    super.key,
    this.scrollable = true,
    this.padding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        const SkeletonLoader(
          width: 96,
          height: 96,
          borderRadius: BorderRadius.all(Radius.circular(48)),
        ),
        const SizedBox(height: 16),
        const SkeletonLoader(
          width: 180,
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        const SizedBox(height: 8),
        const SkeletonLoader(
          width: 120,
          height: 14,
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            children: List.generate(4, (_) => const _ProfileRowSkeleton()),
          ),
        ),
      ],
    );

    return Shimmer(
      child: scrollable
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(padding),
              child: content,
            )
          : Padding(padding: EdgeInsets.all(padding), child: content),
    );
  }
}

class _ProfileRowSkeleton extends StatelessWidget {
  const _ProfileRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SkeletonLoader(
            width: 20,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: SkeletonLoader(
              height: 14,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          SizedBox(width: 12),
          SkeletonLoader(
            width: 60,
            height: 12,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}
