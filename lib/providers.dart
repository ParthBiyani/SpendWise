import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/config/constants.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/books_repository.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/transaction_utils.dart'
    show groupTransactions, computeRunningBalances;

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  return BooksRepository(ref.watch(appDatabaseProvider));
});

// ---------------------------------------------------------------------------
// Active book selection
// ---------------------------------------------------------------------------

/// The currently open book ID. Null when on the Books List page.
final activeBookIdProvider = StateProvider<int?>((ref) => null);

/// Stream of all (non-deleted) books, sorted by last updated.
final booksListProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(booksRepositoryProvider).watchAll();
});

// ---------------------------------------------------------------------------
// Scoped repository — only non-null when a book is open
// ---------------------------------------------------------------------------

final repositoryProvider = Provider<TransactionsRepository?>((ref) {
  final bookId = ref.watch(activeBookIdProvider);
  if (bookId == null) return null;
  return TransactionsRepository(ref.watch(appDatabaseProvider), bookId: bookId);
});

// ---------------------------------------------------------------------------
// App-wide convenience providers derived from the active book
// ---------------------------------------------------------------------------

/// Flat list of category names, in display order (sort_order from DB).
final availableCategoriesProvider = Provider<List<String>>((ref) {
  return (ref.watch(categoriesProvider).valueOrNull ?? []).map((c) => c.name).toList();
});

/// Flat list of category names sorted by usage count descending.
final sortedCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return cats.map((c) => c.name).toList();
  final counts = await repo.fetchCategoryUsageCounts();
  final sorted = cats.toList()
    ..sort((a, b) {
      final countDiff = (counts[b.name] ?? 0).compareTo(counts[a.name] ?? 0);
      if (countDiff != 0) return countDiff;
      return cats.indexOf(a).compareTo(cats.indexOf(b));
    });
  return sorted.map((c) => c.name).toList();
});

/// Flat list of payment method names, in display order.
final availablePaymentMethodsProvider = Provider<List<String>>((ref) {
  return (ref.watch(paymentMethodsProvider).valueOrNull ?? []).map((p) => p.name).toList();
});

/// Maps every category name to its class type.
final categoryClassificationProvider = Provider<Map<String, String>>((ref) {
  return {for (final c in ref.watch(categoriesProvider).valueOrNull ?? []) c.name: c.classType};
});

/// Maps category name → icon.
final categoryIconsProvider = Provider<Map<String, IconData>>((ref) {
  return {for (final c in ref.watch(categoriesProvider).valueOrNull ?? []) c.name: c.icon};
});

/// Maps payment method name → icon.
final paymentMethodIconsProvider = Provider<Map<String, IconData>>((ref) {
  return {for (final p in ref.watch(paymentMethodsProvider).valueOrNull ?? []) p.name: p.icon};
});

const int kPageSize = 30;

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
// ---------------------------------------------------------------------------

final allFilteredStreamProvider = StreamProvider<List<TransactionItem>>((ref) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return const Stream.empty();
  final filterState = ref.watch(filterStateProvider);
  return repo.watchFiltered(filterState);
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

class TransactionPageNotifier extends AsyncNotifier<TransactionPageState> {
  @override
  Future<TransactionPageState> build() async {
    final filterState = ref.watch(filterStateProvider);
    ref.watch(allFilteredStreamProvider);

    final repo = ref.read(repositoryProvider);
    if (repo == null) {
      return const TransactionPageState(items: [], hasMore: false, isLoadingMore: false);
    }
    final first = await repo.fetchPaged(filterState, limit: kPageSize, offset: 0);
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
    if (repo == null) return;
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
// Derived display providers
// ---------------------------------------------------------------------------

final groupedTransactionsProvider = Provider<List<DateGroup>>((ref) {
  final items = ref.watch(transactionPageProvider).valueOrNull?.items ?? const [];
  return groupTransactions(items);
});

final runningBalancesProvider = Provider<Map<int, double>>((ref) {
  return computeRunningBalances(
      ref.watch(allFilteredStreamProvider).valueOrNull ?? const []);
});

// ---------------------------------------------------------------------------
// Settings providers — backed by the active book's categories/payment methods
// ---------------------------------------------------------------------------

class BookNameNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final bookId = ref.watch(activeBookIdProvider);
    if (bookId == null) return '';
    final book = await ref.read(booksRepositoryProvider).getBook(bookId);
    return book?.name ?? '';
  }

  Future<void> set(String name) async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    state = AsyncData(name);
    await ref.read(booksRepositoryProvider).rename(bookId, name);
  }
}

