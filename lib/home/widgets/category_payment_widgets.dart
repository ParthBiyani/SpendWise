import 'package:flutter/material.dart';

/// Maps category names to their respective icons
const Map<String, IconData> categoryIcons = {
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

/// Maps payment method names to their respective icons
const Map<String, IconData> paymentMethodIcons = {
  'Cash': Icons.payments,
  'Card': Icons.credit_card,
  'Bank': Icons.account_balance,
  'UPI': Icons.qr_code,
};

/// Represents a category option with a label and icon
class CategoryOption {
  const CategoryOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// List of all available category options
const List<CategoryOption> categoryOptions = [
  CategoryOption('Income', Icons.currency_rupee),
  CategoryOption('Dining', Icons.restaurant),
  CategoryOption('Snacks', Icons.fastfood),
  CategoryOption('Shopping', Icons.shopping_bag),
  CategoryOption('Groceries', Icons.shopping_cart),
  CategoryOption('Travel', Icons.directions_car),
  CategoryOption('Bills', Icons.receipt_long),
  CategoryOption('Health', Icons.health_and_safety),
  CategoryOption('Education', Icons.school),
  CategoryOption('Investment', Icons.trending_up),
  CategoryOption('Personal Care', Icons.spa),
  CategoryOption('Entertainment', Icons.movie),
  CategoryOption('Gifts', Icons.card_giftcard),
  CategoryOption('EMIs', Icons.payments),
  CategoryOption('Transfers', Icons.swap_horiz),
  CategoryOption('Housing', Icons.home),
  CategoryOption('Others', Icons.category),
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
