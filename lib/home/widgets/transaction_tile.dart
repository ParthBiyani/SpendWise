import 'package:flutter/material.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});

  final TransactionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = item.isIncome ? theme.colorScheme.tertiary : theme.colorScheme.error;
    final balanceAfter = formatCurrency(item.balanceAfter, prefix: '');
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            item.isIncome ? Icons.south_west : Icons.north_east,
            color: amountColor,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.category,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            // const SizedBox(height: 4),
            Text(item.remarks, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              '${item.entryBy} · ${formatTime(item.dateTime)}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatCurrency(item.amount, prefix: item.isIncome ? '+' : '-'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
            // const SizedBox(height: 4),
            Text(
              'Balance:',
              style: theme.textTheme.labelSmall,
            ),
            Text(
              balanceAfter,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
