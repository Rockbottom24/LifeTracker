import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                provider.dashboard?.userName?.isNotEmpty == true
                    ? 'Hi ${provider.dashboard!.userName}, here is your momentum.'
                    : 'Your daily progress at a glance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(provider.errorMessage!),
                  ),
                )
              else ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.dashboard?.greeting ?? 'Today',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${provider.dashboard?.summary?.completedHabits ?? 0}/${provider.dashboard?.summary?.totalHabits ?? 0} habits completed',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: ((provider.dashboard?.summary?.completionPercentage ?? 0) / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(title: 'Completed', value: '${provider.dashboard?.summary?.completedHabits ?? 0}'),
                    StatCard(title: 'Pending', value: '${provider.dashboard?.summary?.pendingHabits ?? 0}'),
                    StatCard(title: 'Current Streak', value: '${provider.dashboard?.summary?.currentStreak ?? 0}'),
                    StatCard(title: 'Longest Streak', value: '${provider.dashboard?.summary?.longestStreak ?? 0}'),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Today’s habits', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if ((provider.dashboard?.todayHabits ?? []).isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No habits scheduled for today yet.'),
                    ),
                  )
                else
                  ...?provider.dashboard?.todayHabits?.map((habit) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            child: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.secondary),
                          ),
                          title: Text(habit.habitName ?? 'Habit'),
                          subtitle: Text(habit.completed ? 'Completed' : 'Pending'),
                          trailing: Icon(habit.completed ? Icons.check_circle : Icons.radio_button_unchecked),
                        ),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
