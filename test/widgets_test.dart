import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/widgets/summary_card.dart';
import 'package:spendwise/home/widgets/transaction_tile.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in a minimal MaterialApp with the app's colour scheme so
/// widgets that call Theme.of(context) work correctly.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E394E),
        tertiary: Color(0xFF1A7A44),
        error: Color(0xFFC0392B),
        surface: Colors.white,
        onPrimary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: Colors.black,
      ),
      useMaterial3: true,
    ),
    home: Scaffold(body: child),
  );
}

TransactionItem _expense({
  int id = 1,
  String category = 'Groceries',
  double amount = 100.0,
  String? remarks,
  String? entryBy,
  DateTime? dateTime,
}) =>
    TransactionItem(
      id: id,
      category: category,
      classType: 'Necessity',
      amount: amount,
      isIncome: false,
      paymentMethod: 'Cash',
      dateTime: dateTime ?? DateTime(2024, 6, 15, 10, 30),
      remarks: remarks,
      entryBy: entryBy,
    );

TransactionItem _income({
  int id = 2,
  String category = 'Income',
  double amount = 500.0,
  DateTime? dateTime,
}) =>
    TransactionItem(
      id: id,
      category: category,
      classType: 'Others',
      amount: amount,
      isIncome: true,
      paymentMethod: 'UPI',
      dateTime: dateTime ?? DateTime(2024, 6, 15, 9, 0),
    );

// ---------------------------------------------------------------------------
// TransactionTile tests
// ---------------------------------------------------------------------------

