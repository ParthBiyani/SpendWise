import 'package:flutter/material.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.onMoneyOut,
    required this.onMoneyIn,
  });

  final VoidCallback onMoneyOut;
  final VoidCallback onMoneyIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMoneyOut,
                icon: const Icon(Icons.north_east),
                label: Text(
                  'Money Out',
                  style:
                      theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMoneyIn,
                icon: const Icon(Icons.south_west),
                label: Text(
                  'Money In',
                  style:
                      theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
