import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/repository_exceptions.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppDatabase _openInMemory() => AppDatabase.forTesting(NativeDatabase.memory());

TransactionItem _item({
  int? id,
  String category = 'Groceries',
  String classType = 'Necessity',
  double amount = 100.0,
  bool isIncome = false,
  String paymentMethod = 'Cash',
  DateTime? dateTime,
  String? remarks,
  String? referenceId,
  String? entryBy,
}) =>
    TransactionItem(
      id: id,
      category: category,
      classType: classType,
      amount: amount,
      isIncome: isIncome,
      paymentMethod: paymentMethod,
      dateTime: dateTime ?? DateTime(2024, 6, 15, 10, 0),
      remarks: remarks,
      referenceId: referenceId,
      entryBy: entryBy,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late TransactionsRepository repo;

  setUp(() {
    db = _openInMemory();
    repo = TransactionsRepository(db);
  });

  tearDown(() async => db.close());

  // -------------------------------------------------------------------------
  // add
  // -------------------------------------------------------------------------
  group('add', () {
    test('returns a positive id', () async {
      final id = await repo.add(_item());
      expect(id, isPositive);
    });

    test('inserted item is retrievable via watchAll', () async {
      await repo.add(_item(category: 'Dining', amount: 250.0));

      final items = await repo.watchAll().first;
      expect(items, hasLength(1));
      expect(items.first.category, 'Dining');
      expect(items.first.amount, 250.0);
    });

    test('nullable fields stored as null when omitted', () async {
      final id = await repo.add(_item());
      final items = await repo.watchAll().first;
      final saved = items.firstWhere((i) => i.id == id);

      expect(saved.remarks, isNull);
      expect(saved.referenceId, isNull);
      expect(saved.entryBy, isNull);
    });

    test('nullable fields round-trip correctly when provided', () async {
      final id = await repo.add(_item(
        remarks: 'lunch',
        referenceId: 'TXN123',
        entryBy: 'Alice',
      ));
      final items = await repo.watchAll().first;
      final saved = items.firstWhere((i) => i.id == id);

      expect(saved.remarks, 'lunch');
      expect(saved.referenceId, 'TXN123');
      expect(saved.entryBy, 'Alice');
    });
  });

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------
  group('update', () {
    test('updates an existing transaction', () async {
      final id = await repo.add(_item(amount: 100.0));
      final success = await repo.update(_item(id: id, amount: 999.0, category: 'Travel'));

      expect(success, isTrue);
      final items = await repo.watchAll().first;
      expect(items.first.amount, 999.0);
      expect(items.first.category, 'Travel');
    });

    test('throws TransactionUpdateException when id is null', () {
      expect(() => repo.update(_item()), throwsA(isA<TransactionUpdateException>()));
    });
  });

  // -------------------------------------------------------------------------
  // delete
  // -------------------------------------------------------------------------
  group('delete', () {
    test('removes the transaction and returns 1', () async {
      final id = await repo.add(_item());
      final affected = await repo.delete(id);

      expect(affected, 1);
      expect(await repo.watchAll().first, isEmpty);
    });

    test('returns 0 when id does not exist', () async {
      final affected = await repo.delete(99999);
      expect(affected, 0);
    });

    test('only deletes the targeted row, not others', () async {
      final id1 = await repo.add(_item(category: 'Dining'));
      final id2 = await repo.add(_item(category: 'Travel'));

      await repo.delete(id1);

      final remaining = await repo.watchAll().first;
      expect(remaining, hasLength(1));
      expect(remaining.first.id, id2);
    });
  });

  // -------------------------------------------------------------------------
  // watchAll
  // -------------------------------------------------------------------------
  group('watchAll', () {
    test('emits empty list when no transactions exist', () async {
      expect(await repo.watchAll().first, isEmpty);
    });

    test('emits updated list after insert', () async {
      final stream = repo.watchAll();
      expect(await stream.first, isEmpty);

      await repo.add(_item(category: 'Bills'));

      expect(await stream.first, hasLength(1));
    });

    test('orders results by date descending', () async {
      await repo.add(_item(dateTime: DateTime(2024, 1, 1)));
      await repo.add(_item(dateTime: DateTime(2024, 6, 1)));
      await repo.add(_item(dateTime: DateTime(2024, 3, 1)));

      final dates = (await repo.watchAll().first).map((i) => i.dateTime).toList();
      expect(dates, [DateTime(2024, 6, 1), DateTime(2024, 3, 1), DateTime(2024, 1, 1)]);
    });
  });

  // -------------------------------------------------------------------------
  // watchFiltered
  // -------------------------------------------------------------------------
  group('watchFiltered', () {
    test('all-time filter returns all transactions', () async {
      await repo.add(_item(category: 'Dining'));
      await repo.add(_item(category: 'Travel'));

      expect(await repo.watchFiltered(const FilterState()).first, hasLength(2));
    });

    test('income filter returns only income transactions', () async {
      await repo.add(_item(isIncome: true, category: 'Income'));
      await repo.add(_item(isIncome: false, category: 'Dining'));

      final filter = const FilterState()
          .copyWith(transactionType: TransactionTypeFilter.income);
      final items = await repo.watchFiltered(filter).first;

      expect(items, hasLength(1));
      expect(items.first.isIncome, isTrue);
    });

    test('expense filter returns only expense transactions', () async {
      await repo.add(_item(isIncome: true));
      await repo.add(_item(isIncome: false, category: 'Dining'));
      await repo.add(_item(isIncome: false, category: 'Travel'));

      final filter = const FilterState()
          .copyWith(transactionType: TransactionTypeFilter.expense);
      final items = await repo.watchFiltered(filter).first;

      expect(items, hasLength(2));
      expect(items.every((i) => !i.isIncome), isTrue);
    });

    test('category filter returns only matching categories', () async {
      await repo.add(_item(category: 'Dining'));
      await repo.add(_item(category: 'Travel'));
      await repo.add(_item(category: 'Groceries'));

      final filter = const FilterState()
          .copyWith(categories: ['Dining', 'Travel']);
      final items = await repo.watchFiltered(filter).first;

      expect(items, hasLength(2));
      expect(items.map((i) => i.category), containsAll(['Dining', 'Travel']));
    });

    test('payment method filter returns only matching methods', () async {
      await repo.add(_item(paymentMethod: 'Cash'));
      await repo.add(_item(paymentMethod: 'UPI'));
      await repo.add(_item(paymentMethod: 'Card'));

      final filter = const FilterState()
          .copyWith(paymentMethods: ['UPI']);
      final items = await repo.watchFiltered(filter).first;

      expect(items, hasLength(1));
      expect(items.first.paymentMethod, 'UPI');
    });

    test('custom date range filter returns only transactions within range', () async {
      await repo.add(_item(dateTime: DateTime(2024, 3, 1)));
      await repo.add(_item(dateTime: DateTime(2024, 5, 15)));
      await repo.add(_item(dateTime: DateTime(2024, 8, 1)));

      final filter = const FilterState().copyWith(
        dateFilter: 'Custom Range',
        customStartDate: () => DateTime(2024, 4, 1),
        customEndDate: () => DateTime(2024, 6, 30),
      );
      final items = await repo.watchFiltered(filter).first;

      expect(items, hasLength(1));
      expect(items.first.dateTime, DateTime(2024, 5, 15));
    });

    test('combined filters are ANDed together', () async {
      await repo.add(_item(category: 'Dining', paymentMethod: 'UPI'));
      await repo.add(_item(category: 'Dining', paymentMethod: 'Cash'));
      await repo.add(_item(category: 'Travel', paymentMethod: 'UPI'));

      final filter = const FilterState().copyWith(
        categories: ['Dining'],
        paymentMethods: ['UPI'],
      );
      final items = await repo.watchFiltered(filter).first;

      expect(items, hasLength(1));
      expect(items.first.category, 'Dining');
      expect(items.first.paymentMethod, 'UPI');
    });
  });

  // -------------------------------------------------------------------------
  // fetchPaged
  // -------------------------------------------------------------------------
  group('fetchPaged', () {
    setUp(() async {
      for (var i = 1; i <= 5; i++) {
        await repo.add(_item(amount: i * 10.0, dateTime: DateTime(2024, i, 1)));
      }
    });

    test('returns only the requested page size', () async {
      final page = await repo.fetchPaged(const FilterState(), limit: 2, offset: 0);
      expect(page, hasLength(2));
    });

    test('page 2 returns different items than page 1', () async {
      final page1 = await repo.fetchPaged(const FilterState(), limit: 2, offset: 0);
      final page2 = await repo.fetchPaged(const FilterState(), limit: 2, offset: 2);

      expect(page1.first.dateTime, isNot(equals(page2.first.dateTime)));
    });

    test('last page returns fewer items than limit', () async {
      // 5 items total, offset 4 → 1 remaining
      final page = await repo.fetchPaged(const FilterState(), limit: 3, offset: 4);
      expect(page, hasLength(1));
    });

    test('offset beyond total returns empty list', () async {
      final page = await repo.fetchPaged(const FilterState(), limit: 3, offset: 10);
      expect(page, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // fetchCategoryUsageCounts
  // -------------------------------------------------------------------------
  group('fetchCategoryUsageCounts', () {
    test('returns empty map when no transactions exist', () async {
      expect(await repo.fetchCategoryUsageCounts(), isEmpty);
    });

    test('counts each category correctly', () async {
      await repo.add(_item(category: 'Dining'));
      await repo.add(_item(category: 'Dining'));
      await repo.add(_item(category: 'Travel'));

      final counts = await repo.fetchCategoryUsageCounts();
      expect(counts['Dining'], 2);
      expect(counts['Travel'], 1);
    });
  });
}
