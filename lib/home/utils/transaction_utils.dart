import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/date_filters.dart';
import 'package:spendwise/home/utils/formatters.dart';

List<TransactionItem> applyFilter(
  List<TransactionItem> items,
  FilterState filterState,
) {
  final DateTime now = DateTime.now();
  return items.where((item) {
    bool dateMatch = true;
    switch (filterState.dateFilter) {
      case 'Today':
        dateMatch = isSameDay(item.dateTime, now);
        break;
      case 'This Week':
        dateMatch = isSameWeek(item.dateTime, now);
        break;
      case 'This Month':
        dateMatch =
            item.dateTime.year == now.year && item.dateTime.month == now.month;
        break;
      case 'This Year':
        dateMatch = item.dateTime.year == now.year;
        break;
      case 'Custom Range':
        final start = filterState.customStartDate;
        final end = filterState.customEndDate;
        if (start != null && end != null) {
          dateMatch =
              !item.dateTime.isBefore(start) && !item.dateTime.isAfter(end);
        } else if (start != null) {
          dateMatch = !item.dateTime.isBefore(start);
        } else if (end != null) {
          dateMatch = !item.dateTime.isAfter(end);
        } else {
          dateMatch = true;
        }
        break;
      case 'All Time':
      default:
        dateMatch = true;
    }
    if (!dateMatch) return false;

    if (filterState.categories.isNotEmpty &&
        !filterState.categories.contains(item.category)) {
      return false;
    }

    if (filterState.paymentMethods.isNotEmpty &&
        !filterState.paymentMethods.contains(item.paymentMethod)) {
      return false;
    }

    switch (filterState.transactionType) {
      case TransactionTypeFilter.income:
        if (!item.isIncome) return false;
      case TransactionTypeFilter.expense:
        if (item.isIncome) return false;
      case TransactionTypeFilter.all:
        break;
    }

    return true;
  }).toList();
}

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
