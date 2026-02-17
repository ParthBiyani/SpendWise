import 'package:flutter/material.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    required this.balanceAfter,
    this.onTap,
  });

  final TransactionItem item;
  final double balanceAfter;
  final VoidCallback? onTap;

  static const Map<String, IconData> _categoryIcons = {
    'Income': Icons.currency_rupee,
    'Dining': Icons.restaurant,
    'Snacks': Icons.fastfood,
    'Shopping': Icons.shopping_bag,
    'Groceries': Icons.shopping_cart,
    'Travel': Icons.directions_car,
    'Bills': Icons.receipt_long,
    'Health': Icons.health_and_safety,
    'Education': Icons.school,
    'Investment': Icons.trending_up,
    'Personal Care': Icons.spa,
    'Entertainment': Icons.movie,
    'Gifts': Icons.card_giftcard,
    'EMIs': Icons.payments,
    'Transfers': Icons.swap_horiz,
    'Housing': Icons.home,
    'Others': Icons.category,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = item.isIncome ? theme.colorScheme.tertiary : theme.colorScheme.error;
    final formattedBalanceAfter = formatCurrency(balanceAfter, prefix: '');
    final categoryIcon = _categoryIcons[item.category] ?? Icons.category;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            categoryIcon,
            color: theme.colorScheme.primary,
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
              formattedBalanceAfter,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
