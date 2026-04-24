import 'package:flutter/material.dart';

const List<IconData> bookIconPalette = [
  Icons.menu_book_outlined,
  Icons.book_outlined,
  Icons.auto_stories,
  Icons.wallet,
  Icons.account_balance_wallet_outlined,
  Icons.savings_outlined,
  Icons.home_outlined,
  Icons.work_outline,
  Icons.shopping_bag_outlined,
  Icons.directions_car_outlined,
  Icons.flight_outlined,
  Icons.school_outlined,
  Icons.health_and_safety_outlined,
  Icons.fitness_center_outlined,
  Icons.restaurant_outlined,
  Icons.coffee_outlined,
  Icons.celebration_outlined,
  Icons.favorite_outline,
  Icons.star_outline,
  Icons.attach_money,
  Icons.currency_rupee,
  Icons.trending_up_outlined,
  Icons.business_center_outlined,
  Icons.family_restroom_outlined,
];

Future<IconData?> pickBookIcon(BuildContext context, IconData current) {
  return showModalBottomSheet<IconData>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.65,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose Icon',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: bookIconPalette.length,
                itemBuilder: (_, i) {
                  final icon = bookIconPalette[i];
                  final selected = icon.codePoint == current.codePoint;
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: selected ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
