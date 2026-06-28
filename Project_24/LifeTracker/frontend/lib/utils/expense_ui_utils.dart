import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_type.dart';

class ExpenseUiUtils {
  const ExpenseUiUtils._();

  static final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  static String formatAmount(double amount) => _currencyFormat.format(amount);

  static IconData iconForType(ExpenseType type) => switch (type) {
        ExpenseType.personal => Icons.account_balance_wallet_outlined,
        ExpenseType.sharedLiving => Icons.home_work_outlined,
        ExpenseType.family => Icons.family_restroom_outlined,
      };

  static Color colorForType(ExpenseType type, ColorScheme scheme) => switch (type) {
        ExpenseType.personal => scheme.primary,
        ExpenseType.sharedLiving => scheme.tertiary,
        ExpenseType.family => scheme.secondary,
      };

  static List<Color> gradientForType(ExpenseType type, ColorScheme scheme) => switch (type) {
        ExpenseType.personal => [
            scheme.primary.withValues(alpha: 0.92),
            scheme.primaryContainer.withValues(alpha: 0.88),
          ],
        ExpenseType.sharedLiving => [
            scheme.tertiary.withValues(alpha: 0.92),
            scheme.tertiaryContainer.withValues(alpha: 0.88),
          ],
        ExpenseType.family => [
            scheme.secondary.withValues(alpha: 0.92),
            scheme.secondaryContainer.withValues(alpha: 0.88),
          ],
      };

  static String formatDate(DateTime date) => DateFormat.yMMMd().format(date);
}
