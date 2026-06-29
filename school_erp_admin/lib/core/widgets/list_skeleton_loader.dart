import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/widgets/skeleton_loader.dart';
import 'package:school_erp_admin/core/widgets/glass_card.dart';

class ListSkeletonLoader extends StatefulWidget {
  final int itemCount;

  const ListSkeletonLoader({super.key, this.itemCount = 5});

  @override
  State<ListSkeletonLoader> createState() => _ListSkeletonLoaderState();
}

class _ListSkeletonLoaderState extends State<ListSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: widget.itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => GlassCard(
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
        ),
      ),
    );
  }
}
