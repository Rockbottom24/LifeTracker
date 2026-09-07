import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/house_theme.dart';
import 'glass_card.dart';

/// Shared dark chronicle surface with restrained gold accents and glassmorphism.
class ChronicleCard extends StatelessWidget {
  const ChronicleCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC4B28B);

    return GlassCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      borderRadius: 24,
      onTap: onTap,
      borderColor: gold.withValues(alpha: 0.3),
      borderWidth: 1.2,
      child: child,
    );
  }
}

class ChronicleEmptyState extends StatelessWidget {
  const ChronicleEmptyState({
    super.key,
    required this.house,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final HouseTheme house;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gold = Color(0xFFC4B28B);

    return ChronicleCard(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: house.accent.withValues(alpha: 0.16),
              border: Border.all(color: gold.withValues(alpha: 0.35)),
            ),
            child: Icon(house.icon, color: gold, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
