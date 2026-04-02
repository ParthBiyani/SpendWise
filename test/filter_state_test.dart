import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/providers.dart' show filterStateProvider;

void main() {
  // -------------------------------------------------------------------------
  // FilterState — default values
  // -------------------------------------------------------------------------
  group('FilterState defaults', () {
    const state = FilterState();

    test('dateFilter defaults to All Time', () {
      expect(state.dateFilter, 'All Time');
    });

    test('customStartDate defaults to null', () {
      expect(state.customStartDate, isNull);
    });

    test('customEndDate defaults to null', () {
      expect(state.customEndDate, isNull);
    });

    test('categories defaults to empty', () {
      expect(state.categories, isEmpty);
    });

    test('paymentMethods defaults to empty', () {
      expect(state.paymentMethods, isEmpty);
    });

    test('transactionType defaults to all', () {
      expect(state.transactionType, TransactionTypeFilter.all);
    });
  });

  // -------------------------------------------------------------------------
  // hasActiveFilters
  // -------------------------------------------------------------------------
  group('hasActiveFilters', () {
    test('false for default state', () {
      expect(const FilterState().hasActiveFilters, isFalse);
    });

    test('true when dateFilter is not All Time', () {
      expect(
        const FilterState(dateFilter: 'This Month').hasActiveFilters,
        isTrue,
      );
    });

    test('true when categories is non-empty', () {
      expect(
        const FilterState(categories: ['Dining']).hasActiveFilters,
        isTrue,
      );
    });

    test('true when paymentMethods is non-empty', () {
      expect(
        const FilterState(paymentMethods: ['UPI']).hasActiveFilters,
        isTrue,
      );
    });

    test('true when transactionType is income', () {
      expect(
        const FilterState(transactionType: TransactionTypeFilter.income)
            .hasActiveFilters,
        isTrue,
      );
    });

    test('true when transactionType is expense', () {
      expect(
        const FilterState(transactionType: TransactionTypeFilter.expense)
            .hasActiveFilters,
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // activeFilterCount
  // -------------------------------------------------------------------------
  group('activeFilterCount', () {
    test('0 for default state', () {
      expect(const FilterState().activeFilterCount, 0);
    });

    test('1 when only dateFilter is active', () {
      expect(
        const FilterState(dateFilter: 'Today').activeFilterCount,
        1,
      );
    });

    test('1 when only categories is active', () {
      expect(
        const FilterState(categories: ['Dining']).activeFilterCount,
        1,
      );
    });

    test('1 when only paymentMethods is active', () {
      expect(
        const FilterState(paymentMethods: ['Cash']).activeFilterCount,
        1,
      );
    });

    test('1 when only transactionType is active', () {
      expect(
        const FilterState(transactionType: TransactionTypeFilter.expense)
            .activeFilterCount,
        1,
      );
    });

    test('4 when all filters are active', () {
      expect(
        const FilterState(
          dateFilter: 'This Month',
          categories: ['Dining'],
          paymentMethods: ['UPI'],
          transactionType: TransactionTypeFilter.income,
        ).activeFilterCount,
        4,
      );
    });

    test('categories with multiple items still counts as 1', () {
      expect(
        const FilterState(categories: ['Dining', 'Travel', 'Groceries'])
            .activeFilterCount,
        1,
      );
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------
  group('copyWith', () {
    const base = FilterState(
      dateFilter: 'This Month',
      categories: ['Dining'],
      paymentMethods: ['Cash'],
      transactionType: TransactionTypeFilter.income,
    );

    test('unchanged fields are preserved when nothing is passed', () {
      final copy = base.copyWith();
      expect(copy.dateFilter, base.dateFilter);
      expect(copy.categories, base.categories);
      expect(copy.paymentMethods, base.paymentMethods);
      expect(copy.transactionType, base.transactionType);
    });

    test('dateFilter is replaced', () {
      expect(base.copyWith(dateFilter: 'Today').dateFilter, 'Today');
    });

    test('categories is replaced', () {
      expect(
        base.copyWith(categories: ['Travel']).categories,
        ['Travel'],
      );
    });

    test('paymentMethods is replaced', () {
      expect(
        base.copyWith(paymentMethods: ['UPI']).paymentMethods,
        ['UPI'],
      );
    });

    test('transactionType is replaced', () {
      expect(
        base.copyWith(transactionType: TransactionTypeFilter.expense)
            .transactionType,
        TransactionTypeFilter.expense,
      );
    });

    test('customStartDate is set via callback', () {
      final date = DateTime(2024, 1, 1);
      final copy = base.copyWith(customStartDate: () => date);
      expect(copy.customStartDate, date);
    });

    test('customStartDate is cleared by passing () => null', () {
      final withDate = base.copyWith(
        customStartDate: () => DateTime(2024, 1, 1),
      );
      final cleared = withDate.copyWith(customStartDate: () => null);
      expect(cleared.customStartDate, isNull);
    });

    test('customStartDate is preserved when callback is omitted', () {
      final date = DateTime(2024, 3, 15);
      final withDate = base.copyWith(customStartDate: () => date);
      final copy = withDate.copyWith(dateFilter: 'Custom Range');
      expect(copy.customStartDate, date);
    });

    test('customEndDate is set via callback', () {
      final date = DateTime(2024, 12, 31);
      final copy = base.copyWith(customEndDate: () => date);
      expect(copy.customEndDate, date);
    });
  });

  // -------------------------------------------------------------------------
  // cleared
  // -------------------------------------------------------------------------
  group('cleared', () {
    test('returns a default FilterState', () {
      const active = FilterState(
        dateFilter: 'Today',
        categories: ['Dining'],
        paymentMethods: ['UPI'],
        transactionType: TransactionTypeFilter.expense,
      );
      final cleared = active.cleared();

      expect(cleared.dateFilter, 'All Time');
      expect(cleared.categories, isEmpty);
      expect(cleared.paymentMethods, isEmpty);
      expect(cleared.transactionType, TransactionTypeFilter.all);
      expect(cleared.hasActiveFilters, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // FilterStateNotifier
  // -------------------------------------------------------------------------
  group('FilterStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is default FilterState', () {
      expect(container.read(filterStateProvider), const FilterState());
    });

    test('update replaces the state', () {
      const newState = FilterState(
        dateFilter: 'This Week',
        categories: ['Travel'],
      );
      container.read(filterStateProvider.notifier).update(newState);
      expect(container.read(filterStateProvider), newState);
    });

    test('reset returns to default state', () {
      container.read(filterStateProvider.notifier).update(
            const FilterState(dateFilter: 'Today', categories: ['Dining']),
          );
      container.read(filterStateProvider.notifier).reset();
      expect(container.read(filterStateProvider), const FilterState());
      expect(
        container.read(filterStateProvider).hasActiveFilters,
        isFalse,
      );
    });

    test('reset after partial update clears all fields', () {
      container.read(filterStateProvider.notifier).update(
            const FilterState(
              dateFilter: 'This Month',
              paymentMethods: ['Card'],
              transactionType: TransactionTypeFilter.income,
            ),
          );
      container.read(filterStateProvider.notifier).reset();

      final state = container.read(filterStateProvider);
      expect(state.dateFilter, 'All Time');
      expect(state.paymentMethods, isEmpty);
      expect(state.transactionType, TransactionTypeFilter.all);
    });
  });
}
