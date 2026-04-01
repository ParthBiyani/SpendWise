import 'package:flutter/material.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.repository,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final TransactionsRepository repository;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  List<CategoryOption> _sortedOptions(List<TransactionItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    final order = <String, int>{};
    for (var i = 0; i < categoryOptions.length; i++) {
      order[categoryOptions[i].label] = i;
    }
    final options = [...categoryOptions];
    options.sort((a, b) {
      final countA = counts[a.label] ?? 0;
      final countB = counts[b.label] ?? 0;
      if (countA != countB) return countB.compareTo(countA);
      return (order[a.label] ?? 0).compareTo(order[b.label] ?? 0);
    });
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<TransactionItem>>(
      stream: repository.watchAll(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <TransactionItem>[];
        final options = _sortedOptions(items);
        final hasSelection = selectedCategory != null;
        return LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 16.0;
            final tileWidth = (constraints.maxWidth - (spacing * 4)) / 5;
            final tileSize = tileWidth.clamp(56.0, 72.0);
            return SizedBox(
              height: tileSize + 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(width: spacing),
                itemBuilder: (context, index) {
                  final option = options[index];
                  return CategoryTile(
                    label: option.label,
                    icon: option.icon,
                    size: tileSize,
                    selected: selectedCategory == option.label,
                    hasSelection: hasSelection,
                    selectedColor: theme.colorScheme.primary,
                    onTap: () => onCategorySelected(option.label),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
