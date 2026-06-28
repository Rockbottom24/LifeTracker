import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../app_card.dart';

class AccentListCardShell extends StatelessWidget {
  const AccentListCardShell({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.footer,
    this.onTap,
  });

  final Color accentColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      elevation: 1,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 5)),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            footer,
          ],
        ),
      ),
    );
  }
}
