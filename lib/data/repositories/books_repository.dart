import 'package:flutter/material.dart';
import 'package:spendwise/config/constants.dart' as defaults;
import 'package:spendwise/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class BooksRepository {
  BooksRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Books
  // ---------------------------------------------------------------------------

  Stream<List<Book>> watchAll() => _db.watchAllBooks();

  Future<Book> create(String name, {IconData icon = Icons.menu_book_outlined}) async {
    final book = await _db.createBook(
      name,
      _uuid.v4(),
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily,
    );
    await _seedDefaults(book.id);
    return book;
  }

  Future<void> _seedDefaults(int bookId) async {
    final now = DateTime.now();
    for (var i = 0; i < defaults.categories.length; i++) {
      final cat = defaults.categories[i];
      await _db.insertBookCategory(BookCategoriesCompanion.insert(
        uuid: _uuid.v4(),
        bookId: bookId,
        name: cat.name,
        iconCodePoint: cat.icon.codePoint,
        iconFontFamily: Value(cat.icon.fontFamily),
        classType: cat.classType,
        sortOrder: Value(i),
        updatedAt: now,
      ));
    }
    for (var i = 0; i < defaults.paymentMethods.length; i++) {
      final pm = defaults.paymentMethods[i];
      await _db.insertBookPaymentMethod(BookPaymentMethodsCompanion.insert(
        uuid: _uuid.v4(),
        bookId: bookId,
        name: pm.name,
        iconCodePoint: pm.icon.codePoint,
        iconFontFamily: Value(pm.icon.fontFamily),
        sortOrder: Value(i),
        updatedAt: now,
      ));
    }
  }

  Future<void> rename(int id, String name) {
    return _db.updateBook(BooksCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateIcon(int id, IconData icon) {
    return _db.updateBook(BooksCompanion(
      id: Value(id),
      iconCodePoint: Value(icon.codePoint),
      iconFontFamily: Value(icon.fontFamily),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> delete(int id) => _db.softDeleteBook(id);

  Future<Book?> getBook(int id) => _db.getBook(id);

  Future<({int count, double totalIncome, double totalExpense})> getStats(int bookId) {
    return _db.getBookStats(bookId);
  }

  Stream<({int count, double totalIncome, double totalExpense})> watchStats(int bookId) {
    return _db.watchBookStats(bookId);
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  Stream<List<BookCategory>> watchCategories(int bookId) =>
      _db.watchBookCategories(bookId);

  Future<void> addCategory(int bookId, defaults.CategoryInfo cat) {
    final now = DateTime.now();
    return _db.insertBookCategory(BookCategoriesCompanion.insert(
      uuid: _uuid.v4(),
      bookId: bookId,
      name: cat.name,
      iconCodePoint: cat.icon.codePoint,
      iconFontFamily: Value(cat.icon.fontFamily),
      classType: cat.classType,
      updatedAt: now,
    ));
  }

  Future<void> updateCategory(int id, defaults.CategoryInfo cat, {required int sortOrder}) {
    final now = DateTime.now();
    return _db.updateBookCategory(BookCategoriesCompanion(
      id: Value(id),
      name: Value(cat.name),
      iconCodePoint: Value(cat.icon.codePoint),
      iconFontFamily: Value(cat.icon.fontFamily),
      classType: Value(cat.classType),
      sortOrder: Value(sortOrder),
      updatedAt: Value(now),
    ));
  }

  Future<void> removeCategory(int id) => _db.softDeleteBookCategory(id);

  // ---------------------------------------------------------------------------
  // Payment methods
  // ---------------------------------------------------------------------------

  Stream<List<BookPaymentMethod>> watchPaymentMethods(int bookId) =>
      _db.watchBookPaymentMethods(bookId);

  Future<void> addPaymentMethod(int bookId, defaults.PaymentMethodInfo pm) {
    final now = DateTime.now();
    return _db.insertBookPaymentMethod(BookPaymentMethodsCompanion.insert(
      uuid: _uuid.v4(),
      bookId: bookId,
      name: pm.name,
      iconCodePoint: pm.icon.codePoint,
      iconFontFamily: Value(pm.icon.fontFamily),
      updatedAt: now,
    ));
  }

  Future<void> updatePaymentMethod(int id, defaults.PaymentMethodInfo pm, {required int sortOrder}) {
    final now = DateTime.now();
    return _db.updateBookPaymentMethod(BookPaymentMethodsCompanion(
      id: Value(id),
      name: Value(pm.name),
      iconCodePoint: Value(pm.icon.codePoint),
      iconFontFamily: Value(pm.icon.fontFamily),
      sortOrder: Value(sortOrder),
      updatedAt: Value(now),
    ));
  }

  Future<void> removePaymentMethod(int id) => _db.softDeleteBookPaymentMethod(id);

  // ---------------------------------------------------------------------------
  // Helpers: convert DB rows → app models
  // ---------------------------------------------------------------------------

  static defaults.CategoryInfo categoryFromRow(BookCategory row) => defaults.CategoryInfo(
        name: row.name,
        icon: IconData(row.iconCodePoint, fontFamily: row.iconFontFamily),
        classType: row.classType,
      );

  static defaults.PaymentMethodInfo paymentMethodFromRow(BookPaymentMethod row) => defaults.PaymentMethodInfo(
        name: row.name,
        icon: IconData(row.iconCodePoint, fontFamily: row.iconFontFamily),
      );
}
