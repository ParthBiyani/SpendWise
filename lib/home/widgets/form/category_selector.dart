import 'package:flutter/material.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({
    super.key,
    required this.repository,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final TransactionsRepository repository;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late final Future<List<CategoryOption>> _sortedOptionsFuture;

  @override
  void initState() {
    super.initState();
    _sortedOptionsFuture = _buildSortedOptions();
  }

  Future<List<CategoryOption>> _buildSortedOptions() async {
    final counts = await widget.repository.fetchCategoryUsageCounts();
    final defaultOrder = <String, int>{
      for (var i = 0; i < categoryOptions.length; i++) categoryOptions[i].label: i,
    };
    final options = [...categoryOptions];
    options.sort((a, b) {
      final countDiff = (counts[b.label] ?? 0).compareTo(counts[a.label] ?? 0);
      if (countDiff != 0) return countDiff;
      return (defaultOrder[a.label] ?? 0).compareTo(defaultOrder[b.label] ?? 0);
    });
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<CategoryOption>>(
      future: _sortedOptionsFuture,
      builder: (context, snapshot) {
        final options = snapshot.data ?? categoryOptions;
        final hasSelection = widget.selectedCategory != null;
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
                    selected: widget.selectedCategory == option.label,
                    hasSelection: hasSelection,
                    selectedColor: theme.colorScheme.primary,
                    onTap: () => widget.onCategorySelected(option.label),
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
