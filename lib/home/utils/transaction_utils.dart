import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/formatters.dart';

List<DateGroup> groupTransactions(List<TransactionItem> items) {
  final sorted = [...items]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  final Map<String, List<TransactionItem>> grouped = {};
  for (final item in sorted) {
    grouped.putIfAbsent(formatDate(item.dateTime), () => []).add(item);
  }
  return grouped.entries
      .map((e) => DateGroup(dateLabel: e.key, items: e.value))
      .toList();
}

/// Returns a map of transaction id → running balance up to and including that
/// transaction, ordered chronologically ascending.
Map<int, double> computeRunningBalances(List<TransactionItem> items) {
  final ascending = [...items]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  double running = 0;
  final result = <int, double>{};
  for (final item in ascending) {
    running += item.isIncome ? item.amount : -item.amount;
    if (item.id != null) result[item.id!] = running;
  }
  return result;
}
