import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class ResponsiveFormContainer extends StatelessWidget {
  const ResponsiveFormContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= 720;

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 720;
    if (width >= 720) return 680;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
        child: child,
      ),
    );
  }
}

/// Bottom padding that accounts for keyboard insets on form screens.
double formScrollBottomPadding(BuildContext context) {
  return AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom;
}
