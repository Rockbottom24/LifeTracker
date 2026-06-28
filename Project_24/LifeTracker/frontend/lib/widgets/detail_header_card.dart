import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_card.dart';

class DetailHeaderCard extends StatelessWidget {
  const DetailHeaderCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.chips = const [],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      elevation: 1,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 44, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: chips,
            ),
          ],
        ],
      ),
    );
  }
}

class DetailStatChip extends StatelessWidget {
  const DetailStatChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class DetailActionsSection extends StatelessWidget {
  const DetailActionsSection({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        ...children,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : null;

    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
