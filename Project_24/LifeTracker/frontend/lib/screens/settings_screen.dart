import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/local_auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/learning_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/expense_provider.dart';
import '../services/drive_backup_service.dart';
import '../services/google_auth_service.dart';
import '../theme/app_spacing.dart';
import '../theme/house_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Drive Backup
  bool _isBackingUp = false;
  bool _isRestoring = false;
  DateTime? _lastLocalBackup;
  DriveBackupMeta? _remoteMeta;
  bool _isLoadingRemoteMeta = true;

  late DriveBackupService _backupService;

  @override
  void initState() {
    super.initState();
    final googleAuth = context.read<GoogleAuthService>();
    _backupService = DriveBackupService(googleAuthService: googleAuth);
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() => _isLoadingRemoteMeta = true);
    final [local, remote] = await Future.wait([
      _backupService.getLastBackupTime(),
      _backupService.getRemoteBackupInfo(),
    ]);
    if (!mounted) return;
    setState(() {
      _lastLocalBackup = local as DateTime?;
      _remoteMeta = remote as DriveBackupMeta?;
      _isLoadingRemoteMeta = false;
    });
  }

  Future<void> _backupNow() async {
    setState(() => _isBackingUp = true);
    final result = await _backupService.backup();
    if (!mounted) return;
    setState(() => _isBackingUp = false);
    if (result.success) {
      setState(() => _lastLocalBackup = result.timestamp);
      _showSnack('✅ Backup to Google Drive complete!', isSuccess: true);
      _loadBackupInfo(); // refresh remote meta
    } else {
      _showSnack('❌ ${result.errorMessage}', isError: true);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ Restore from Drive?'),
        content: const Text(
          'This will OVERWRITE all your current local data with the Drive backup.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    final result = await _backupService.restore();
    if (!mounted) return;
    setState(() => _isRestoring = false);
    if (result.success) {
      if (!mounted) return;
      try {
        final authP = context.read<LocalAuthProvider>();
        final journalP = context.read<JournalProvider>();
        final mealP = context.read<MealProvider>();
        final habitP = context.read<HabitProvider>();
        final learnP = context.read<LearningProvider>();
        final workoutP = context.read<WorkoutProvider>();
        final expenseP = context.read<ExpenseProvider>();
        final dashP = context.read<DashboardProvider>();

        await authP.initialize();
        await journalP.reloadFromDisk();
        await mealP.loadDashboard();
        await habitP.loadHabits();
        await learnP.loadSessions();
        await workoutP.loadScheduleAndTemplates();
        await expenseP.loadExpenses();
        await dashP.loadDashboard();
      } catch (_) {}
      _showSnack('✅ Restore complete! Data restored successfully.', isSuccess: true);
    } else {
      _showSnack('❌ ${result.errorMessage}', isError: true);
    }
  }

  Future<void> _signOut() async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await context.read<LocalAuthProvider>().signOut();
  }

  void _showSnack(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : (isSuccess ? Colors.green.shade700 : null),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LocalAuthProvider>();
    final house = auth.house;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: [
          // ── Account Banner ──────────────────────────────────────────────
          _AccountBanner(auth: auth, house: house, onSignOut: _signOut),

          const SizedBox(height: AppSpacing.xl),

          // ── Google Drive Sync ───────────────────────────────────────────
          _SectionHeader(icon: Icons.cloud_sync_rounded, label: 'Google Drive Sync'),
          const SizedBox(height: AppSpacing.sm),
          _DriveBackupCard(
            isBackingUp: _isBackingUp,
            isRestoring: _isRestoring,
            isLoadingMeta: _isLoadingRemoteMeta,
            lastLocalBackup: _lastLocalBackup,
            remoteMeta: _remoteMeta,
            onBackup: _backupNow,
            onRestore: _restoreBackup,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader(icon: Icons.palette_outlined, label: 'Appearance'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            children: [
              _HousePickerRow(auth: auth),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Data & Privacy ──────────────────────────────────────────────
          _SectionHeader(icon: Icons.security_outlined, label: 'Data & Privacy Sanctuary'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Data Stored Locally',
                subtitle: 'All your chronicles, habits, training & nutrition live strictly on this device.',
                onTap: null,
                iconColor: Colors.blue,
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.storage_outlined,
                title: 'Encrypted SQLite Vault',
                subtitle: 'Local Drift ORM database — private & offline-first',
                onTap: null,
                iconColor: const Color(0xFFC4B28B),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── About ───────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.info_outlined, label: 'About'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.apps_rounded,
                title: 'LifeTracker',
                subtitle: 'Version 1.0.0 · Fully offline-first',
                onTap: null,
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.code_rounded,
                title: 'Architecture',
                subtitle: 'Flutter · Drift SQLite · Google Sign-In · Provider',
                onTap: null,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Sign Out ────────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ── Account Banner ─────────────────────────────────────────────────────────────

class _AccountBanner extends StatelessWidget {
  const _AccountBanner({required this.auth, required this.house, required this.onSignOut});
  final LocalAuthProvider auth;
  final HouseTheme house;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFC4B28B);
    return GlassCard(
      borderRadius: 24,
      borderColor: gold.withValues(alpha: 0.35),
      borderWidth: 1.2,
      backgroundColor: Colors.black.withValues(alpha: 0.28),
      gradient: LinearGradient(
        colors: house.bannerGradient.map((c) => c.withValues(alpha: 0.38)).toList(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
              color: Colors.white10,
            ),
            child: auth.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      auth.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(house.icon, color: Colors.white70),
                    ),
                  )
                : Icon(house.icon, color: Colors.white70, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.displayName ?? 'Traveler',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  auth.email ?? '',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'House ${house.name} · ${house.motto}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drive Backup Card ──────────────────────────────────────────────────────────

class _DriveBackupCard extends StatelessWidget {
  const _DriveBackupCard({
    required this.isBackingUp,
    required this.isRestoring,
    required this.isLoadingMeta,
    required this.lastLocalBackup,
    required this.remoteMeta,
    required this.onBackup,
    required this.onRestore,
  });

  final bool isBackingUp;
  final bool isRestoring;
  final bool isLoadingMeta;
  final DateTime? lastLocalBackup;
  final DriveBackupMeta? remoteMeta;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  static final _fmt = DateFormat('MMM d, yyyy · h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cloud_done_rounded, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google Drive Backup', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        'Backs up to your private App Data folder.\nNo one else can see your files.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // Status rows
            _BackupStatusRow(
              label: 'Last backup',
              value: lastLocalBackup != null ? _fmt.format(lastLocalBackup!) : 'Never',
              icon: Icons.backup_rounded,
              color: lastLocalBackup != null ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            if (isLoadingMeta)
              const Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Checking Drive…'),
                ],
              )
            else if (remoteMeta != null) ...[
              _BackupStatusRow(
                label: 'Drive backup date',
                value: _fmt.format(remoteMeta!.backedUpAt),
                icon: Icons.cloud_outlined,
                color: Colors.blue,
              ),
              _BackupStatusRow(
                label: 'Backup size',
                value: remoteMeta!.formattedSize,
                icon: Icons.storage_rounded,
                color: Colors.purple,
              ),
            ] else
              _BackupStatusRow(
                label: 'Drive backup',
                value: 'No backup found',
                icon: Icons.cloud_off_rounded,
                color: Colors.grey,
              ),

            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (isBackingUp || isRestoring) ? null : onBackup,
                    icon: isBackingUp
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(isBackingUp ? 'Backing up…' : 'Backup Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (isBackingUp || isRestoring || remoteMeta == null) ? null : onRestore,
                    icon: isRestoring
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_download_rounded),
                    label: Text(isRestoring ? 'Restoring…' : 'Restore'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupStatusRow extends StatelessWidget {
  const _BackupStatusRow({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ── House Picker ───────────────────────────────────────────────────────────────

class _HousePickerRow extends StatelessWidget {
  const _HousePickerRow({super.key, this.auth});
  final LocalAuthProvider? auth;

  @override
  Widget build(BuildContext context) {
    final liveAuth = context.watch<LocalAuthProvider>();
    final currentKey = liveAuth.houseKey ?? 'stark';
    final currentHouse = liveAuth.house;
    final currentName = liveAuth.displayName ?? liveAuth.userOriginalName;
    final originalName = liveAuth.userOriginalName;
    final theme = Theme.of(context);

    // Characters list starting with user's original name
    final availableCharacters = [
      originalName,
      ...currentHouse.characters.where((c) => c.toLowerCase() != originalName.toLowerCase()),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your House Allegiance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HouseTheme.houses.map((h) {
                final selected = currentKey == h.key;
                return GestureDetector(
                  onTap: () {
                    liveAuth.updateHouse(h.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? LinearGradient(colors: h.bannerGradient) : null,
                      color: selected ? null : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? h.accent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(h.icon, size: 14, color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          h.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('House Character / Champion', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Select a character to represent your House, or choose your own name.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableCharacters.map((charName) {
                final isOriginal = charName.toLowerCase() == originalName.toLowerCase();
                final isSelected = currentName.toLowerCase() == charName.toLowerCase();

                final label = isOriginal ? '$charName (Your Name)' : charName;

                return GestureDetector(
                  onTap: () {
                    liveAuth.updateCharacterName(charName);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? currentHouse.accent.withValues(alpha: 0.25)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? currentHouse.accent : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOriginal ? Icons.person_rounded : Icons.star_rounded,
                          size: 14,
                          color: isSelected ? currentHouse.accent : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Status Row ────────────────────────────────────────────────────



// ── Reusable Layout Widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant) : null),
      onTap: onTap,
    );
  }
}
