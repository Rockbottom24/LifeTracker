import 'package:flutter/material.dart';

import '../../utils/expense_ui_utils.dart';

class MoneyAnimatedAmount extends StatelessWidget {
  const MoneyAnimatedAmount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          ExpenseUiUtils.formatAmount(animatedValue),
          style: style,
        );
      },
    );
  }
}
