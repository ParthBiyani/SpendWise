import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/widgets/transaction_tile.dart';

class GroupedTransactionSliver extends StatelessWidget {
  const GroupedTransactionSliver({
    super.key,
    required this.groups,
    required this.balances,
    required this.selectedIds,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final List<DateGroup> groups;

  /// Maps transaction id → running balance up to that transaction.
  final Map<int, double> balances;

  final Set<int> selectedIds;
  final bool isSelectionMode;
  final void Function(TransactionItem item) onTap;
  final void Function(TransactionItem item) onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverMainAxisGroup(
      slivers: [
        for (final group in groups)
          SliverStickyHeader(
            header: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(color: Colors.white),
              child: Text(
                group.dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < group.items.length) {
                    final item = group.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TransactionTile(
                        item: item,
                        balanceAfter: balances[item.id] ?? 0,
                        isSelected: selectedIds.contains(item.id),
                        isSelectionMode: isSelectionMode,
                        onTap: () => onTap(item),
                        onLongPress: () => onLongPress(item),
                      ),
                    );
                  }
                  return const SizedBox(height: 16);
                },
                childCount: group.items.length + 1,
              ),
            ),
          ),
      ],
    );
  }
}
