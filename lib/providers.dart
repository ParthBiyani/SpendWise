import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/transaction_utils.dart'
    show groupTransactions, computeRunningBalances;

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

/// Maps every category to its class type (Necessity / Desire / Investment / Others).
/// Single source of truth — used by the form when saving and by the v2→v3
/// migration SQL (which is a frozen copy; this map governs live classification).
const Map<String, String> categoryClassification = {
  'Income': 'Others',
  'Dining': 'Desire',
  'Snacks': 'Desire',
  'Shopping': 'Desire',
  'Groceries': 'Necessity',
  'Travel': 'Necessity',
  'Bills': 'Necessity',
  'Health': 'Necessity',
  'Education': 'Investment',
  'Investment': 'Investment',
  'Personal Care': 'Necessity',
  'Entertainment': 'Desire',
  'Gifts': 'Desire',
  'EMIs': 'Necessity',
  'Transfers': 'Others',
  'Housing': 'Necessity',
  'Others': 'Desire',
};

const int kPageSize = 30;

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
// Full filtered stream — used for summary totals and running balances only.
// NOT used for the display list (that comes from the paged notifier).
// ---------------------------------------------------------------------------

final _allFilteredStreamProvider = StreamProvider<List<TransactionItem>>((ref) {
  final filterState = ref.watch(filterStateProvider);
  return ref.watch(repositoryProvider).watchFiltered(filterState);
});

// ---------------------------------------------------------------------------
// Paged transaction list
// ---------------------------------------------------------------------------

class TransactionPageState {
  const TransactionPageState({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final List<TransactionItem> items;
  final bool hasMore;
  final bool isLoadingMore;

  TransactionPageState copyWith({
    List<TransactionItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TransactionPageState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TransactionPageNotifier
    extends AsyncNotifier<TransactionPageState> {
  @override
  Future<TransactionPageState> build() async {
    // Re-run whenever the filter changes.
    final filterState = ref.watch(filterStateProvider);
    // Also re-run when the underlying DB stream emits (e.g. after add/delete).
    ref.watch(_allFilteredStreamProvider);

    final repo = ref.read(repositoryProvider);
    final first = await repo.fetchPaged(filterState,
        limit: kPageSize, offset: 0);
    return TransactionPageState(
      items: first,
      hasMore: first.length == kPageSize,
      isLoadingMore: false,
    );
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final filterState = ref.read(filterStateProvider);
    final repo = ref.read(repositoryProvider);
    final next = await repo.fetchPaged(filterState,
        limit: kPageSize, offset: current.items.length);

    state = AsyncData(current.copyWith(
      items: [...current.items, ...next],
      hasMore: next.length == kPageSize,
      isLoadingMore: false,
    ));
  }
}

final transactionPageProvider =
    AsyncNotifierProvider<TransactionPageNotifier, TransactionPageState>(
        TransactionPageNotifier.new);

// ---------------------------------------------------------------------------
// Derived display providers (use the paged list)
// ---------------------------------------------------------------------------

final groupedTransactionsProvider = Provider<List<DateGroup>>((ref) {
  final items =
      ref.watch(transactionPageProvider).valueOrNull?.items ?? const [];
  return groupTransactions(items);
});

// Running balances are computed over the full filtered set so that the balance
// shown on each visible tile is correct relative to all-time history.
final runningBalancesProvider = Provider<Map<int, double>>((ref) {
  return computeRunningBalances(
      ref.watch(_allFilteredStreamProvider).valueOrNull ?? const []);
});

// ---------------------------------------------------------------------------
// Summary provider (full filtered set)
// ---------------------------------------------------------------------------

typedef TransactionSummary = ({
  double totalIncome,
  double totalExpense,
  double netBalance,
});

final summaryProvider = Provider<TransactionSummary>((ref) {
  final items =
      ref.watch(_allFilteredStreamProvider).valueOrNull ?? const [];
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
