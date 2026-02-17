import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final label = filters[index];
          final isSelected = label == selected;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: theme.colorScheme.primary,
            backgroundColor: Colors.white,
            side: BorderSide(color: theme.colorScheme.primary),
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(vertical: -2),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : theme.textTheme.labelLarge?.color,
            ),
            onSelected: (_) => onSelected(label),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}
