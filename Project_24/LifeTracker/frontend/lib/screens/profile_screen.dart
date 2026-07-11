import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/profile_response.dart';
import '../navigation/app_navigator.dart';
import '../services/api_client.dart';
import '../services/profile_service.dart';
import '../theme/app_spacing.dart';
import '../theme/house_theme.dart';
import '../widgets/chronicle_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileResponse? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await context.read<ProfileService>().getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _profile == null) {
      return const LoadingView(message: 'Loading your chronicle...');
    }

    if (_error != null && _profile == null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load profile',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    final profile = _profile!;
    final house = HouseTheme.fromKey(profile.houseKey);
    const gold = Color(0xFFC4B28B);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ChronicleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: house.accent.withValues(alpha: 0.18),
                        border: Border.all(color: gold.withValues(alpha: 0.4)),
                      ),
                      child: Icon(house.icon, color: gold),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.firstName.isEmpty ? 'Traveler' : profile.firstName,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'House ${profile.houseDisplayName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: gold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile.houseMotto.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.houseMotto,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  profile.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ChronicleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seven-Day Honor',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _StatChip(label: 'Honor', value: '${profile.summary.sevenDayHonor}'),
                    _StatChip(
                      label: 'Completion',
                      value: '${profile.summary.sevenDayCompletionPercentage.round()}%',
                    ),
                    _StatChip(label: 'Streak', value: '${profile.summary.currentStreak}'),
                    _StatChip(label: 'Best', value: '${profile.summary.longestStreak}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recent Chronicle',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap a day to review habits and nutrition for that date.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (profile.recentDays.isEmpty)
            ChronicleCard(
              child: Text(
                'No recent performance yet. Complete quests to fill the chronicle.',
                style: theme.textTheme.bodyLarge,
              ),
            )
          else
            ...profile.recentDays.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ChronicleCard(
                  onTap: () => AppNavigator.openDailyPerformance(context, day.date),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d').format(day.date),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.completedHabits}/${day.plannedHabits} quests · '
                              '${day.completionPercentage.round()}% complete',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${day.earnedPoints}/${day.possiblePoints} pts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4B28B).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
