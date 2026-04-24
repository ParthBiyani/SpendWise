import 'package:drift/drift.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/repository_exceptions.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:uuid/uuid.dart';

class TransactionsRepository {
  TransactionsRepository(this._db, {required this.bookId});

  final AppDatabase _db;
  final int bookId;

  static const _uuid = Uuid();

  Stream<List<TransactionItem>> watchFiltered(FilterState filterState) {
    return _db
        .watchFilteredTransactions(
          bookId: bookId,
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
        bookId: bookId,
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
      return await _db.fetchCategoryUsageCounts(bookId: bookId);
    } catch (e) {
      throw TransactionReadException('Failed to fetch category usage counts', cause: e);
    }
  }

  Future<int> add(TransactionItem item) async {
    try {
      final id = await _db.addTransaction(_toCompanion(item));
      await _db.touchBook(bookId);
      return id;
    } catch (e) {
      throw TransactionInsertException('Failed to add transaction', cause: e);
    }
  }

  Future<bool> update(TransactionItem item) async {
    if (item.id == null) {
      throw const TransactionUpdateException('Transaction id is required for update');
    }
    try {
      final result = await _db.updateTransaction(_toCompanion(item));
      await _db.touchBook(bookId);
      return result;
    } catch (e) {
      throw TransactionUpdateException('Failed to update transaction', cause: e);
    }
  }

  Future<int> delete(int id) async {
    try {
      final result = await _db.deleteTransactionById(id);
      await _db.touchBook(bookId);
      return result;
    } catch (e) {
      throw TransactionDeleteException('Failed to delete transaction', cause: e);
    }
  }

  Future<int> deleteAll() async {
    try {
      final result = await _db.deleteAllTransactions(bookId: bookId);
      await _db.touchBook(bookId);
      return result;
    } catch (e) {
      throw TransactionDeleteException('Failed to delete all transactions', cause: e);
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
      uuid: item.id == null ? Value(_uuid.v4()) : const Value.absent(),
      bookId: Value(bookId),
      remarks: Value(item.remarks),
      category: Value(item.category),
      classType: Value(item.classType),
      amount: Value(item.amount),
      isIncome: Value(item.isIncome),
      paymentMethod: Value(item.paymentMethod),
      referenceId: Value(item.referenceId),
      entryBy: Value(item.entryBy),
      occurredAt: Value(item.dateTime),
      updatedAt: Value(DateTime.now()),
    );
  }
}
