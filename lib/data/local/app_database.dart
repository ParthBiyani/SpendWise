import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remarks => text()();
  TextColumn get category => text()();
  TextColumn get classType => text()(); // Necessity, Desire, Investment, Others
  RealColumn get amount => real()();
  BoolColumn get isIncome => boolean()();
  TextColumn get paymentMethod => text()();
  TextColumn get referenceId => text()();
  TextColumn get entryBy => text()();
  DateTimeColumn get occurredAt => dateTime().named('date_time')();
}

@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          await m.database.customStatement('DROP TABLE IF EXISTS "transactions_new";');
          await m.database.customStatement('''
CREATE TABLE transactions_new (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "remarks" TEXT NOT NULL,
  "category" TEXT NOT NULL,
  "class_type" TEXT NOT NULL,
  "amount" REAL NOT NULL,
  "is_income" INTEGER NOT NULL,
  "payment_method" TEXT NOT NULL,
  "reference_id" TEXT NOT NULL,
  "entry_by" TEXT NOT NULL,
  "date_time" INTEGER NOT NULL
);
''');
          await m.database.customStatement('''
INSERT INTO transactions_new (
  "remarks", "category", "class_type", "amount", "is_income",
  "payment_method", "reference_id", "entry_by", "date_time"
)
SELECT "remarks", "category",
  CASE
    WHEN "category" = 'Income' THEN 'Others'
    WHEN "category" = 'Dining' THEN 'Desire'
    WHEN "category" = 'Snacks' THEN 'Desire'
    WHEN "category" = 'Shopping' THEN 'Desire'
    WHEN "category" = 'Groceries' THEN 'Necessity'
    WHEN "category" = 'Travel' THEN 'Necessity'
    WHEN "category" = 'Bills' THEN 'Necessity'
    WHEN "category" = 'Health' THEN 'Necessity'
    WHEN "category" = 'Education' THEN 'Investment'
    WHEN "category" = 'Investment' THEN 'Investment'
    WHEN "category" = 'Personal Care' THEN 'Necessity'
    WHEN "category" = 'Entertainment' THEN 'Desire'
    WHEN "category" = 'Gifts' THEN 'Desire'
    WHEN "category" = 'EMIs' THEN 'Necessity'
    WHEN "category" = 'Transfers' THEN 'Others'
    WHEN "category" = 'Housing' THEN 'Necessity'
    WHEN "category" = 'Others' THEN 'Desire'
    ELSE 'Desire'
  END,
  "amount", "is_income", "payment_method", "reference_id", "entry_by", "date_time"
FROM "transactions";
''');
          await m.database.customStatement('DROP TABLE "transactions";');
          await m.database.customStatement('ALTER TABLE "transactions_new" RENAME TO "transactions";');
        }
      },
    );
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> addTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) {
    return update(transactions).replace(entry);
  }

  Future<int> deleteTransactionById(int id) {
    return (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'spendwise.sqlite'));
    return NativeDatabase(file);
  });
}
