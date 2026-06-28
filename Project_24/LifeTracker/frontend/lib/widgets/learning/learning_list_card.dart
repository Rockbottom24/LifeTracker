import 'package:flutter/material.dart';

import '../../models/learning_session_response.dart';
import '../../theme/app_spacing.dart';
import '../../utils/learning_ui_utils.dart';
import '../app_chip.dart';
import '../lists/accent_list_card_shell.dart';

class LearningListCard extends StatelessWidget {
  const LearningListCard({
    super.key,
    required this.session,
    required this.onTap,
    this.isPendingSync = false,
  });

  final LearningSessionResponse session;
  final VoidCallback onTap;
  final bool isPendingSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = LearningUiUtils.colorFromHex(session.colorHex, theme.colorScheme);

    return AccentListCardShell(
      accentColor: accent,
      icon: LearningUiUtils.iconFromName(session.iconName),
      title: session.title,
      subtitle: session.topic,
      onTap: onTap,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: session.priorityEnum.label,
                backgroundColor: theme.colorScheme.secondaryContainer,
              ),
              AppChip(
                label: session.statusEnum.label,
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              if (session.formattedReminderTime != null)
                AppChip(
                  label: session.formattedReminderTime!,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                ),
              if (isPendingSync)
                AppChip(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Pending sync',
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: session.progressFraction,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${session.completedMinutes}/${session.plannedMinutes}m',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
