import 'package:flutter/material.dart';
import 'package:school_erp_student/core/widgets/glass_card.dart';
import 'package:school_erp_student/core/widgets/shimmer.dart';
import 'package:school_erp_student/core/widgets/skeleton_loader.dart';

class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final bool scrollable;
  final double padding;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.scrollable = true,
    this.padding = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cards = List.generate(
      itemCount,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _SkeletonCard(),
      ),
    );

    final content = scrollable
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(padding),
            children: cards,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards,
          );

    return Shimmer(child: content);
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 200,
                  height: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 10),
                SkeletonLoader(
                  width: 140,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SkeletonLoader(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}