final bookNameProvider =
    AsyncNotifierProvider<BookNameNotifier, String>(BookNameNotifier.new);

class BookIconNotifier extends AsyncNotifier<IconData> {
  @override
  Future<IconData> build() async {
    final bookId = ref.watch(activeBookIdProvider);
    if (bookId == null) return Icons.menu_book_outlined;
    final book = await ref.read(booksRepositoryProvider).getBook(bookId);
    if (book == null) return Icons.menu_book_outlined;
    return IconData(book.iconCodePoint, fontFamily: book.iconFontFamily);
  }

  Future<void> set(IconData icon) async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    state = AsyncData(icon);
    await ref.read(booksRepositoryProvider).updateIcon(bookId, icon);
  }
}

final bookIconProvider =
    AsyncNotifierProvider<BookIconNotifier, IconData>(BookIconNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<CategoryInfo>> {
  @override
  Future<List<CategoryInfo>> build() async {
    final bookId = ref.watch(activeBookIdProvider);
    if (bookId == null) return [];
    final rows = await ref
        .watch(booksRepositoryProvider)
        .watchCategories(bookId)
        .first;
    return rows.map(BooksRepository.categoryFromRow).toList();
  }

  Future<void> add(CategoryInfo item) async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    await ref.read(booksRepositoryProvider).addCategory(bookId, item);
    ref.invalidateSelf();
  }

  Future<void> edit(int index, CategoryInfo item) async {
    final current = state.valueOrNull ?? [];
    if (index < 0 || index >= current.length) return;
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    // We need the DB row id — re-fetch rows to get the id
    final rows = await ref.read(booksRepositoryProvider).watchCategories(bookId).first;
    if (index >= rows.length) return;
    await ref.read(booksRepositoryProvider).updateCategory(
          rows[index].id,
          item,
          sortOrder: rows[index].sortOrder,
        );
    ref.invalidateSelf();
  }

  Future<void> remove(int index) async {
    final current = state.valueOrNull ?? [];
    if (index < 0 || index >= current.length) return;
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    final rows = await ref.read(booksRepositoryProvider).watchCategories(bookId).first;
    if (index >= rows.length) return;
    await ref.read(booksRepositoryProvider).removeCategory(rows[index].id);
    ref.invalidateSelf();
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryInfo>>(
        CategoriesNotifier.new);

class PaymentMethodsNotifier extends AsyncNotifier<List<PaymentMethodInfo>> {
  @override
  Future<List<PaymentMethodInfo>> build() async {
    final bookId = ref.watch(activeBookIdProvider);
    if (bookId == null) return [];
    final rows = await ref
        .watch(booksRepositoryProvider)
        .watchPaymentMethods(bookId)
        .first;
    return rows.map(BooksRepository.paymentMethodFromRow).toList();
  }

  Future<void> add(PaymentMethodInfo item) async {
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    await ref.read(booksRepositoryProvider).addPaymentMethod(bookId, item);
    ref.invalidateSelf();
  }

  Future<void> edit(int index, PaymentMethodInfo item) async {
    final current = state.valueOrNull ?? [];
    if (index < 0 || index >= current.length) return;
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    final rows = await ref.read(booksRepositoryProvider).watchPaymentMethods(bookId).first;
    if (index >= rows.length) return;
    await ref.read(booksRepositoryProvider).updatePaymentMethod(
          rows[index].id,
          item,
          sortOrder: rows[index].sortOrder,
        );
    ref.invalidateSelf();
  }

  Future<void> remove(int index) async {
    final current = state.valueOrNull ?? [];
    if (index < 0 || index >= current.length) return;
    final bookId = ref.read(activeBookIdProvider);
    if (bookId == null) return;
    final rows = await ref.read(booksRepositoryProvider).watchPaymentMethods(bookId).first;
    if (index >= rows.length) return;
    await ref.read(booksRepositoryProvider).removePaymentMethod(rows[index].id);
    ref.invalidateSelf();
  }
}

final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodsNotifier, List<PaymentMethodInfo>>(
        PaymentMethodsNotifier.new);

// ---------------------------------------------------------------------------
// Summary provider (full filtered set)
// ---------------------------------------------------------------------------

typedef TransactionSummary = ({
  double totalIncome,
  double totalExpense,
  double netBalance,
});

final summaryProvider = Provider<TransactionSummary>((ref) {
  final items = ref.watch(allFilteredStreamProvider).valueOrNull ?? const [];
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
