import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SkeletonBlock(height: 180, color: color),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBlock(height: 160, color: color),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBlock(height: 120, color: color),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _SkeletonBlock(height: 100, color: color)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _SkeletonBlock(height: 100, color: color)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
