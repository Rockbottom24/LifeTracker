import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/local_auth_provider.dart';
import '../services/user_xp_manager.dart';
import '../theme/app_spacing.dart';

class FocusShieldDialog extends StatefulWidget {
  const FocusShieldDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FocusShieldDialog(),
    );
  }

  @override
  State<FocusShieldDialog> createState() => _FocusShieldDialogState();
}

class _FocusShieldDialogState extends State<FocusShieldDialog> {
  int _selectedMinutes = 45;
  int _secondsRemaining = 45 * 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _onComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _selectedMinutes * 60;
    });
  }

  Future<void> _onComplete() async {
    // Play completion sound & heavy haptic alerts
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    HapticFeedback.vibrate();

    final xpEarned = (_selectedMinutes * 2.5).round();
    await UserXpManager.addXp(xpEarned);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔔 🛡️ Focus Shield Completed! Earned +$xpEarned XP for your Realm! 🎉',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _showCustomMinutesDialog() {
    final controller = TextEditingController(text: '30');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Custom Focus Duration'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Duration in Minutes',
            hintText: 'e.g. 25, 60, 120',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final mins = int.tryParse(controller.text.trim()) ?? 45;
              if (mins > 0) {
                setState(() {
                  _selectedMinutes = mins;
                  _secondsRemaining = mins * 60;
                });
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Set Mins'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<LocalAuthProvider>();
    final house = auth.house;
    final totalSeconds = _selectedMinutes * 60;
    final progress = totalSeconds > 0 ? (1.0 - (_secondsRemaining / totalSeconds)) : 0.0;
    final isPausedOrStarted = _secondsRemaining < totalSeconds;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      title: Row(
        children: [
          Icon(Icons.shield_rounded, color: house.accent, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Focus Shield 🛡️',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lock into Deep Work & No Social Media. Stay focused until the countdown finishes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Time Selector (if not started)
            if (!_isRunning && !isPausedOrStarted) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mins in [25, 45, 60, 90])
                    ChoiceChip(
                      label: Text('$mins Mins'),
                      selected: mins == _selectedMinutes,
                      selectedColor: house.accent,
                      labelStyle: TextStyle(
                        color: mins == _selectedMinutes ? Colors.black : theme.colorScheme.onSurface,
                        fontWeight: mins == _selectedMinutes ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedMinutes = mins;
                          _secondsRemaining = mins * 60;
                        });
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.edit_calendar_rounded, size: 14),
                    label: Text(_selectedMinutes != 25 && _selectedMinutes != 45 && _selectedMinutes != 60 && _selectedMinutes != 90 ? 'Custom: $_selectedMinutes m' : 'Custom...'),
                    onPressed: _showCustomMinutesDialog,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Timer Display Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: house.accent.withValues(alpha: 0.15),
                    color: house.accent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      house.sigil,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(_secondsRemaining),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Control Buttons Row
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (!_isRunning)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: house.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _startTimer,
                    icon: Icon(isPausedOrStarted ? Icons.play_arrow_rounded : Icons.play_arrow_rounded),
                    label: Text(
                      isPausedOrStarted ? 'Resume' : 'Start Focus',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _pauseTimer,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Pause', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (isPausedOrStarted || _isRunning)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
