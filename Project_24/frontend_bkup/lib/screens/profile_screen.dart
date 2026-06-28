import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Ava Carter', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Consistency is your superpower.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Current streak'),
                trailing: Text('12 days', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Weekly focus'),
                trailing: Text('4 habits', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
