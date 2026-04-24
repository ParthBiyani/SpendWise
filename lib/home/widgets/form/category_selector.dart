import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';
import 'package:spendwise/providers.dart';

class CategorySelector extends ConsumerStatefulWidget {
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
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  Future<Map<String, int>>? _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = widget.repository.fetchCategoryUsageCounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liveCats = ref.watch(categoriesProvider).valueOrNull ?? [];

    return FutureBuilder<Map<String, int>>(
      future: _countsFuture,
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};

        final options = liveCats
            .map((c) => CategoryOption(c.name, c.icon))
            .toList()
          ..sort((a, b) {
            final countDiff =
                (counts[b.label] ?? 0).compareTo(counts[a.label] ?? 0);
            if (countDiff != 0) return countDiff;
            return liveCats.indexWhere((c) => c.name == a.label)
                .compareTo(liveCats.indexWhere((c) => c.name == b.label));
          });

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
                separatorBuilder: (_, _) => const SizedBox(width: spacing),
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
