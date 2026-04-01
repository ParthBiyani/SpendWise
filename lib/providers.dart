import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/transaction_utils.dart';

// ---------------------------------------------------------------------------
// App-wide constants (previously static consts scattered across widgets)
// ---------------------------------------------------------------------------

const List<String> availableCategories = [
  'Income',
  'Dining',
  'Snacks',
  'Shopping',
  'Groceries',
  'Travel',
  'Bills',
  'Health',
  'Education',
  'Investment',
  'Personal Care',
  'Entertainment',
  'Gifts',
  'EMIs',
  'Transfers',
  'Housing',
  'Others',
];

const List<String> availablePaymentMethods = ['Cash', 'UPI', 'Card', 'Bank'];

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(appDatabaseProvider));
});

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

class FilterStateNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void update(FilterState newState) => state = newState;
  void reset() => state = const FilterState();
}

final filterStateProvider =
    NotifierProvider<FilterStateNotifier, FilterState>(FilterStateNotifier.new);

// ---------------------------------------------------------------------------
// Transaction data providers
// ---------------------------------------------------------------------------

final transactionsStreamProvider = StreamProvider<List<TransactionItem>>((ref) {
  return ref.watch(repositoryProvider).watchAll();
});

final filteredTransactionsProvider = Provider<List<TransactionItem>>((ref) {
  final transactions =
      ref.watch(transactionsStreamProvider).valueOrNull ?? const [];
  final filterState = ref.watch(filterStateProvider);
  return applyFilter(transactions, filterState);
});

final groupedTransactionsProvider = Provider<List<DateGroup>>((ref) {
  return groupTransactions(ref.watch(filteredTransactionsProvider));
});

final runningBalancesProvider = Provider<Map<int, double>>((ref) {
  return computeRunningBalances(ref.watch(filteredTransactionsProvider));
});

// ---------------------------------------------------------------------------
// Summary provider
// ---------------------------------------------------------------------------

typedef TransactionSummary = ({
  double totalIncome,
  double totalExpense,
  double netBalance,
});

final summaryProvider = Provider<TransactionSummary>((ref) {
  final items = ref.watch(filteredTransactionsProvider);
  final totalIncome =
      items.where((i) => i.isIncome).fold(0.0, (s, i) => s + i.amount);
  final totalExpense =
      items.where((i) => !i.isIncome).fold(0.0, (s, i) => s + i.amount);
  return (
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netBalance: totalIncome - totalExpense,
  );
});
