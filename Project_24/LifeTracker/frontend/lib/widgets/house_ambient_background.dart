import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/local_auth_provider.dart';
import '../theme/house_theme.dart';

/// Wraps any screen or main scaffold with a dynamic House-themed background
/// featuring multi-stop radial house gradients and unique 60fps ambient particle animations:
/// - Stark: Crystalline 6-Branch Snowflakes & Ice Dust ❄️
/// - Targaryen: Rising Dragon Flame Shapes & Glowing Fire Embers 🔥
/// - Lannister: 4-Point Golden Starbursts & Sparkling Gold Dust ✨
/// - Baratheon: Electric Zig-Zag Lightning & Storm Energy Pulses ⚡
/// - Tyrell: Rotating Rose Petals & Emerald Leaves 🌸
/// - Greyjoy: Concentric Sea Ripple Rings & Ocean Bubbles 🫧
/// - Martell: Radiating Sunburst Rays & Solar Flares ☀️
/// - Arryn: Fluffy Mountain Cloud Puffs & Feather Wisps ☁️
/// - Tully: Flowing River Current Sine-Waves & Foam 🌊
class HouseAmbientBackground extends StatefulWidget {
  const HouseAmbientBackground({
    super.key,
    this.child,
    this.houseKeyOverride,
  });

  final Widget? child;
  final String? houseKeyOverride;

  @override
  State<HouseAmbientBackground> createState() => _HouseAmbientBackgroundState();
}

class _HouseAmbientBackgroundState extends State<HouseAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();
  TextPainter? _cachedWatermarkPainter;
  String? _watermarkCacheKey;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _particles = List.generate(36, (index) => _Particle.random(_random));
  }

  TextPainter _getWatermarkPainter(HouseTheme house, Color accentColor, bool isDark) {
    final cacheKey = '${house.key}-$isDark-${accentColor.toARGB32()}';
    if (_cachedWatermarkPainter == null || _watermarkCacheKey != cacheKey) {
      _watermarkCacheKey = cacheKey;
      _cachedWatermarkPainter = TextPainter(
        text: TextSpan(
          text: house.sigil,
          style: TextStyle(
            fontSize: 180,
            color: accentColor.withValues(alpha: isDark ? 0.05 : 0.08),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    return _cachedWatermarkPainter!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<LocalAuthProvider>();
    final activeKey = widget.houseKeyOverride ?? auth.houseKey ?? 'stark';
    final house = HouseTheme.fromKey(activeKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final watermarkPainter = _getWatermarkPainter(house, house.accent, isDark);

    return Stack(
      children: [
        // 1. Rich House Gradient Background
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.6),
                radius: 1.5,
                colors: _getHouseGradient(house, isDark),
              ),
            ),
          ),
        ),

        // 2. Animated House Particle Canvas
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _HouseParticlePainter(
                    particles: _particles,
                    progress: _controller.value,
                    houseKey: house.key,
                    accentColor: house.accent,
                    isDark: isDark,
                    watermarkPainter: watermarkPainter,
                  ),
                );
              },
            ),
          ),
        ),

        // 3. Page Content Overlay
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }

  List<Color> _getHouseGradient(HouseTheme house, bool isDark) {
    switch (house.key) {
      case 'stark':
        return isDark
            ? const [Color(0xFF1E2A3A), Color(0xFF111824), Color(0xFF090E16)]
            : const [Color(0xFFE8F2FA), Color(0xFFC7DDF2), Color(0xFF9CBEE0)];
      case 'targaryen':
        return isDark
            ? const [Color(0xFF4A0E0E), Color(0xFF2B0707), Color(0xFF120303)]
            : const [Color(0xFFFCE8E8), Color(0xFFF7C3C3), Color(0xFFE88A8A)];
      case 'lannister':
        return isDark
            ? const [Color(0xFF4A380E), Color(0xFF2B2007), Color(0xFF120E03)]
            : const [Color(0xFFFCF6E8), Color(0xFFF7E6BD), Color(0xFFE8C97B)];
      case 'baratheon':
        return isDark
            ? const [Color(0xFF45300B), Color(0xFF271A05), Color(0xFF110B02)]
            : const [Color(0xFFFCF5E6), Color(0xFFF5DFB3), Color(0xFFE5BF73)];
      case 'tyrell':
        return isDark
            ? const [Color(0xFF1C3A1A), Color(0xFF0F220E), Color(0xFF060F06)]
            : const [Color(0xFFEEFAF0), Color(0xFFC6F2CB), Color(0xFF90DC9B)];
      case 'greyjoy':
        return isDark
            ? const [Color(0xFF133242), Color(0xFF0A1D27), Color(0xFF040C11)]
            : const [Color(0xFFE6F5FC), Color(0xFFBBE5F7), Color(0xFF80C9E8)];
      case 'martell':
        return isDark
            ? const [Color(0xFF4D240E), Color(0xFF2D1407), Color(0xFF130802)]
            : const [Color(0xFFFCF1E8), Color(0xFFF7D9C3), Color(0xFFE8AC83)];
      case 'arryn':
        return isDark
            ? const [Color(0xFF183254), Color(0xFF0E1C30), Color(0xFF050B14)]
            : const [Color(0xFFEBF3FC), Color(0xFFBFDAF7), Color(0xFF85B6EA)];
      case 'tully':
        return isDark
            ? const [Color(0xFF123447), Color(0xFF091F2B), Color(0xFF030D12)]
            : const [Color(0xFFE6F6FC), Color(0xFFBAEBF8), Color(0xFF7DD5ED)];
      default:
        return isDark
            ? const [Color(0xFF1C2430), Color(0xFF10151E), Color(0xFF080B10)]
            : const [Color(0xFFF4EFE5), Color(0xFFE6DCC9), Color(0xFFC7B9A3)];
    }
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.baseOpacity,
    required this.oscillationSpeed,
    required this.rotation,
  });

  factory _Particle.random(math.Random rand) {
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      size: 4.0 + rand.nextDouble() * 8.0,
      speed: 0.12 + rand.nextDouble() * 0.35,
      baseOpacity: 0.3 + rand.nextDouble() * 0.55,
      oscillationSpeed: 0.8 + rand.nextDouble() * 2.0,
      rotation: rand.nextDouble() * math.pi * 2,
    );
  }

  double x;
  double y;
  double size;
  double speed;
  double baseOpacity;
  double oscillationSpeed;
  double rotation;
}

