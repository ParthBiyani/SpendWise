import 'package:drift/drift.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/repository_exceptions.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';

class TransactionsRepository {
  TransactionsRepository(this._db);

  final AppDatabase _db;

  Stream<List<TransactionItem>> watchAll() {
    return _db.watchAllTransactions().map((rows) => rows.map(_toItem).toList()).handleError(
          (Object e, StackTrace st) =>
              throw TransactionReadException('Failed to watch transactions', cause: e),
        );
  }

  Stream<List<TransactionItem>> watchFiltered(FilterState filterState) {
    return _db
        .watchFilteredTransactions(
          dateFilter: filterState.dateFilter,
          customStartDate: filterState.customStartDate,
          customEndDate: filterState.customEndDate,
          categories: filterState.categories,
          paymentMethods: filterState.paymentMethods,
          isIncome: switch (filterState.transactionType) {
            TransactionTypeFilter.income => true,
            TransactionTypeFilter.expense => false,
            TransactionTypeFilter.all => null,
          },
        )
        .map((rows) => rows.map(_toItem).toList())
        .handleError(
          (Object e, StackTrace st) =>
              throw TransactionReadException('Failed to watch filtered transactions', cause: e),
        );
  }

  Future<List<TransactionItem>> fetchPaged(
    FilterState filterState, {
    required int limit,
    required int offset,
  }) async {
    try {
      final rows = await _db.fetchFilteredTransactionsPaged(
        dateFilter: filterState.dateFilter,
        customStartDate: filterState.customStartDate,
        customEndDate: filterState.customEndDate,
        categories: filterState.categories,
        paymentMethods: filterState.paymentMethods,
        isIncome: switch (filterState.transactionType) {
          TransactionTypeFilter.income => true,
          TransactionTypeFilter.expense => false,
          TransactionTypeFilter.all => null,
        },
        limit: limit,
        offset: offset,
      );
      return rows.map(_toItem).toList();
    } catch (e) {
      throw TransactionReadException('Failed to fetch transactions', cause: e);
    }
  }

  Future<Map<String, int>> fetchCategoryUsageCounts() async {
    try {
      return await _db.fetchCategoryUsageCounts();
    } catch (e) {
      throw TransactionReadException('Failed to fetch category usage counts', cause: e);
    }
  }

  Future<int> add(TransactionItem item) async {
    try {
      return await _db.addTransaction(_toCompanion(item));
    } catch (e) {
      throw TransactionInsertException('Failed to add transaction', cause: e);
    }
  }

  Future<bool> update(TransactionItem item) async {
    if (item.id == null) {
      throw const TransactionUpdateException('Transaction id is required for update');
    }
    try {
      return await _db.updateTransaction(_toCompanion(item));
    } catch (e) {
      throw TransactionUpdateException('Failed to update transaction', cause: e);
    }
  }

  Future<int> delete(int id) async {
    try {
      return await _db.deleteTransactionById(id);
    } catch (e) {
      throw TransactionDeleteException('Failed to delete transaction', cause: e);
    }
  }

  TransactionItem _toItem(Transaction row) {
    return TransactionItem(
      id: row.id,
      remarks: row.remarks,
      category: row.category,
      classType: row.classType,
      dateTime: row.occurredAt,
      amount: row.amount,
      isIncome: row.isIncome,
      paymentMethod: row.paymentMethod,
      referenceId: row.referenceId,
      entryBy: row.entryBy,
    );
  }

  TransactionsCompanion _toCompanion(TransactionItem item) {
    return TransactionsCompanion(
      id: item.id == null ? const Value.absent() : Value(item.id!),
      remarks: Value(item.remarks),
      category: Value(item.category),
      classType: Value(item.classType),
      amount: Value(item.amount),
      isIncome: Value(item.isIncome),
      paymentMethod: Value(item.paymentMethod),
      referenceId: Value(item.referenceId),
      entryBy: Value(item.entryBy),
      occurredAt: Value(item.dateTime),
    );
  }
}
