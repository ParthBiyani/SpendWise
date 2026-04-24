import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spendwise/config/constants.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Settings table — simple key/value store for global app settings
// ---------------------------------------------------------------------------

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Books table
// ---------------------------------------------------------------------------

class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  IntColumn get iconCodePoint => integer().withDefault(const Constant(0xf02b4))(); // Icons.menu_book_outlined
  TextColumn get iconFontFamily => text().nullable()();
  TextColumn get createdByUserId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// ---------------------------------------------------------------------------
// BookCategories table
// ---------------------------------------------------------------------------

class BookCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get bookId => integer().references(Books, #id)();
  TextColumn get name => text()();
  IntColumn get iconCodePoint => integer()();
  TextColumn get iconFontFamily => text().nullable()();
  TextColumn get classType => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// ---------------------------------------------------------------------------
// BookPaymentMethods table
// ---------------------------------------------------------------------------

class BookPaymentMethods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get bookId => integer().references(Books, #id)();
  TextColumn get name => text()();
  IntColumn get iconCodePoint => integer()();
  TextColumn get iconFontFamily => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// ---------------------------------------------------------------------------
// Transactions table
// ---------------------------------------------------------------------------

@TableIndex(name: 'idx_transactions_date_time', columns: {#occurredAt})
@TableIndex(name: 'idx_transactions_category', columns: {#category})
@TableIndex(name: 'idx_transactions_payment_method', columns: {#paymentMethod})
@TableIndex(name: 'idx_transactions_book_id', columns: {#bookId})
@TableIndex(name: 'idx_transactions_updated_at', columns: {#updatedAt})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get bookId => integer().references(Books, #id)();
  TextColumn get remarks => text().nullable()();
  TextColumn get category => text()();
  TextColumn get classType => text()();
  RealColumn get amount => real()();
  BoolColumn get isIncome => boolean()();
  TextColumn get paymentMethod => text()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get entryBy => text().nullable()();
  DateTimeColumn get occurredAt => dateTime().named('date_time')();
  DateTimeColumn get updatedAt => dateTime()();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Books, BookCategories, BookPaymentMethods, Transactions, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
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

        // v3 → v4: add indexes
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

        // v5 → v6: add settings table
        if (from <= 5 && to > 5) {
          await m.database.customStatement('''
CREATE TABLE IF NOT EXISTS "settings" (
  "key" TEXT NOT NULL PRIMARY KEY,
  "value" TEXT NOT NULL
);
''');
        }

        // v6 → v7: add books, book_categories, book_payment_methods;
        //          add book_id, uuid, updated_at to transactions.
        if (from <= 6 && to > 6) {
          final nowMs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          // 1. Create books table
          await m.database.customStatement('''
CREATE TABLE IF NOT EXISTS "books" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "uuid" TEXT NOT NULL UNIQUE,
  "name" TEXT NOT NULL,
  "created_by_user_id" TEXT,
  "created_at" INTEGER NOT NULL,
  "updated_at" INTEGER NOT NULL,
  "deleted_at" INTEGER
);
''');

          // 2. Read existing book_name from settings (if any)
          final nameRows = await m.database.customSelect(
            "SELECT value FROM settings WHERE key = 'book_name'",
          ).get();
          final bookName = nameRows.isNotEmpty
              ? nameRows.first.read<String>('value')
              : 'Wallet Transactions';

          // 3. Insert the default book (will get id=1)
          await m.database.customStatement(
            'INSERT INTO "books" ("uuid","name","created_at","updated_at") VALUES (?,?,?,?)',
            ['default-book-uuid-0001', bookName, nowMs, nowMs],
          );

          // 4. Create book_categories table
          await m.database.customStatement('''
CREATE TABLE IF NOT EXISTS "book_categories" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "uuid" TEXT NOT NULL UNIQUE,
  "book_id" INTEGER NOT NULL REFERENCES books(id),
  "name" TEXT NOT NULL,
  "icon_code_point" INTEGER NOT NULL,
  "icon_font_family" TEXT,
  "class_type" TEXT NOT NULL,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "updated_at" INTEGER NOT NULL,
  "deleted_at" INTEGER
);
''');

          // 5. Migrate or seed categories
          final catRows = await m.database.customSelect(
            "SELECT value FROM settings WHERE key = 'categories'",
          ).get();

          if (catRows.isNotEmpty) {
            final raw = catRows.first.read<String>('value');
            final list = jsonDecode(raw) as List<dynamic>;
            for (var i = 0; i < list.length; i++) {
              final cat = list[i] as Map<String, dynamic>;
              final icon = cat['icon'] as Map<String, dynamic>;
              await m.database.customStatement(
                '''INSERT INTO "book_categories"
                   ("uuid","book_id","name","icon_code_point","icon_font_family","class_type","sort_order","updated_at")
                   VALUES (?,1,?,?,?,?,?,?)''',
                [
                  'migrated-cat-${i.toString().padLeft(4, '0')}',
                  cat['name'] as String,
                  icon['cp'] as int,
                  icon['ff'] as String?,
                  cat['classType'] as String,
                  i,
                  nowMs,
                ],
              );
            }
          } else {
            for (var i = 0; i < categories.length; i++) {
              final cat = categories[i];
              await m.database.customStatement(
                '''INSERT INTO "book_categories"
                   ("uuid","book_id","name","icon_code_point","icon_font_family","class_type","sort_order","updated_at")
                   VALUES (?,1,?,?,?,?,?,?)''',
                [
                  'default-cat-${i.toString().padLeft(4, '0')}',
                  cat.name,
                  cat.icon.codePoint,
                  cat.icon.fontFamily,
                  cat.classType,
                  i,
                  nowMs,
                ],
              );
            }
          }

          // 6. Create book_payment_methods table
          await m.database.customStatement('''
CREATE TABLE IF NOT EXISTS "book_payment_methods" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "uuid" TEXT NOT NULL UNIQUE,
  "book_id" INTEGER NOT NULL REFERENCES books(id),
  "name" TEXT NOT NULL,
  "icon_code_point" INTEGER NOT NULL,
  "icon_font_family" TEXT,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "updated_at" INTEGER NOT NULL,
  "deleted_at" INTEGER
);
''');

          // 7. Migrate or seed payment methods
          final pmRows = await m.database.customSelect(
            "SELECT value FROM settings WHERE key = 'payment_methods'",
          ).get();

          if (pmRows.isNotEmpty) {
            final raw = pmRows.first.read<String>('value');
            final list = jsonDecode(raw) as List<dynamic>;
            for (var i = 0; i < list.length; i++) {
              final pm = list[i] as Map<String, dynamic>;
              final icon = pm['icon'] as Map<String, dynamic>;
              await m.database.customStatement(
                '''INSERT INTO "book_payment_methods"
                   ("uuid","book_id","name","icon_code_point","icon_font_family","sort_order","updated_at")
                   VALUES (?,1,?,?,?,?,?)''',
                [
                  'migrated-pm-${i.toString().padLeft(4, '0')}',
                  pm['name'] as String,
                  icon['cp'] as int,
                  icon['ff'] as String?,
                  i,
                  nowMs,
                ],
              );
            }
          } else {
            for (var i = 0; i < paymentMethods.length; i++) {
              final pm = paymentMethods[i];
              await m.database.customStatement(
                '''INSERT INTO "book_payment_methods"
                   ("uuid","book_id","name","icon_code_point","icon_font_family","sort_order","updated_at")
                   VALUES (?,1,?,?,?,?,?)''',
                [
                  'default-pm-${i.toString().padLeft(4, '0')}',
                  pm.name,
                  pm.icon.codePoint,
                  pm.icon.fontFamily,
                  i,
                  nowMs,
                ],
              );
            }
          }

          // 8. Recreate transactions with book_id, uuid, updated_at
          await m.database.customStatement('DROP TABLE IF EXISTS "transactions_new";');
          await m.database.customStatement('''
CREATE TABLE "transactions_new" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "uuid" TEXT NOT NULL UNIQUE,
  "book_id" INTEGER NOT NULL DEFAULT 1,
  "remarks" TEXT,
  "category" TEXT NOT NULL,
  "class_type" TEXT NOT NULL,
  "amount" REAL NOT NULL,
  "is_income" INTEGER NOT NULL,
  "payment_method" TEXT NOT NULL,
  "reference_id" TEXT,
  "entry_by" TEXT,
  "date_time" INTEGER NOT NULL,
  "updated_at" INTEGER NOT NULL DEFAULT 0
);
''');
          await m.database.customStatement('''
INSERT INTO "transactions_new"
  ("id","uuid","book_id","remarks","category","class_type","amount","is_income",
   "payment_method","reference_id","entry_by","date_time","updated_at")
SELECT "id",
  'migrated-txn-' || CAST("id" AS TEXT),
  1,
  "remarks","category","class_type","amount","is_income",
  "payment_method","reference_id","entry_by","date_time",
  $nowMs
FROM "transactions";
''');
          await m.database.customStatement('DROP TABLE "transactions";');
          await m.database.customStatement('ALTER TABLE "transactions_new" RENAME TO "transactions";');

          // 9. Recreate indexes
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_time ON transactions (date_time);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON transactions (payment_method);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_book_id ON transactions (book_id);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_updated_at ON transactions (updated_at);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_books_uuid ON books (uuid);');
          await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_uuid ON transactions (uuid);');

          // 10. Clean up migrated settings keys
          await m.database.customStatement(
              "DELETE FROM settings WHERE key IN ('book_name','categories','payment_methods');");
        }

        // v7 → v8: add icon_code_point and icon_font_family to books
        if (from <= 7 && to > 7) {
          await m.database.customStatement(
              'ALTER TABLE books ADD COLUMN "icon_code_point" INTEGER NOT NULL DEFAULT 0;');
          await m.database.customStatement(
              'ALTER TABLE books ADD COLUMN "icon_font_family" TEXT;');
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Books CRUD
  // ---------------------------------------------------------------------------

  Stream<List<Book>> watchAllBooks() {
    return (select(books)
          ..where((b) => b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm(expression: b.updatedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<Book> createBook(String name, String uuid, {required int iconCodePoint, String? iconFontFamily}) async {
    final now = DateTime.now();
    final id = await into(books).insert(BooksCompanion.insert(
      uuid: uuid,
      name: name,
      iconCodePoint: Value(iconCodePoint),
      iconFontFamily: Value(iconFontFamily),
      createdAt: now,
      updatedAt: now,
    ));
    return (select(books)..where((b) => b.id.equals(id))).getSingle();
  }

  Future<Book?> getBook(int id) {
    return (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateBook(BooksCompanion companion) {
    return (update(books)..where((b) => b.id.equals(companion.id.value)))
        .write(companion);
  }

  Future<void> touchBook(int bookId) {
    return (update(books)..where((b) => b.id.equals(bookId)))
        .write(BooksCompanion(updatedAt: Value(DateTime.now())));
  }

  Future<void> softDeleteBook(int bookId) async {
    await (update(books)..where((b) => b.id.equals(bookId)))
        .write(BooksCompanion(deletedAt: Value(DateTime.now())));
    await (delete(transactions)..where((t) => t.bookId.equals(bookId))).go();
  }

  // ---------------------------------------------------------------------------
  // BookCategories CRUD
  // ---------------------------------------------------------------------------

  Stream<List<BookCategory>> watchBookCategories(int bookId) {
    return (select(bookCategories)
          ..where((c) => c.bookId.equals(bookId) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .watch();
  }

  Future<void> insertBookCategory(BookCategoriesCompanion entry) {
    return into(bookCategories).insert(entry);
  }

  Future<void> updateBookCategory(BookCategoriesCompanion entry) {
    return (update(bookCategories)..where((c) => c.id.equals(entry.id.value)))
        .write(entry);
  }

  Future<void> softDeleteBookCategory(int id) {
    return (update(bookCategories)..where((c) => c.id.equals(id)))
        .write(BookCategoriesCompanion(deletedAt: Value(DateTime.now())));
  }

  // ---------------------------------------------------------------------------
  // BookPaymentMethods CRUD
  // ---------------------------------------------------------------------------

  Stream<List<BookPaymentMethod>> watchBookPaymentMethods(int bookId) {
    return (select(bookPaymentMethods)
          ..where((p) => p.bookId.equals(bookId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]))
        .watch();
  }

  Future<void> insertBookPaymentMethod(BookPaymentMethodsCompanion entry) {
    return into(bookPaymentMethods).insert(entry);
  }

  Future<void> updateBookPaymentMethod(BookPaymentMethodsCompanion entry) {
    return (update(bookPaymentMethods)..where((p) => p.id.equals(entry.id.value)))
        .write(entry);
  }

  Future<void> softDeleteBookPaymentMethod(int id) {
    return (update(bookPaymentMethods)..where((p) => p.id.equals(id)))
        .write(BookPaymentMethodsCompanion(deletedAt: Value(DateTime.now())));
  }

  // ---------------------------------------------------------------------------
  // Book stats
  // ---------------------------------------------------------------------------

  Future<({int count, double totalIncome, double totalExpense})> getBookStats(int bookId) async {
    final rows = await customSelect(
      '''SELECT
           COUNT(*) AS cnt,
           SUM(CASE WHEN is_income = 1 THEN amount ELSE 0.0 END) AS income,
           SUM(CASE WHEN is_income = 0 THEN amount ELSE 0.0 END) AS expense
         FROM transactions
         WHERE book_id = ?''',
      variables: [Variable.withInt(bookId)],
      readsFrom: {transactions},
    ).get();
    final row = rows.first;
    return (
      count: row.read<int>('cnt'),
      totalIncome: row.read<double?>('income') ?? 0.0,
      totalExpense: row.read<double?>('expense') ?? 0.0,
    );
  }

  Stream<({int count, double totalIncome, double totalExpense})> watchBookStats(int bookId) {
    return customSelect(
      '''SELECT
           COUNT(*) AS cnt,
           SUM(CASE WHEN is_income = 1 THEN amount ELSE 0.0 END) AS income,
           SUM(CASE WHEN is_income = 0 THEN amount ELSE 0.0 END) AS expense
         FROM transactions
         WHERE book_id = ?''',
      variables: [Variable.withInt(bookId)],
      readsFrom: {transactions},
    ).watchSingle().map((row) => (
          count: row.read<int>('cnt'),
          totalIncome: row.read<double?>('income') ?? 0.0,
          totalExpense: row.read<double?>('expense') ?? 0.0,
        ));
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  Stream<List<Transaction>> watchFilteredTransactions({
    required int bookId,
    required String dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    required List<String> categories,
    required List<String> paymentMethods,
    bool? isIncome,
  }) {
    final now = DateTime.now();
    final query = select(transactions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ]);
    query.where((t) => _buildWhere(t, bookId, dateFilter, now,
        customStartDate, customEndDate, categories, paymentMethods, isIncome));
    return query.watch();
  }

  Future<List<Transaction>> fetchFilteredTransactionsPaged({
    required int bookId,
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
    query.where((t) => _buildWhere(t, bookId, dateFilter, now,
        customStartDate, customEndDate, categories, paymentMethods, isIncome));
    return query.get();
  }

  Expression<bool> _buildWhere(
    Transactions t,
    int bookId,
    String dateFilter,
    DateTime now,
    DateTime? customStartDate,
    DateTime? customEndDate,
    List<String> cats,
    List<String> pms,
    bool? isIncome,
  ) {
    final conditions = <Expression<bool>>[t.bookId.equals(bookId)];
    switch (dateFilter) {
      case defaultDateFilter:
        break;
      case 'Today':
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        conditions
          ..add(t.occurredAt.isBiggerOrEqualValue(start))
          ..add(t.occurredAt.isSmallerOrEqualValue(end));
        break;
      case 'This Week':
        final off = now.weekday - 1;
        final wStart = DateTime(now.year, now.month, now.day - off);
        final wEnd = DateTime(now.year, now.month, now.day - off + 6, 23, 59, 59, 999);
        conditions
          ..add(t.occurredAt.isBiggerOrEqualValue(wStart))
          ..add(t.occurredAt.isSmallerOrEqualValue(wEnd));
        break;
      case 'This Month':
        final mStart = DateTime(now.year, now.month);
        final mEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        conditions
          ..add(t.occurredAt.isBiggerOrEqualValue(mStart))
          ..add(t.occurredAt.isSmallerOrEqualValue(mEnd));
        break;
      case 'This Year':
        final yStart = DateTime(now.year);
        final yEnd = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        conditions
          ..add(t.occurredAt.isBiggerOrEqualValue(yStart))
          ..add(t.occurredAt.isSmallerOrEqualValue(yEnd));
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
    if (cats.isNotEmpty) conditions.add(t.category.isIn(cats));
    if (pms.isNotEmpty) conditions.add(t.paymentMethod.isIn(pms));
    if (isIncome != null) conditions.add(t.isIncome.equals(isIncome));
    return conditions.reduce((a, b) => a & b);
  }

  Future<Map<String, int>> fetchCategoryUsageCounts({required int bookId}) async {
    final rows = await customSelect(
      'SELECT category, COUNT(*) AS cnt FROM transactions WHERE book_id = ? GROUP BY category',
      variables: [Variable.withInt(bookId)],
      readsFrom: {transactions},
    ).get();
    return {for (final r in rows) r.read<String>('category'): r.read<int>('cnt')};
  }

  Future<int> addTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) {
    final id = entry.id.value;
    return (update(transactions)..where((t) => t.id.equals(id)))
        .write(entry)
        .then((count) => count > 0);
  }

  Future<int> deleteTransactionById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteAllTransactions({required int bookId}) {
    return (delete(transactions)..where((t) => t.bookId.equals(bookId))).go();
  }

  // ---------------------------------------------------------------------------
  // Global settings
  // ---------------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'spendwise.sqlite'));
    return NativeDatabase(file);
  });
}
