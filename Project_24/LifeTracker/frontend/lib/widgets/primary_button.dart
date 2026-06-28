import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.icon,
    this.expand = false,
  });

  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLoadingLabel = loadingLabel ?? 'Saving...';

    final button = SizedBox(
      height: AppSpacing.buttonHeight,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          elevation: 1,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: isLoading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(effectiveLoadingLabel),
                  ],
                )
              : icon != null
                  ? Row(
                      key: const ValueKey('icon'),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 10),
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Text(
                      label,
                      key: const ValueKey('label'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
