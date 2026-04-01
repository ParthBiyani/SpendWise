import 'package:flutter/material.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
  });

  final List<String> paymentMethods;
  final String? selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodSelected;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedPaymentMethod != null;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paymentMethods.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          if (index == paymentMethods.length) {
            return _OutlinePill(
              label: 'Add',
              icon: Icons.add,
              dimmed: hasSelection,
              onTap: () {},
            );
          }
          final label = paymentMethods[index];
          return FilledPill(
            label: label,
            icon: paymentMethodIcons[label],
            selected: selectedPaymentMethod == label,
            hasSelection: hasSelection,
            onTap: () => onPaymentMethodSelected(label),
          );
        },
      ),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({
    required this.label,
    this.icon,
    this.dimmed = false,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = dimmed
        ? theme.colorScheme.primary.withValues(alpha: 0.7)
        : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 16, color: textColor),
              if (icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
