import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'fade_in_section.dart';

class FormSectionHeader extends StatelessWidget {
  const FormSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.index = 0,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return FadeInSection(
      index: index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            elevation: 1,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ),
    );
  }
}
