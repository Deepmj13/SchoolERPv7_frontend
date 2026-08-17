import 'package:flutter/material.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/core/widgets/shimmer.dart';
import 'package:school_erp_student/core/widgets/skeleton_loader.dart';

class DashboardSkeletonLoader extends StatelessWidget {
  final int statCount;
  final bool showListBlock;
  final bool scrollable;
  final double padding;

  const DashboardSkeletonLoader({
    super.key,
    this.statCount = 2,
    this.showListBlock = true,
    this.scrollable = true,
    this.padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLoader(
          width: 200,
          height: 26,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 10),
        SkeletonLoader(
          width: 160,
          height: 14,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            statCount,
            (_) => const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: _StatCardSkeleton(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (showListBlock) ...[
          const _BlockCardSkeleton(bars: 3),
          const SizedBox(height: 16),
          const _BlockCardSkeleton(bars: 2),
        ],
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

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 36,
            height: 36,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(height: 14),
          SkeletonLoader(
            width: 64,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          SizedBox(height: 6),
          SkeletonLoader(
            width: 48,
            height: 12,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

class _BlockCardSkeleton extends StatelessWidget {
  final int bars;
  const _BlockCardSkeleton({required this.bars});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(
            width: 120,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            bars,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
