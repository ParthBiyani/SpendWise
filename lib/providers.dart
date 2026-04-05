import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/config/constants.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/transaction_utils.dart'
    show groupTransactions, computeRunningBalances;

// ---------------------------------------------------------------------------
// App-wide convenience providers derived from the mutable notifiers
// ---------------------------------------------------------------------------

/// Flat list of category names, in display order.
final availableCategoriesProvider = Provider<List<String>>((ref) {
  return (ref.watch(categoriesProvider).valueOrNull ?? []).map((c) => c.name).toList();
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

final allFilteredStreamProvider = StreamProvider<List<TransactionItem>>((ref) {
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
    ref.watch(allFilteredStreamProvider);

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
      ref.watch(allFilteredStreamProvider).valueOrNull ?? const []);
});

// ---------------------------------------------------------------------------
// Settings providers — persisted to the Settings table in SQLite
// ---------------------------------------------------------------------------

// IconData serialisation helpers (codePoint + fontFamily + fontPackage)
Map<String, dynamic> _iconToJson(IconData icon) => {
      'cp': icon.codePoint,
      'ff': icon.fontFamily,
      'fp': icon.fontPackage,
    };

IconData _iconFromJson(Map<String, dynamic> j) => IconData(
      j['cp'] as int,
      fontFamily: j['ff'] as String?,
      fontPackage: j['fp'] as String?,
    );

class BookNameNotifier extends AsyncNotifier<String> {
  static const _key = 'book_name';

  @override
  Future<String> build() async {
    final db = ref.read(appDatabaseProvider);
    return await db.getSetting(_key) ?? 'Wallet Transactions';
  }

  Future<void> set(String name) async {
    state = AsyncData(name);
    await ref.read(appDatabaseProvider).setSetting(_key, name);
  }
}

final bookNameProvider =
    AsyncNotifierProvider<BookNameNotifier, String>(BookNameNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<CategoryInfo>> {
  static const _key = 'categories';

  @override
  Future<List<CategoryInfo>> build() async {
    final db = ref.read(appDatabaseProvider);
    final raw = await db.getSetting(_key);
    if (raw == null) return List<CategoryInfo>.from(categories);
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return CategoryInfo(
        name: m['name'] as String,
        icon: _iconFromJson(m['icon'] as Map<String, dynamic>),
        classType: m['classType'] as String,
      );
    }).toList();
  }

  Future<void> _persist(List<CategoryInfo> list) async {
    final encoded = jsonEncode(list.map((c) => {
          'name': c.name,
          'icon': _iconToJson(c.icon),
          'classType': c.classType,
        }).toList());
    await ref.read(appDatabaseProvider).setSetting(_key, encoded);
  }

  Future<void> add(CategoryInfo item) async {
    final current = state.valueOrNull ?? [];
    final updated = [...current, item];
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> edit(int index, CategoryInfo item) async {
    final updated = List<CategoryInfo>.from(state.valueOrNull ?? []);
    updated[index] = item;
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> remove(int index) async {
    final updated = List<CategoryInfo>.from(state.valueOrNull ?? []);
    updated.removeAt(index);
    state = AsyncData(updated);
    await _persist(updated);
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryInfo>>(
        CategoriesNotifier.new);

class PaymentMethodsNotifier extends AsyncNotifier<List<PaymentMethodInfo>> {
  static const _key = 'payment_methods';

  @override
  Future<List<PaymentMethodInfo>> build() async {
    final db = ref.read(appDatabaseProvider);
    final raw = await db.getSetting(_key);
    if (raw == null) return List<PaymentMethodInfo>.from(paymentMethods);
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return PaymentMethodInfo(
        name: m['name'] as String,
        icon: _iconFromJson(m['icon'] as Map<String, dynamic>),
      );
    }).toList();
  }

  Future<void> _persist(List<PaymentMethodInfo> list) async {
    final encoded = jsonEncode(list.map((p) => {
          'name': p.name,
          'icon': _iconToJson(p.icon),
        }).toList());
    await ref.read(appDatabaseProvider).setSetting(_key, encoded);
  }

  Future<void> add(PaymentMethodInfo item) async {
    final current = state.valueOrNull ?? [];
    final updated = [...current, item];
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> edit(int index, PaymentMethodInfo item) async {
    final updated = List<PaymentMethodInfo>.from(state.valueOrNull ?? []);
    updated[index] = item;
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> remove(int index) async {
    final updated = List<PaymentMethodInfo>.from(state.valueOrNull ?? []);
    updated.removeAt(index);
    state = AsyncData(updated);
    await _persist(updated);
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
  final items =
      ref.watch(allFilteredStreamProvider).valueOrNull ?? const [];
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
