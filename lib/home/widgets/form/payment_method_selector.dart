import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';
import 'package:spendwise/providers.dart';

class PaymentMethodSelector extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final iconMap = ref.watch(paymentMethodIconsProvider);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paymentMethods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final label = paymentMethods[index];
          return FilledPill(
            label: label,
            icon: iconMap[label],
            selected: selectedPaymentMethod == label,
            hasSelection: selectedPaymentMethod != null,
            onTap: () => onPaymentMethodSelected(label),
          );
        },
      ),
    );
  }
}
