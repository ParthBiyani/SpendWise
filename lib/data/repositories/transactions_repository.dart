import 'package:drift/drift.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/home/models/transaction_item.dart';

class TransactionsRepository {
  TransactionsRepository(this._db);

  final AppDatabase _db;

  Stream<List<TransactionItem>> watchAll() {
    return _db.watchAllTransactions().map(
          (rows) => rows.map(_toItem).toList(),
        );
  }

  Future<int> add(TransactionItem item) {
    return _db.addTransaction(_toCompanion(item));
  }

  Future<bool> update(TransactionItem item) {
    if (item.id == null) {
      throw ArgumentError('Transaction id is required for update');
    }
    return _db.updateTransaction(_toCompanion(item));
  }

  Future<int> delete(int id) {
    return _db.deleteTransactionById(id);
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
