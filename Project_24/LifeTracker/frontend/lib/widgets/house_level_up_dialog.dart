import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/house_theme.dart';
import 'glass_card.dart';

class HouseLevelUpDialog extends StatefulWidget {
  const HouseLevelUpDialog({
    super.key,
    required this.newLevel,
    required this.rankTitle,
    required this.house,
  });

  final int newLevel;
  final String rankTitle;
  final HouseTheme house;

  static Future<void> show(BuildContext context, {required int newLevel, required String rankTitle, required HouseTheme house}) {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => HouseLevelUpDialog(
        newLevel: newLevel,
        rankTitle: rankTitle,
        house: house,
      ),
    );
  }

  @override
  State<HouseLevelUpDialog> createState() => _HouseLevelUpDialogState();
}

class _HouseLevelUpDialogState extends State<HouseLevelUpDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final house = widget.house;
    const goldColor = Color(0xFFC4B28B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ScaleTransition(
        scale: _scale,
        child: GlassCard(
          borderRadius: 28,
          borderColor: house.accent.withValues(alpha: 0.6),
          borderWidth: 2,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rotating House Sigil Aura
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: house.bannerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: house.accent.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    house.sigil,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'LEVEL UP! 🎉',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: goldColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'House ${house.name} Rises to Level ${widget.newLevel}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rank: ${widget.rankTitle}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: house.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  '"${house.motto}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: house.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Glory to the Realm! ⚔️',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
