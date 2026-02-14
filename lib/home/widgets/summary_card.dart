import 'package:flutter/material.dart';
import 'package:spendwise/home/utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  final double netBalance;
  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netTextStyle = theme.textTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Net Balance', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(formatCurrency(netBalance), style: netTextStyle),
            const SizedBox(height: 20),
            _MetricLine(
              label: 'Net Income',
              value: formatCurrency(totalIncome),
              valueColor: theme.colorScheme.tertiary,
            ),
            _MetricLine(
              label: 'Net Expenses',
              value: formatCurrency(totalExpense),
              valueColor: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
