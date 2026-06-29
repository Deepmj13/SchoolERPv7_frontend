import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.surfaceDark.withValues(alpha: 0.5) 
            : AppColors.background.withValues(alpha: 0.5),
        borderRadius: borderRadius,
      ),
    );
  }
}

