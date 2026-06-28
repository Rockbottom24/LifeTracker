import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_style.dart';
import '../theme/theme_provider.dart';
import '../theme/house_theme.dart';
import '../theme/app_spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _permissionsGranted = false;
  bool _isChecking = true;
  bool _isScheduling = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    setState(() {
      _isChecking = true;
    });

    final granted = await NotificationService().arePermissionsGranted();

    setState(() {
      _permissionsGranted = granted;
      _isChecking = false;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isChecking = true;
    });

    final granted = await NotificationService().requestPermissions();

    setState(() {
      _permissionsGranted = granted;
      _isChecking = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? 'Ravens are ready to fly.' : 'Notification permission denied'),
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    await NotificationService().showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A raven has been sent.')),
      );
    }
  }

  Future<void> _scheduleReminder() async {
    setState(() {
      _isScheduling = true;
    });

    await NotificationService().scheduleDailyReminder(hour: 8, minute: 0);

    setState(() {
      _isScheduling = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily raven scheduled for 8:00 AM.')),
      );
    }
  }

  Future<void> _cancelNotifications() async {
    await NotificationService().cancelAllNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All ravens dismissed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final house = auth.house;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            _ProfileBanner(auth: auth, house: house),
            const SizedBox(height: AppSpacing.lg),
            _ThemeSection(themeProvider: themeProvider),
            const SizedBox(height: AppSpacing.lg),
            Text('Ravens', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              'Use notifications to keep your quests, studies, and provisions in order.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Permission status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_isChecking)
                      const LinearProgressIndicator()
                    else
                      Row(
                        children: [
                          Icon(
                            _permissionsGranted ? Icons.check_circle_outline : Icons.error_outline,
                            color: _permissionsGranted ? Colors.green : theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _permissionsGranted ? 'Ravens are enabled.' : 'Ravens are not enabled.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isChecking ? null : _requestPermissions,
                      child: const Text('Request Permissions'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notification actions', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _permissionsGranted ? _sendTestNotification : null,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Send Test Notification'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _permissionsGranted && !_isScheduling ? _scheduleReminder : null,
                      icon: const Icon(Icons.schedule_outlined),
                      label: const Text('Schedule Daily Reminder'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _cancelNotifications,
                      icon: const Icon(Icons.notifications_off_outlined),
                      label: const Text('Cancel All Notifications'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.auth,
    required this.house,
  });

  final AuthProvider auth;
  final HouseTheme house;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: house.bannerGradient),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(house.icon, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            auth.profileLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            house.motto,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Visual Theme', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppStyle>(
              initialValue: themeProvider.style,
              decoration: const InputDecoration(labelText: 'Theme Mode'),
              items: const [
                DropdownMenuItem(value: AppStyle.classic, child: Text('Classic Theme')),
                DropdownMenuItem(value: AppStyle.fantasy, child: Text('Fantasy Theme')),
                DropdownMenuItem(value: AppStyle.system, child: Text('System Theme')),
              ],
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setStyle(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
