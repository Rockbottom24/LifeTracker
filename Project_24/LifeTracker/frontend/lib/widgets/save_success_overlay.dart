import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/local_auth_provider.dart';
import '../theme/house_theme.dart';

class SaveSuccessOverlay extends StatefulWidget {
  const SaveSuccessOverlay({
    super.key,
    required this.message,
    required this.onComplete,
  });

  final String message;
  final VoidCallback onComplete;

  @override
  State<SaveSuccessOverlay> createState() => _SaveSuccessOverlayState();
}

class _SaveSuccessOverlayState extends State<SaveSuccessOverlay> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _rotationController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );

    _controller.forward().then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<LocalAuthProvider>();
    final house = HouseTheme.fromKey(auth.houseKey);
    const gold = Color(0xFFC4B28B);

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: house.bannerGradient.map((c) => c.withValues(alpha: 0.85)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: house.accent.withValues(alpha: 0.6), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: house.accent.withValues(alpha: 0.45),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated House Crest Ring with Orbiting Particles
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(120, 120),
                            painter: _HouseBurstPainter(
                              houseKey: house.key,
                              accentColor: house.accent,
                              progress: _rotationController.value,
                            ),
                          ),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.5),
                              border: Border.all(color: gold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: house.accent.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(house.icon, size: 32, color: gold),
                                const SizedBox(height: 2),
                                Text(
                                  house.sigil,
                                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Success Message
                  Text(
                    widget.message,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // House Motto Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '"${house.motto}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: gold,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HouseBurstPainter extends CustomPainter {
  _HouseBurstPainter({
    required this.houseKey,
    required this.accentColor,
    required this.progress,
  });

  final String houseKey;
  final Color accentColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angle = progress * 2 * math.pi;

    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw orbiting house particles around the seal
    const particleCount = 8;
    for (int i = 0; i < particleCount; i++) {
      final currentAngle = angle + (i * 2 * math.pi / particleCount);
      final x = center.dx + math.cos(currentAngle) * (radius - 8);
      final y = center.dy + math.sin(currentAngle) * (radius - 8);

      switch (houseKey.toLowerCase()) {
        case 'stark':
          // Snowflake crystals ❄️
          canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = const Color(0xFFC0D8F0));
          canvas.drawLine(
            Offset(x - 4, y),
            Offset(x + 4, y),
            Paint()..color = Colors.white..strokeWidth = 1,
          );
          break;
        case 'targaryen':
          // Dragon Fire Embers 🔥
          canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = const Color(0xFFFF5533));
          canvas.drawCircle(Offset(x, y), 2.0, Paint()..color = const Color(0xFFFFCC00));
          break;
        case 'lannister':
          // Lion Gold Sunburst ✨
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = const Color(0xFFFFD700));
          break;
        case 'baratheon':
          // Lightning Sparks ⚡
          final path = Path()
            ..moveTo(x, y - 5)
            ..lineTo(x - 2, y)
            ..lineTo(x + 1, y)
            ..lineTo(x - 1, y + 5);
          canvas.drawPath(path, Paint()..color = const Color(0xFFFFCC00)..style = PaintingStyle.stroke..strokeWidth = 1.5);
          break;
        case 'tyrell':
          // Rose Petals 🌸
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = const Color(0xFFFFB7C5));
          break;
        case 'greyjoy':
          // Sea Ripples 🌊
          canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = const Color(0xFF4DD0E1)..style = PaintingStyle.stroke..strokeWidth = 1.2);
          break;
        case 'martell':
          // Sunburst Rays ☀️
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = const Color(0xFFFF9800));
          break;
        case 'arryn':
          // Falcon Wind Puffs ☁️
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white70);
          break;
        case 'tully':
          // River Waves 🐟
          canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = const Color(0xFF81D4FA));
          break;
        default:
          canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HouseBurstPainter oldDelegate) => true;
}
