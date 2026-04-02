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
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paymentMethods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final label = paymentMethods[index];
          return FilledPill(
            label: label,
            icon: paymentMethodIcons[label],
            selected: selectedPaymentMethod == label,
            hasSelection: selectedPaymentMethod != null,
            onTap: () => onPaymentMethodSelected(label),
          );
        },
      ),
    );
  }
}
