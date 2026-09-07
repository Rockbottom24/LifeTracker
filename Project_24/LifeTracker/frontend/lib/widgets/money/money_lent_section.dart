import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/money_lent_item.dart';
import '../../providers/expense_provider.dart';
import '../../theme/app_spacing.dart';
import '../../utils/expense_ui_utils.dart';
import '../app_card.dart';
import '../fade_in_section.dart';

class MoneyLentSection extends StatelessWidget {
  const MoneyLentSection({super.key});

  void _showAddLendDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actionsOverflowDirection: VerticalDirection.down,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              const Icon(Icons.handshake_rounded, color: Color(0xFFC4B28B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lend Money',
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Money lent will be deducted from your vault savings until received back.',
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                        color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Person Name',
                    hintText: 'e.g. Ramesh',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount Lent (₹)',
                    hintText: 'e.g. 5000',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g. Emergency loan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B28B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (name.isNotEmpty && amt > 0) {
                  context.read<ExpenseProvider>().addMoneyLent(
                        name,
                        amt,
                        notes: notesController.text.trim(),
                      );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Lend Money', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = context.watch<ExpenseProvider>();
    final lentList = provider.moneyLentList;
    final outstandingList = lentList.where((item) => !item.isReceived).toList();
    final historyList = lentList.where((item) => item.isReceived).toList();
    final totalOutstanding = provider.totalOutstandingLent;
    const goldColor = Color(0xFFC4B28B);

    return FadeInSection(
      index: 1,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake_rounded, color: goldColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Money Lent Vault',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: goldColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _showAddLendDialog(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: goldColor),
                          SizedBox(width: 4),
                          Text(
                            'Lend Money',
                            style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (totalOutstanding > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Total Outstanding: ${ExpenseUiUtils.formatAmount(totalOutstanding)} (deducted from savings)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFF8A80),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (outstandingList.isEmpty && historyList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No money lent yet. Tap Lend Money to record loans.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              if (outstandingList.isNotEmpty) ...[
                Text(
                  'Currently Outstanding',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final item in outstandingList)
                  _MoneyLentTile(
                    item: item,
                    onReceived: () {
                      provider.markMoneyReceived(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${ExpenseUiUtils.formatAmount(item.amount)} received from ${item.personName} added back to Vault Savings! 🎉'),
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                      );
                    },
                    onDelete: () => provider.deleteMoneyLent(item.id),
                  ),
              ],
              if (historyList.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Received History (${historyList.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      for (final item in historyList)
                        _MoneyLentTile(
                          item: item,
                          onReceived: null,
                          onDelete: () => provider.deleteMoneyLent(item.id),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MoneyLentTile extends StatelessWidget {
  const _MoneyLentTile({
    required this.item,
    this.onReceived,
    required this.onDelete,
  });

  final MoneyLentItem item;
  final VoidCallback? onReceived;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = DateFormat.yMMMd().format(item.date);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isReceived
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : const Color(0xFFFF8A80).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: item.isReceived
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                    : const Color(0xFFFF8A80).withValues(alpha: 0.2),
                child: Icon(
                  item.isReceived ? Icons.check_circle_rounded : Icons.person_pin_rounded,
                  color: item.isReceived ? const Color(0xFF4CAF50) : const Color(0xFFFF8A80),
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.personName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                ExpenseUiUtils.formatAmount(item.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: item.isReceived ? const Color(0xFF4CAF50) : const Color(0xFFFF8A80),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 6),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isReceived
                          ? 'Received back • $dateLabel'
                          : 'Lent on $dateLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onReceived != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onReceived,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_done_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Received Back',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