void main() {
  group('TransactionTile', () {
    testWidgets('renders category name', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(category: 'Dining'),
        balanceAfter: 0,
      )));

      expect(find.text('Dining'), findsOneWidget);
    });

    testWidgets('renders remarks when non-null and non-empty', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(remarks: 'Weekly shop'),
        balanceAfter: 0,
      )));

      expect(find.text('Weekly shop'), findsOneWidget);
    });

    testWidgets('omits remarks row when remarks is null', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(remarks: null),
        balanceAfter: 0,
      )));

      // No empty Text widget for remarks
      final remarksCandidates = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.data == null || t.data!.isEmpty);
      expect(remarksCandidates, isEmpty);
    });

    testWidgets('omits remarks row when remarks is empty string', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(remarks: ''),
        balanceAfter: 0,
      )));

      expect(find.text(''), findsNothing);
    });

    testWidgets('shows formatted expense amount with minus prefix', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(amount: 100.0),
        balanceAfter: 900.0, // distinct from amount so text is unambiguous
      )));

      expect(find.text('-₹100.00'), findsOneWidget);
    });

    testWidgets('shows formatted income amount with plus prefix', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _income(amount: 500.0),
        balanceAfter: 1200.0, // distinct from amount
      )));

      expect(find.text('+₹500.00'), findsOneWidget);
    });

    testWidgets('shows Balance label and formatted balance value', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(amount: 200.0),
        balanceAfter: 800.0,
      )));

      expect(find.text('Balance:'), findsOneWidget);
      expect(find.text('₹800.00'), findsOneWidget);
    });

    testWidgets('falls back to "You" when entryBy is null', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(entryBy: null, dateTime: DateTime(2024, 6, 15, 10, 30)),
        balanceAfter: 0,
      )));

      expect(find.text('You · 10:30 AM'), findsOneWidget);
    });

    testWidgets('shows entryBy name when provided', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(entryBy: 'Alice', dateTime: DateTime(2024, 6, 15, 14, 0)),
        balanceAfter: 0,
      )));

      expect(find.text('Alice · 2:00 PM'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(),
        balanceAfter: 0,
        onTap: () => tapped = true,
      )));

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(),
        balanceAfter: 0,
        onLongPress: () => longPressed = true,
      )));

      await tester.longPress(find.byType(ListTile));
      expect(longPressed, isTrue);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(),
        balanceAfter: 0,
        isSelected: true,
        isSelectionMode: true,
      )));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows category icon when not selected', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(category: 'Groceries'),
        balanceAfter: 0,
        isSelected: false,
        isSelectionMode: true,
      )));

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('selected card uses primary colour background', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(),
        balanceAfter: 0,
        isSelected: true,
        isSelectionMode: true,
      )));

      final card = tester.widget<Card>(find.byType(Card));
      // Selected background is primary.withValues(alpha: 0.1), not plain white.
      expect(card.color, isNot(Colors.white));
    });

    testWidgets('unselected card uses white background', (tester) async {
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(),
        balanceAfter: 0,
        isSelected: false,
      )));

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, Colors.white);
    });

    testWidgets('semantics label includes category, amount and balance',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(category: 'Dining', amount: 250.0),
        balanceAfter: 750.0,
      )));

      expect(
        find.bySemanticsLabel(RegExp('Dining')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Expense')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('balance')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('semantics label includes selected state in selection mode',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(category: 'Travel'),
        balanceAfter: 0,
        isSelectionMode: true,
        isSelected: true,
      )));

      expect(
        find.bySemanticsLabel(RegExp(', selected')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('semantics label includes not-selected state in selection mode',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(TransactionTile(
        item: _expense(category: 'Travel'),
        balanceAfter: 0,
        isSelectionMode: true,
        isSelected: false,
      )));

      expect(
        find.bySemanticsLabel(RegExp(', not selected')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // SummaryCard tests
  // -------------------------------------------------------------------------

  group('SummaryCard', () {
    testWidgets('renders Net Balance label', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 200,
        totalIncome: 500,
        totalExpense: 300,
      )));

      expect(find.text('Net Balance'), findsOneWidget);
    });

    testWidgets('renders formatted net balance value', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 1500,
        totalIncome: 2000,
        totalExpense: 500,
      )));

      expect(find.text('₹1,500.00'), findsOneWidget);
    });

    testWidgets('renders Net Income label', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 0,
        totalIncome: 1000,
        totalExpense: 1000,
      )));

      expect(find.text('Net Income'), findsOneWidget);
    });

    testWidgets('renders formatted income value', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 300,
        totalIncome: 800,
        totalExpense: 500,
      )));

      expect(find.text('₹800.00'), findsOneWidget);
    });

    testWidgets('renders Net Expenses label', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 0,
        totalIncome: 0,
        totalExpense: 0,
      )));

      expect(find.text('Net Expenses'), findsOneWidget);
    });

    testWidgets('renders formatted expense value', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 300,
        totalIncome: 800,
        totalExpense: 500,
      )));

      expect(find.text('₹500.00'), findsOneWidget);
    });

    testWidgets('renders negative net balance with minus sign', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: -200,
        totalIncome: 300,
        totalExpense: 500,
      )));

      expect(find.text('-₹200.00'), findsOneWidget);
    });

    testWidgets('renders zero values as ₹0.00', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 0,
        totalIncome: 0,
        totalExpense: 0,
      )));

      // All three values display as ₹0.00
      expect(find.text('₹0.00'), findsNWidgets(3));
    });

    testWidgets('semantics label contains net balance amount', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 200,
        totalIncome: 500,
        totalExpense: 300,
      )));

      expect(
        find.bySemanticsLabel(RegExp('Net balance')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('semantics label contains income and expense amounts',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 200,
        totalIncome: 500,
        totalExpense: 300,
      )));

      expect(
        find.bySemanticsLabel(RegExp('Net income')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Net expenses')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('income value colour is tertiary (green)', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 200,
        totalIncome: 500,
        totalExpense: 300,
      )));

      // Find the Text widget whose value is '₹500.00' (income) and verify its
      // style uses the tertiary colour.
      final incomeText = tester.widgetList<Text>(find.byType(Text)).firstWhere(
            (t) => t.data == '₹500.00',
          );
      expect(incomeText.style?.color, const Color(0xFF1A7A44));
    });

    testWidgets('expense value colour is error (red)', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(bookName: 'Test',
        netBalance: 200,
        totalIncome: 500,
        totalExpense: 300,
      )));

      final expenseText = tester.widgetList<Text>(find.byType(Text)).firstWhere(
            (t) => t.data == '₹300.00',
          );
      expect(expenseText.style?.color, const Color(0xFFC0392B));
    });
  });
}
