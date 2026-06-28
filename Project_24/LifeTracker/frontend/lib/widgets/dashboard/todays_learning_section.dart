import 'package:flutter/material.dart';

import '../../models/learning_session_response.dart';
import '../../models/learning_status.dart';
import '../../theme/app_spacing.dart';
import '../../utils/learning_ui_utils.dart';
import '../app_card.dart';
import '../fade_in_section.dart';
import '../primary_button.dart';
import '../section_title.dart';

class TodaysLearningSection extends StatelessWidget {
  const TodaysLearningSection({
    super.key,
    required this.sessions,
    required this.onQuickStart,
    required this.onOpenDetails,
  });

  final List<LearningSessionResponse> sessions;
  final ValueChanged<LearningSessionResponse> onQuickStart;
  final ValueChanged<int> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = sessions.where((s) => s.statusEnum != LearningStatus.completed).length;
    final completed = sessions.where((s) => s.statusEnum == LearningStatus.completed).length;
    LearningSessionResponse? next;
    for (final session in sessions) {
      if (session.statusEnum != LearningStatus.completed) {
        next = session;
        break;
      }
    }

    final upcoming = next;

    return FadeInSection(
      index: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: "Today's Learning", subtitle: 'Keep your learning momentum going.'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _StatChip(label: 'Pending', value: '$pending', color: theme.colorScheme.tertiaryContainer)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _StatChip(label: 'Completed', value: '$completed', color: theme.colorScheme.primaryContainer)),
                  ],
                ),
                if (upcoming != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: LearningUiUtils.colorFromHex(upcoming.colorHex, theme.colorScheme).withValues(alpha: 0.15),
                      child: Icon(LearningUiUtils.iconFromName(upcoming.iconName)),
                    ),
                    title: Text(upcoming.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text(upcoming.topic ?? 'Learning session'),
                    onTap: () => onOpenDetails(upcoming.id),
                  ),
                  PrimaryButton(
                    label: 'Quick Start',
                    expand: true,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => onQuickStart(upcoming),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text("You're all caught up today.", style: theme.textTheme.bodyLarge),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
