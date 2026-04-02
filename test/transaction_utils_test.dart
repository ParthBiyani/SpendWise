import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/transaction_utils.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

TransactionItem _item({
  required int id,
  required DateTime dateTime,
  double amount = 100.0,
  bool isIncome = false,
  String category = 'Groceries',
}) =>
    TransactionItem(
      id: id,
      category: category,
      classType: 'Necessity',
      amount: amount,
      isIncome: isIncome,
      paymentMethod: 'Cash',
      dateTime: dateTime,
    );

void main() {
  // -------------------------------------------------------------------------
  // groupTransactions
  // -------------------------------------------------------------------------
  group('groupTransactions', () {
    test('returns empty list for empty input', () {
      expect(groupTransactions([]), isEmpty);
    });

    test('single transaction produces one group', () {
      final items = [_item(id: 1, dateTime: DateTime(2024, 6, 15, 10, 0))];
      final groups = groupTransactions(items);

      expect(groups, hasLength(1));
      expect(groups.first.items, hasLength(1));
    });

    test('transactions on the same date are grouped together', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 6, 15, 8, 0)),
        _item(id: 2, dateTime: DateTime(2024, 6, 15, 14, 30)),
        _item(id: 3, dateTime: DateTime(2024, 6, 15, 20, 0)),
      ];
      final groups = groupTransactions(items);

      expect(groups, hasLength(1));
      expect(groups.first.items, hasLength(3));
    });

    test('transactions on different dates produce separate groups', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 6, 15)),
        _item(id: 2, dateTime: DateTime(2024, 6, 16)),
        _item(id: 3, dateTime: DateTime(2024, 6, 17)),
      ];
      final groups = groupTransactions(items);

      expect(groups, hasLength(3));
    });

    test('groups are ordered by date descending (newest first)', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 1, 1)),
        _item(id: 2, dateTime: DateTime(2024, 6, 1)),
        _item(id: 3, dateTime: DateTime(2024, 3, 1)),
      ];
      final groups = groupTransactions(items);

      expect(groups[0].items.first.dateTime, DateTime(2024, 6, 1));
      expect(groups[1].items.first.dateTime, DateTime(2024, 3, 1));
      expect(groups[2].items.first.dateTime, DateTime(2024, 1, 1));
    });

    test('dateLabel is formatted correctly', () {
      final items = [_item(id: 1, dateTime: DateTime(2024, 6, 15))];
      final groups = groupTransactions(items);

      expect(groups.first.dateLabel, 'Jun 15, 2024');
    });

    test('mixed-date list is split and ordered correctly', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 5, 20, 9, 0)),
        _item(id: 2, dateTime: DateTime(2024, 5, 21, 10, 0)),
        _item(id: 3, dateTime: DateTime(2024, 5, 20, 18, 0)),
      ];
      final groups = groupTransactions(items);

      expect(groups, hasLength(2));
      // Newer date first
      expect(groups[0].dateLabel, 'May 21, 2024');
      expect(groups[0].items, hasLength(1));
      expect(groups[1].dateLabel, 'May 20, 2024');
      expect(groups[1].items, hasLength(2));
    });
  });

  // -------------------------------------------------------------------------
  // computeRunningBalances
  // -------------------------------------------------------------------------
  group('computeRunningBalances', () {
    test('returns empty map for empty input', () {
      expect(computeRunningBalances([]), isEmpty);
    });

    test('single income transaction has positive balance', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 1, 1), amount: 500, isIncome: true),
      ];
      final balances = computeRunningBalances(items);

      expect(balances[1], 500.0);
    });

    test('single expense transaction has negative balance', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 1, 1), amount: 200, isIncome: false),
      ];
      final balances = computeRunningBalances(items);

      expect(balances[1], -200.0);
    });

    test('balances accumulate in chronological order', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 1, 1), amount: 1000, isIncome: true),
        _item(id: 2, dateTime: DateTime(2024, 1, 2), amount: 300, isIncome: false),
        _item(id: 3, dateTime: DateTime(2024, 1, 3), amount: 200, isIncome: false),
      ];
      final balances = computeRunningBalances(items);

      expect(balances[1], 1000.0);
      expect(balances[2], 700.0);
      expect(balances[3], 500.0);
    });

    test('input order does not affect balances — sorted by date', () {
      // Provide items in reverse order; result should match chronological accumulation.
      final items = [
        _item(id: 3, dateTime: DateTime(2024, 1, 3), amount: 200, isIncome: false),
        _item(id: 1, dateTime: DateTime(2024, 1, 1), amount: 1000, isIncome: true),
        _item(id: 2, dateTime: DateTime(2024, 1, 2), amount: 300, isIncome: false),
      ];
      final balances = computeRunningBalances(items);

      expect(balances[1], 1000.0);
      expect(balances[2], 700.0);
      expect(balances[3], 500.0);
    });

    test('items without an id are excluded from the result', () {
      final items = [
        TransactionItem(
          id: null,
          category: 'Dining',
          classType: 'Desire',
          amount: 100,
          isIncome: false,
          paymentMethod: 'Cash',
          dateTime: DateTime(2024, 1, 1),
        ),
        _item(id: 2, dateTime: DateTime(2024, 1, 2), amount: 500, isIncome: true),
      ];
      final balances = computeRunningBalances(items);

      // id=null item is still counted in the running total but has no key
      expect(balances.containsKey(null), isFalse);
      expect(balances[2], 400.0); // 500 - 100 (null-id expense came first)
    });

    test('net balance is zero when income equals expenses', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 1, 1), amount: 500, isIncome: true),
        _item(id: 2, dateTime: DateTime(2024, 1, 2), amount: 500, isIncome: false),
      ];
      final balances = computeRunningBalances(items);

      expect(balances[2], 0.0);
    });

    test('all entries are present in the result map', () {
      final items = [
        _item(id: 1, dateTime: DateTime(2024, 1, 1), amount: 100, isIncome: true),
        _item(id: 2, dateTime: DateTime(2024, 1, 2), amount: 50, isIncome: false),
        _item(id: 3, dateTime: DateTime(2024, 1, 3), amount: 75, isIncome: true),
      ];
      final balances = computeRunningBalances(items);

      expect(balances.keys, containsAll([1, 2, 3]));
    });
  });
}
