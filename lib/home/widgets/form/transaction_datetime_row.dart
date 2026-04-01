import 'package:flutter/material.dart';
import 'package:spendwise/home/utils/formatters.dart';

class TransactionDateTimeRow extends StatelessWidget {
  const TransactionDateTimeRow({
    super.key,
    required this.dateTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime dateTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onPickDate,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  formatDate(dateTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          GestureDetector(
            onTap: onPickTime,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  formatTime(dateTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
