import 'package:flutter/material.dart';
import 'package:spendwise/config/constants.dart';

/// Maps category names to their icons. Derived from [categories] in constants.dart.
final Map<String, IconData> categoryIcons = {
  for (final c in categories) c.name: c.icon,
};

/// Maps payment method names to their icons. Derived from [paymentMethods] in constants.dart.
final Map<String, IconData> paymentMethodIcons = {
  for (final p in paymentMethods) p.name: p.icon,
};

/// Represents a category option with a label and icon.
class CategoryOption {
  const CategoryOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// All available category options, derived from [categories] in constants.dart.
final List<CategoryOption> categoryOptions = [
  for (final c in categories) CategoryOption(c.name, c.icon),
];

/// A tile widget for displaying a category with an icon
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.size,
    required this.selected,
    this.hasSelection = false,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double size;
  final bool selected;
  final bool hasSelection;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmedColor = theme.colorScheme.primary.withValues(alpha: 0.7);
    final labelColor = selected
        ? theme.colorScheme.primary
        : (hasSelection ? dimmedColor : theme.textTheme.labelLarge?.color);
    final iconColor = selected
        ? Colors.white
        : (hasSelection ? dimmedColor : theme.colorScheme.primary);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: selected ? selectedColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Icon(
                    icon,
                    key: ValueKey<Color>(iconColor),
                    size: size * 0.38,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ) ?? const TextStyle(),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pill-shaped widget for displaying payment methods
class FilledPill extends StatelessWidget {
  const FilledPill({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    this.hasSelection = false,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmedColor = theme.colorScheme.primary.withValues(alpha: 0.7);
    final textColor = selected
        ? Colors.white
        : (hasSelection ? dimmedColor : theme.colorScheme.primary);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
              if (icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
