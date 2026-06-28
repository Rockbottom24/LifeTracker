import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.loadHabits,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Habits',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Track today’s completion and undo entries in one tap.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.errorMessage != null)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('An error occurred while loading habits.')))
              else if (provider.habits.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No habits available right now.')))
              else
                ...provider.habits.map(
                  (habit) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(habit.name ?? 'Habit'),
                      subtitle: Text(habit.description ?? 'No description'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => provider.completeHabit(habit.id!.toInt()),
                            child: const Text('Complete'),
                          ),
                          OutlinedButton(
                            onPressed: () => provider.undoHabit(habit.id!.toInt()),
                            child: const Text('Undo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
