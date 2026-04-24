/// Demonstrates using mocktail to mock [TransactionsRepository] so that
/// provider logic can be tested without a real database.
///
/// [summaryProvider] aggregates income/expense totals from the full filtered
/// stream.  By stubbing [TransactionsRepository.watchFiltered] we can verify
/// the provider's arithmetic without touching SQLite at all.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/providers.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TransactionItem _item({
  required int id,
  required double amount,
  required bool isIncome,
  DateTime? dateTime,
}) =>
    TransactionItem(
      id: id,
      category: 'Groceries',
      classType: 'Necessity',
      amount: amount,
      isIncome: isIncome,
      paymentMethod: 'Cash',
      dateTime: dateTime ?? DateTime(2024, 6, 15),
    );

/// Creates a [ProviderContainer] that replaces [repositoryProvider] with [mock]
/// and tears itself down after the test.
ProviderContainer _container(MockTransactionsRepository mock) {
  final container = ProviderContainer(
    overrides: [repositoryProvider.overrideWithValue(mock)],
  );
  addTearDown(container.dispose);
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // Register fallback values for any()/captureAny() matchers.
    registerFallbackValue(const FilterState());
  });

  group('summaryProvider (via mocked repository)', () {
    test('totals are zero when stream emits an empty list', () async {
      final mock = MockTransactionsRepository();
      when(() => mock.watchFiltered(any())).thenAnswer((_) => Stream.value([]));

      final container = _container(mock);
      await container.read(allFilteredStreamProvider.future);

      final summary = container.read(summaryProvider);
      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 0.0);
      expect(summary.netBalance, 0.0);
    });

    test('sums income transactions correctly', () async {
      final mock = MockTransactionsRepository();
      when(() => mock.watchFiltered(any())).thenAnswer(
        (_) => Stream.value([
          _item(id: 1, amount: 1000, isIncome: true),
          _item(id: 2, amount: 500, isIncome: true),
        ]),
      );

      final container = _container(mock);
      await container.read(allFilteredStreamProvider.future);

      final summary = container.read(summaryProvider);
      expect(summary.totalIncome, 1500.0);
      expect(summary.totalExpense, 0.0);
      expect(summary.netBalance, 1500.0);
    });

    test('sums expense transactions correctly', () async {
      final mock = MockTransactionsRepository();
      when(() => mock.watchFiltered(any())).thenAnswer(
        (_) => Stream.value([
          _item(id: 1, amount: 300, isIncome: false),
          _item(id: 2, amount: 200, isIncome: false),
        ]),
      );

      final container = _container(mock);
      await container.read(allFilteredStreamProvider.future);

      final summary = container.read(summaryProvider);
      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 500.0);
      expect(summary.netBalance, -500.0);
    });

    test('computes net balance from mixed transactions', () async {
      final mock = MockTransactionsRepository();
      when(() => mock.watchFiltered(any())).thenAnswer(
        (_) => Stream.value([
          _item(id: 1, amount: 2000, isIncome: true),
          _item(id: 2, amount: 800, isIncome: false),
          _item(id: 3, amount: 400, isIncome: false),
        ]),
      );

      final container = _container(mock);
      await container.read(allFilteredStreamProvider.future);

      final summary = container.read(summaryProvider);
      expect(summary.totalIncome, 2000.0);
      expect(summary.totalExpense, 1200.0);
      expect(summary.netBalance, 800.0);
    });

    test('watchFiltered is called with the current filter state', () async {
      final mock = MockTransactionsRepository();
      when(() => mock.watchFiltered(any())).thenAnswer((_) => Stream.value([]));

      final container = _container(mock);
      await container.read(allFilteredStreamProvider.future);

      verify(() => mock.watchFiltered(const FilterState())).called(1);
    });

    test('watchFiltered is re-called when filter state changes', () async {
      final mock = MockTransactionsRepository();
      when(() => mock.watchFiltered(any())).thenAnswer((_) => Stream.value([]));

      final container = _container(mock);
      await container.read(allFilteredStreamProvider.future);

      const newFilter = FilterState(dateFilter: 'This Month');
      container.read(filterStateProvider.notifier).update(newFilter);
      await container.read(allFilteredStreamProvider.future);

      verify(() => mock.watchFiltered(const FilterState())).called(1);
      verify(() => mock.watchFiltered(newFilter)).called(1);
    });
  });
}
