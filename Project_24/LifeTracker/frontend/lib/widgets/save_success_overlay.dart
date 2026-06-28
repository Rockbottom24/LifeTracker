import 'package:flutter/material.dart';

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

class _SaveSuccessOverlayState extends State<SaveSuccessOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );

    _controller.forward().then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.message,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
