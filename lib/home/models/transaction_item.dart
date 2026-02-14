class TransactionItem {
  const TransactionItem({
    required this.remarks,
    required this.category,
    required this.subcategory,
    required this.dateTime,
    required this.amount,
    required this.isIncome,
    required this.paymentMethod,
    required this.referenceId,
    required this.entryBy,
  });

  final String remarks;
  final String category;
  final String subcategory;
  final DateTime dateTime;
  final double amount;
  final bool isIncome;
  final String paymentMethod;
  final String referenceId;
  final String entryBy;

  double get balanceAfter {
    const baseline = 25000.0;
    return isIncome ? baseline + amount : baseline - amount;
  }
}
