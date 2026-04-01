class TransactionItem {
  const TransactionItem({
    this.id,
    this.remarks,
    required this.category,
    required this.classType,
    required this.dateTime,
    required this.amount,
    required this.isIncome,
    required this.paymentMethod,
    this.referenceId,
    this.entryBy,
  });

  final String? remarks;
  final String category;
  final String classType; // Necessity, Desire, Investment, or Others
  final DateTime dateTime;
  final double amount;
  final bool isIncome;
  final String paymentMethod;
  final String? referenceId;
  final String? entryBy;
  final int? id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransactionItem) return false;
    if (id != null && other.id != null) return id == other.id;
    return remarks == other.remarks &&
        category == other.category &&
        classType == other.classType &&
        dateTime == other.dateTime &&
        amount == other.amount &&
        isIncome == other.isIncome &&
        paymentMethod == other.paymentMethod &&
        referenceId == other.referenceId &&
        entryBy == other.entryBy;
  }

  @override
  int get hashCode => id != null
      ? id.hashCode
      : Object.hash(
          remarks, category, classType, dateTime, amount,
          isIncome, paymentMethod, referenceId, entryBy,
        );
}
