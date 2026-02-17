class TransactionItem {
  const TransactionItem({
    this.id,
    required this.remarks,
    required this.category,
    required this.classType,
    required this.dateTime,
    required this.amount,
    required this.isIncome,
    required this.paymentMethod,
    required this.referenceId,
    required this.entryBy,
  });

  final String remarks;
  final String category;
  final String classType; // Necessity, Desire, Investment, or Others
  final DateTime dateTime;
  final double amount;
  final bool isIncome;
  final String paymentMethod;
  final String referenceId;
  final String entryBy;
  final int? id;
}
