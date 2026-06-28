import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 700),
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final display = value is int ? animatedValue.round().toString() : animatedValue.toStringAsFixed(0);
        return Text('$display$suffix', style: style);
      },
    );
  }
}
