import 'package:flutter/material.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart' show categoryIcons;

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    required this.balanceAfter,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  final TransactionItem item;
  final double balanceAfter;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = item.isIncome ? theme.colorScheme.tertiary : theme.colorScheme.error;
    final formattedBalanceAfter = formatCurrency(balanceAfter, prefix: '');
    final categoryIcon = categoryIcons[item.category] ?? Icons.category;

    final amountLabel =
        '${item.isIncome ? 'Income' : 'Expense'} ${formatCurrency(item.amount, prefix: '')}';
    final remarksLabel =
        (item.remarks != null && item.remarks!.isNotEmpty) ? ', ${item.remarks}' : '';
    final selectionLabel = isSelectionMode
        ? (isSelected ? ', selected' : ', not selected')
        : '';
    final semanticLabel =
        '${item.category}$remarksLabel, $amountLabel, '
        'balance ${formatCurrency(balanceAfter, prefix: '')}$selectionLabel';

    return Semantics(
      label: semanticLabel,
      selected: isSelectionMode ? isSelected : null,
      button: onTap != null,
      excludeSemantics: true,
      child: Card(
      elevation: 0,
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.primary.withValues(alpha: 0.25),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: onTap,
        onLongPress: onLongPress,
        leading: CircleAvatar(
          backgroundColor: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            isSelected ? Icons.check : categoryIcon,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.category,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (item.remarks != null && item.remarks!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.remarks!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Text(
              '${item.entryBy ?? 'You'} · ${formatTime(item.dateTime)}',
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
            Text(
              'Balance:',
              style: theme.textTheme.labelSmall,
            ),
            Text(
              formattedBalanceAfter,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    ));
  }
}
