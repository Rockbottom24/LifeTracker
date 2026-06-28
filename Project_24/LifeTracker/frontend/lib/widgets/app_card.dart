import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.onTap,
    this.color,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: elevation,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      color: color ?? theme.colorScheme.surfaceContainerLow,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
