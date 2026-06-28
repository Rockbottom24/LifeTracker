import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) async {
                  await themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.api_outlined),
                title: Text('Backend endpoint'),
                subtitle: Text('Configured through SharedPreferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
