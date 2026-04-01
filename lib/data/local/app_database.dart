import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@TableIndex(name: 'idx_transactions_date_time', columns: {#occurredAt})
@TableIndex(name: 'idx_transactions_category', columns: {#category})
@TableIndex(name: 'idx_transactions_payment_method', columns: {#paymentMethod})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remarks => text().nullable()();
  TextColumn get category => text()();
  TextColumn get classType => text()(); // Necessity, Desire, Investment, Others
  RealColumn get amount => real()();
  BoolColumn get isIncome => boolean()();
  TextColumn get paymentMethod => text()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get entryBy => text().nullable()();
  DateTimeColumn get occurredAt => dateTime().named('date_time')();
}

@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Each block runs only when upgrading across that specific version
        // boundary, regardless of how many versions are being skipped.
        // Pattern: from <= N && to > N  →  "step N→N+1 has not yet been applied"

        // v2 → v3: add class_type column, backfill from category
        if (from <= 2 && to > 2) {
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

        // v3 → v4: add indexes on date_time, category, payment_method
        if (from <= 3 && to > 3) {
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_time ON transactions (date_time);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON transactions (payment_method);');
        }

        // v4 → v5: make remarks, reference_id, entry_by nullable
        if (from <= 4 && to > 4) {
          await m.database.customStatement('DROP TABLE IF EXISTS "transactions_new";');
          await m.database.customStatement('''
CREATE TABLE transactions_new (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "remarks" TEXT,
  "category" TEXT NOT NULL,
  "class_type" TEXT NOT NULL,
  "amount" REAL NOT NULL,
  "is_income" INTEGER NOT NULL,
  "payment_method" TEXT NOT NULL,
  "reference_id" TEXT,
  "entry_by" TEXT,
  "date_time" INTEGER NOT NULL
);
''');
          await m.database.customStatement('''
INSERT INTO transactions_new (
  "id", "remarks", "category", "class_type", "amount", "is_income",
  "payment_method", "reference_id", "entry_by", "date_time"
)
SELECT
  "id",
  NULLIF("remarks", ''),
  "category", "class_type", "amount", "is_income", "payment_method",
  NULLIF("reference_id", ''),
  NULLIF("entry_by", ''),
  "date_time"
FROM "transactions";
''');
          await m.database.customStatement('DROP TABLE "transactions";');
          await m.database.customStatement('ALTER TABLE "transactions_new" RENAME TO "transactions";');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_time ON transactions (date_time);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON transactions (payment_method);');
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

  Stream<List<Transaction>> watchFilteredTransactions({
    required String dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    required List<String> categories,
    required List<String> paymentMethods,
    bool? isIncome, // null = all, true = income only, false = expense only
  }) {
    final now = DateTime.now();
    final query = select(transactions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ]);

    query.where((t) {
      final conditions = <Expression<bool>>[];

      switch (dateFilter) {
        case 'Today':
          final start = DateTime(now.year, now.month, now.day);
          final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(start))
            ..add(t.occurredAt.isSmallerOrEqualValue(end));
          break;
        case 'This Week':
          final offset = now.weekday - 1;
          final weekStart =
              DateTime(now.year, now.month, now.day - offset);
          final weekEnd = DateTime(
              now.year, now.month, now.day - offset + 6, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(weekStart))
            ..add(t.occurredAt.isSmallerOrEqualValue(weekEnd));
          break;
        case 'This Month':
          final monthStart = DateTime(now.year, now.month);
          final monthEnd =
              DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(monthStart))
            ..add(t.occurredAt.isSmallerOrEqualValue(monthEnd));
          break;
        case 'This Year':
          final yearStart = DateTime(now.year);
          final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(yearStart))
            ..add(t.occurredAt.isSmallerOrEqualValue(yearEnd));
          break;
        case 'Custom Range':
          if (customStartDate != null) {
            conditions.add(t.occurredAt.isBiggerOrEqualValue(customStartDate));
          }
          if (customEndDate != null) {
            conditions.add(t.occurredAt.isSmallerOrEqualValue(customEndDate));
          }
          break;
      }

      if (categories.isNotEmpty) {
        conditions.add(t.category.isIn(categories));
      }

      if (paymentMethods.isNotEmpty) {
        conditions.add(t.paymentMethod.isIn(paymentMethods));
      }

      if (isIncome != null) {
        conditions.add(t.isIncome.equals(isIncome));
      }

      if (conditions.isEmpty) return const Constant(true);
      return conditions.reduce((a, b) => a & b);
    });

    return query.watch();
  }

  Future<List<Transaction>> fetchFilteredTransactionsPaged({
    required String dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    required List<String> categories,
    required List<String> paymentMethods,
    bool? isIncome,
    required int limit,
    required int offset,
  }) {
    final now = DateTime.now();
    final query = select(transactions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    query.where((t) {
      final conditions = <Expression<bool>>[];

      switch (dateFilter) {
        case 'Today':
          final start = DateTime(now.year, now.month, now.day);
          final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(start))
            ..add(t.occurredAt.isSmallerOrEqualValue(end));
          break;
        case 'This Week':
          final offset = now.weekday - 1;
          final weekStart = DateTime(now.year, now.month, now.day - offset);
          final weekEnd = DateTime(
              now.year, now.month, now.day - offset + 6, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(weekStart))
            ..add(t.occurredAt.isSmallerOrEqualValue(weekEnd));
          break;
        case 'This Month':
          final monthStart = DateTime(now.year, now.month);
          final monthEnd =
              DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(monthStart))
            ..add(t.occurredAt.isSmallerOrEqualValue(monthEnd));
          break;
        case 'This Year':
          final yearStart = DateTime(now.year);
          final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59, 999);
          conditions
            ..add(t.occurredAt.isBiggerOrEqualValue(yearStart))
            ..add(t.occurredAt.isSmallerOrEqualValue(yearEnd));
          break;
        case 'Custom Range':
          if (customStartDate != null) {
            conditions
                .add(t.occurredAt.isBiggerOrEqualValue(customStartDate));
          }
          if (customEndDate != null) {
            conditions
                .add(t.occurredAt.isSmallerOrEqualValue(customEndDate));
          }
          break;
      }

      if (categories.isNotEmpty) {
        conditions.add(t.category.isIn(categories));
      }
      if (paymentMethods.isNotEmpty) {
        conditions.add(t.paymentMethod.isIn(paymentMethods));
      }
      if (isIncome != null) {
        conditions.add(t.isIncome.equals(isIncome));
      }

      if (conditions.isEmpty) return const Constant(true);
      return conditions.reduce((a, b) => a & b);
    });

    return query.get();
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