class _HouseParticlePainter extends CustomPainter {
  _HouseParticlePainter({
    required this.particles,
    required this.progress,
    required this.houseKey,
    required this.accentColor,
    required this.isDark,
    required this.watermarkPainter,
  });

  final List<_Particle> particles;
  final double progress;
  final String houseKey;
  final Color accentColor;
  final bool isDark;
  final TextPainter watermarkPainter;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw pre-cached House Sigil Watermark
    watermarkPainter.paint(canvas, Offset(size.width - 190, size.height * 0.08));

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      switch (houseKey) {
        case 'stark':
          _drawSnowflake(canvas, size, p, paint, strokePaint, i);
          break;
        case 'targaryen':
          _drawFireEmber(canvas, size, p, paint, i);
          break;
        case 'lannister':
          _drawGoldSparkle(canvas, size, p, paint, strokePaint, i);
          break;
        case 'baratheon':
          _drawLightningSparks(canvas, size, p, paint, strokePaint, i);
          break;
        case 'tyrell':
          _drawRosePetal(canvas, size, p, paint, i);
          break;
        case 'greyjoy':
          _drawSeaRipples(canvas, size, p, paint, strokePaint, i);
          break;
        case 'martell':
          _drawSunRays(canvas, size, p, paint, strokePaint, i);
          break;
        case 'arryn':
          _drawCloudPuff(canvas, size, p, paint, i);
          break;
        case 'tully':
          _drawRiverCurrent(canvas, size, p, strokePaint, i);
          break;
        default:
          _drawSnowflake(canvas, size, p, paint, strokePaint, i);
          break;
      }
    }
  }

  // ❄️ STARK: Crystalline 6-Branch Snowflakes & Ice Crystals
  void _drawSnowflake(Canvas canvas, Size size, _Particle p, Paint paint, Paint strokePaint, int index) {
    final yPos = ((p.y + progress * p.speed * 0.25) % 1.0) * size.height;
    final xSway = math.sin((progress * math.pi * 2 * p.oscillationSpeed) + index) * 20;
    final xPos = ((p.x * size.width + xSway) % size.width);

    final opacity = (p.baseOpacity * (0.6 + 0.4 * math.sin(progress * math.pi * 3 + index))).clamp(0.0, 1.0);
    final color = isDark ? const Color(0xFFD6E4F0) : const Color(0xFF4A6B82);

    if (index % 3 == 0) {
      // Draw 6-arm Crystalline Snowflake
      strokePaint.color = color.withValues(alpha: opacity * 0.85);
      strokePaint.strokeWidth = 1.2;
      final radius = p.size * 1.5;

      for (var a = 0; a < 6; a++) {
        final angle = (a * math.pi / 3) + p.rotation + progress;
        final dx = math.cos(angle) * radius;
        final dy = math.sin(angle) * radius;
        canvas.drawLine(Offset(xPos, yPos), Offset(xPos + dx, yPos + dy), strokePaint);

        // Branch crossbar
        final branchDx = math.cos(angle) * radius * 0.6;
        final branchDy = math.sin(angle) * radius * 0.6;
        final cross1 = angle + math.pi / 4;
        final cross2 = angle - math.pi / 4;
        canvas.drawLine(
          Offset(xPos + branchDx, yPos + branchDy),
          Offset(xPos + branchDx + math.cos(cross1) * 3, yPos + branchDy + math.sin(cross1) * 3),
          strokePaint,
        );
        canvas.drawLine(
          Offset(xPos + branchDx, yPos + branchDy),
          Offset(xPos + branchDx + math.cos(cross2) * 3, yPos + branchDy + math.sin(cross2) * 3),
          strokePaint,
        );
      }
    } else {
      // Soft falling ice dust
      paint.color = color.withValues(alpha: opacity * 0.6);
      canvas.drawCircle(Offset(xPos, yPos), p.size * 0.6, paint);
      paint.color = Colors.white.withValues(alpha: opacity * 0.9);
      canvas.drawCircle(Offset(xPos, yPos), p.size * 0.25, paint);
    }
  }

  // 🔥 TARGARYEN: Rising Flame Teardrops & Fiery Embers
  void _drawFireEmber(Canvas canvas, Size size, _Particle p, Paint paint, int index) {
    final yPos = ((p.y - progress * p.speed * 0.45) % 1.0) * size.height;
    final normalizedY = (yPos < 0) ? yPos + size.height : yPos;
    final xSway = math.sin((progress * math.pi * 2 * p.oscillationSpeed) + index) * 24;
    final xPos = ((p.x * size.width + xSway) % size.width);

    final flicker = (0.5 + 0.5 * math.sin(progress * math.pi * 8 + index * 4)).clamp(0.1, 1.0);

    if (index % 2 == 0) {
      // Draw Flame Shape
      final flameHeight = p.size * 2.2;
      final flameWidth = p.size * 1.2;
      final path = Path()
        ..moveTo(xPos, normalizedY - flameHeight)
        ..cubicTo(
          xPos + flameWidth, normalizedY - flameHeight * 0.3,
          xPos + flameWidth * 0.8, normalizedY,
          xPos, normalizedY,
        )
        ..cubicTo(
          xPos - flameWidth * 0.8, normalizedY,
          xPos - flameWidth, normalizedY - flameHeight * 0.3,
          xPos, normalizedY - flameHeight,
        );

      final color = index % 4 == 0 ? const Color(0xFFFF3D00) : const Color(0xFFFF9100);
      paint.color = color.withValues(alpha: p.baseOpacity * flicker * 0.7);
      canvas.drawPath(path, paint);
    } else {
      // Fiery Ember Spark
      paint.color = const Color(0xFFFFEA00).withValues(alpha: p.baseOpacity * flicker * 0.9);
      canvas.drawCircle(Offset(xPos, normalizedY), p.size * 0.7, paint);
    }
  }

  // ✨ LANNISTER: 4-Point Golden Starbursts & Shimmering Gold Coins
  void _drawGoldSparkle(Canvas canvas, Size size, _Particle p, Paint paint, Paint strokePaint, int index) {
    final yPos = ((p.y + math.sin(progress * math.pi * 2 + index) * 0.04) % 1.0) * size.height;
    final xPos = p.x * size.width;

    final pulse = (0.3 + 0.7 * math.pow(math.sin(progress * math.pi * 4 + index * 2), 2)).toDouble().clamp(0.0, 1.0);
    final goldColor = const Color(0xFFFFD700);

    if (index % 2 == 0) {
      // 4-Point Starburst
      strokePaint.color = goldColor.withValues(alpha: p.baseOpacity * pulse * 0.9);
      strokePaint.strokeWidth = 1.4;
      final ray = p.size * 1.8 * (0.7 + 0.3 * pulse);

      canvas.drawLine(Offset(xPos - ray, yPos), Offset(xPos + ray, yPos), strokePaint);
      canvas.drawLine(Offset(xPos, yPos - ray), Offset(xPos, yPos + ray), strokePaint);

      paint.color = Colors.white.withValues(alpha: p.baseOpacity * pulse);
      canvas.drawCircle(Offset(xPos, yPos), p.size * 0.4, paint);
    } else {
      // Golden Coin / Sparkle Dot
      paint.color = goldColor.withValues(alpha: p.baseOpacity * pulse * 0.7);
      canvas.drawCircle(Offset(xPos, yPos), p.size * 0.9, paint);
    }
  }

  // ⚡ BARATHEON: Electric Zig-Zag Lightning Bolts & Amber Sparks
  void _drawLightningSparks(Canvas canvas, Size size, _Particle p, Paint paint, Paint strokePaint, int index) {
    final xPos = ((p.x + progress * p.speed * 0.3) % 1.0) * size.width;
    final yPos = p.y * size.height;

    final flash = (math.sin(progress * math.pi * 6 + index * 3) > 0.8) ? 1.0 : 0.2;
    final amber = const Color(0xFFFFC107);

    if (index % 4 == 0) {
      // Zig-Zag Lightning Arc
      strokePaint.color = amber.withValues(alpha: p.baseOpacity * flash * 0.95);
      strokePaint.strokeWidth = 1.6;

      final path = Path()
        ..moveTo(xPos, yPos)
        ..lineTo(xPos + 6, yPos + 8)
        ..lineTo(xPos - 4, yPos + 16)
        ..lineTo(xPos + 8, yPos + 26);

      canvas.drawPath(path, strokePaint);
    } else {
      // Amber Energy Particle
      paint.color = amber.withValues(alpha: p.baseOpacity * flash);
      canvas.drawCircle(Offset(xPos, yPos), p.size * 1.0, paint);
    }
  }

  // 🌸 TYRELL: Spinning Rose Petals & Emerald Leaves
  void _drawRosePetal(Canvas canvas, Size size, _Particle p, Paint paint, int index) {
    final yPos = ((p.y + progress * p.speed * 0.25) % 1.0) * size.height;
    final xSway = math.sin((progress * math.pi * 2 * p.oscillationSpeed) + index) * 26;
    final xPos = ((p.x * size.width + xSway) % size.width);

    final opacity = p.baseOpacity * 0.7;
    final color = index % 3 == 0
        ? const Color(0xFFF48FB1) // Rose pink
        : (index % 2 == 0 ? const Color(0xFFA5D6A7) : const Color(0xFFC8E6C9)); // Emerald leaf

    paint.color = color.withValues(alpha: opacity);

    canvas.save();
    canvas.translate(xPos, yPos);
    canvas.rotate(p.rotation + progress * math.pi * 2);

    // Rose Petal / Leaf Curved Shape
    final path = Path()
      ..moveTo(0, -p.size * 1.4)
      ..quadraticBezierTo(p.size * 1.2, -p.size * 0.4, p.size * 0.8, p.size * 1.2)
      ..quadraticBezierTo(0, p.size * 1.6, -p.size * 0.8, p.size * 1.2)
      ..quadraticBezierTo(-p.size * 1.2, -p.size * 0.4, 0, -p.size * 1.4);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  // 🫧 GREYJOY: Concentric Sea Ripple Rings & Ocean Bubbles
  void _drawSeaRipples(Canvas canvas, Size size, _Particle p, Paint paint, Paint strokePaint, int index) {
    final yPos = ((p.y - progress * p.speed * 0.25) % 1.0) * size.height;
    final normalizedY = (yPos < 0) ? yPos + size.height : yPos;
    final xSway = math.sin((progress * math.pi * 2 * p.oscillationSpeed) + index) * 16;
    final xPos = ((p.x * size.width + xSway) % size.width);

    final cyan = const Color(0xFF26C6DA);

    if (index % 3 == 0) {
      // Expanding Water Ripple Ring
      final expansion = (progress * 2 + index * 0.3) % 1.0;
      strokePaint.color = cyan.withValues(alpha: p.baseOpacity * (1.0 - expansion) * 0.6);
      strokePaint.strokeWidth = 1.2;
      canvas.drawCircle(Offset(xPos, normalizedY), p.size * 1.8 * (0.5 + expansion), strokePaint);
    } else {
      // Ocean Bubble with highlight
      strokePaint.color = cyan.withValues(alpha: p.baseOpacity * 0.65);
      strokePaint.strokeWidth = 1.3;
      canvas.drawCircle(Offset(xPos, normalizedY), p.size * 1.1, strokePaint);

      paint.color = Colors.white.withValues(alpha: p.baseOpacity * 0.4);
      canvas.drawCircle(Offset(xPos - p.size * 0.3, normalizedY - p.size * 0.3), p.size * 0.3, paint);
    }
  }

  // ☀️ MARTELL: Radiating Sunburst Rays & Solar Flares
  void _drawSunRays(Canvas canvas, Size size, _Particle p, Paint paint, Paint strokePaint, int index) {
    final yPos = ((p.y - progress * p.speed * 0.18) % 1.0) * size.height;
    final normalizedY = (yPos < 0) ? yPos + size.height : yPos;
    final xPos = p.x * size.width;

    final glow = (0.4 + 0.6 * math.sin(progress * math.pi * 3 + index)).clamp(0.0, 1.0);
    final orange = const Color(0xFFFF7043);

    if (index % 3 == 0) {
      // Radiating Sunburst Rays
      strokePaint.color = orange.withValues(alpha: p.baseOpacity * glow * 0.6);
      strokePaint.strokeWidth = 1.2;
      final rayLength = p.size * 2.0;

      for (var r = 0; r < 8; r++) {
        final angle = r * math.pi / 4 + progress;
        canvas.drawLine(
          Offset(xPos, normalizedY),
          Offset(xPos + math.cos(angle) * rayLength, normalizedY + math.sin(angle) * rayLength),
          strokePaint,
        );
      }
      paint.color = const Color(0xFFFFD54F).withValues(alpha: p.baseOpacity * glow);
      canvas.drawCircle(Offset(xPos, normalizedY), p.size * 0.6, paint);
    } else {
      // Solar Flare Mote
      paint.color = orange.withValues(alpha: p.baseOpacity * glow * 0.7);
      canvas.drawCircle(Offset(xPos, normalizedY), p.size * 1.2, paint);
    }
  }

  // ☁️ ARRYN: Fluffy Mountain Cloud Puffs & Feather Wisps
  void _drawCloudPuff(Canvas canvas, Size size, _Particle p, Paint paint, int index) {
    final xPos = ((p.x + progress * p.speed * 0.12) % 1.0) * size.width;
    final yPos = p.y * size.height;

    final cloudColor = isDark ? const Color(0xFF78909C) : const Color(0xFFB0BEC5);
    paint.color = cloudColor.withValues(alpha: p.baseOpacity * 0.35);

    // Overlapping Circles forming Cloud Puff
    final r = p.size * 2.5;
    canvas.drawCircle(Offset(xPos, yPos), r, paint);
    canvas.drawCircle(Offset(xPos - r * 0.8, yPos + r * 0.2), r * 0.7, paint);
    canvas.drawCircle(Offset(xPos + r * 0.8, yPos + r * 0.1), r * 0.75, paint);
  }

  // 🌊 TULLY: Flowing River Current Sine-Waves & Foam
  void _drawRiverCurrent(Canvas canvas, Size size, _Particle p, Paint strokePaint, int index) {
    final xPos = ((p.x + progress * p.speed * 0.35) % 1.0) * size.width;
    final yPos = p.y * size.height;

    final blue = const Color(0xFF29B6F6);
    strokePaint.color = blue.withValues(alpha: p.baseOpacity * 0.55);
    strokePaint.strokeWidth = 1.6;

    final path = Path();
    path.moveTo(xPos - 20, yPos);
    for (var dx = -20; dx <= 20; dx += 5) {
      final dy = math.sin((xPos + dx) / size.width * math.pi * 6 + progress * math.pi * 2) * 6;
      path.lineTo(xPos + dx, yPos + dy);
    }

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HouseParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.houseKey != houseKey ||
        oldDelegate.isDark != isDark;
  }
}
