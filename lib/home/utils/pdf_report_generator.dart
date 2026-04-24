import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/formatters.dart';

// ---------------------------------------------------------------------------
// Report type
// ---------------------------------------------------------------------------

enum ReportType { allEntries, daywise, categorywise, paymentwise }

// ---------------------------------------------------------------------------
// Report data input
// ---------------------------------------------------------------------------

class ReportConfig {
  const ReportConfig({
    required this.bookName,
    required this.reportType,
    required this.transactions,
    required this.durationLabel,
    this.categoryFilter = const [],
    this.paymentMethodFilter = const [],
    this.entryTypeLabel = 'Money In & Out',
  });

  final String bookName;
  final ReportType reportType;
  final List<TransactionItem> transactions;
  final String durationLabel;
  final List<String> categoryFilter;
  final List<String> paymentMethodFilter;
  final String entryTypeLabel;
}

// ---------------------------------------------------------------------------
// Generator
// ---------------------------------------------------------------------------

class PdfReportGenerator {
  static const _primary = PdfColor.fromInt(0xFF1E394E);
  static const _income = PdfColor.fromInt(0xFF27AE60);
  static const _expense = PdfColor.fromInt(0xFFE74C3C);
  static const _rowAlt = PdfColor.fromInt(0xFFF7F9FB);

  static Future<File> generate(ReportConfig config, String savePath) async {
    // Load NotoSans fonts (covers ₹ and extended Unicode)
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final emojiData = await rootBundle.load('assets/fonts/NotoEmoji.ttf');
    final ttfRegular = pw.Font.ttf(regularData);
    final ttfBold = pw.Font.ttf(boldData);
    final ttfEmoji = pw.Font.ttf(emojiData);

    // Load logo
    final logoData = await rootBundle.load('assets/SpendWise.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
        fontFallback: [ttfEmoji],
      ),
    );

    final totalIn = config.transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final totalOut = config.transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final balance = totalIn - totalOut;

    // All reports show oldest first, newest at the end.
    final sortedConfig = ReportConfig(
      bookName: config.bookName,
      reportType: config.reportType,
      transactions: config.transactions.reversed.toList(),
      durationLabel: config.durationLabel,
      categoryFilter: config.categoryFilter,
      paymentMethodFilter: config.paymentMethodFilter,
      entryTypeLabel: config.entryTypeLabel,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(config, logo),
        footer: _buildFooter,
        build: (ctx) => [
          _buildMeta(config, logo),
          pw.SizedBox(height: 12),
          _buildSummaryRow(totalIn, totalOut, balance),
          pw.SizedBox(height: 20),
          _buildTable(sortedConfig),
        ],
      ),
    );

    final file = File(savePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  static pw.Widget _buildHeader(ReportConfig config, pw.MemoryImage logo) {
    return pw.SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // Meta section (duration + filters)
  // ---------------------------------------------------------------------------

  static pw.Widget _buildMeta(ReportConfig config, pw.MemoryImage logo) {
    // book name 22pt + 4pt gap + report type 11pt ≈ 48pt combined visual height
    const logoSize = 60.0;

    final filterRows = <pw.Widget>[
      _metaRow('Duration', config.durationLabel),
      _metaRow('Entry Type', config.entryTypeLabel),
    ];
    if (config.categoryFilter.isNotEmpty) {
      filterRows.add(_metaRow('Categories', config.categoryFilter.join(', ')));
    }
    if (config.paymentMethodFilter.isNotEmpty) {
      filterRows.add(_metaRow('Payment Methods', config.paymentMethodFilter.join(', ')));
    }
    filterRows.add(_metaRow('Generated', _formatDateTime(DateTime.now())));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Book name + report type on left, logo on right
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  config.bookName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _reportTypeLabel(config.reportType),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Image(logo, width: logoSize, height: logoSize),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: _primary, thickness: 1.5),
        pw.SizedBox(height: 8),
        ...filterRows,
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary row
  // ---------------------------------------------------------------------------

  static pw.Widget _buildSummaryRow(double totalIn, double totalOut, double balance) {
    return pw.Row(
      children: [
        _summaryBox('Total Money In', formatCurrency(totalIn), _income),
        pw.SizedBox(width: 8),
        _summaryBox('Total Money Out', formatCurrency(totalOut), _expense),
        pw.SizedBox(width: 8),
        _summaryBox(
          'Net Balance',
          formatCurrency(balance),
          PdfColors.black,
        ),
      ],
    );
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table dispatcher
  // ---------------------------------------------------------------------------

  static pw.Widget _buildTable(ReportConfig config) {
    return switch (config.reportType) {
      ReportType.allEntries => _buildAllEntriesTable(config.transactions),
      ReportType.daywise => _buildDaywiseTable(config.transactions),
      ReportType.categorywise => _buildCategorywiseTable(config.transactions),
      ReportType.paymentwise => _buildPaymentwiseTable(config.transactions),
    };
  }

  // ---------------------------------------------------------------------------
  // All entries table
  // ---------------------------------------------------------------------------

  static pw.Widget _buildAllEntriesTable(List<TransactionItem> txns) {
    const headers = ['Date', 'Remarks', 'Category', 'Mode', 'Money In', 'Money Out', 'Balance'];
    const columnWidths = {
      0: pw.FlexColumnWidth(1.4), // Date
      1: pw.FlexColumnWidth(2.0), // Remarks
      2: pw.FlexColumnWidth(1.5), // Category
      3: pw.FlexColumnWidth(1.0), // Mode
      4: pw.FlexColumnWidth(1.4), // Money In
      5: pw.FlexColumnWidth(1.4), // Money Out
      6: pw.FlexColumnWidth(1.4), // Balance
    };
    const cellPad = pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5);
    const border = pw.TableBorder(
      left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    );

    // Header row
    final headerCells = headers.map((h) => pw.Container(
      padding: cellPad,
      color: _primary,
      alignment: pw.Alignment.center,
      child: pw.Text(
        h,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        textAlign: pw.TextAlign.center,
      ),
    )).toList();

    // List is oldest-first (reversed in generate()). Accumulate top-to-bottom.
    final balances = List<double>.filled(txns.length, 0);
    double running = 0;
    for (var i = 0; i < txns.length; i++) {
      running += txns[i].isIncome ? txns[i].amount : -txns[i].amount;
      balances[i] = running;
    }

    final dataRows = txns.asMap().entries.map((entry) {
      final i = entry.key;
      final t = entry.value;
      final bg = i.isOdd ? _rowAlt : PdfColors.white;

      pw.Widget cell(String text, {
        pw.Alignment align = pw.Alignment.centerLeft,
        pw.TextStyle? style,
      }) =>
          pw.Padding(
            padding: cellPad,
            child: pw.Align(
              alignment: align.y == 0 ? align : pw.Alignment(align.x, 0),
              child: pw.Text(text, style: style ?? const pw.TextStyle(fontSize: 8)),
            ),
          );

      return pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: pw.BoxDecoration(color: bg),
        children: [
          cell(_fmtDate(t.dateTime)),
          cell(t.remarks?.isNotEmpty == true ? t.remarks! : '-'),
          cell(t.category),
          cell(t.paymentMethod),
          cell(
            t.isIncome ? formatCurrency(t.amount) : '-',
            align: pw.Alignment.centerRight,
            style: t.isIncome
                ? pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _income)
                : const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
          cell(
            !t.isIncome ? formatCurrency(t.amount) : '-',
            align: pw.Alignment.centerRight,
            style: !t.isIncome
                ? pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _expense)
                : const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
          cell(
            formatCurrency(balances[i]),
            align: pw.Alignment.centerRight,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
        ],
      );
    }).toList();

    return pw.Table(
      border: border,
      columnWidths: columnWidths,
      children: [
        pw.TableRow(children: headerCells),
        ...dataRows,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Day-wise table
  // ---------------------------------------------------------------------------

  static pw.Widget _buildDaywiseTable(List<TransactionItem> txns) {
    final Map<String, ({double income, double expense})> dayMap = {};
    for (final t in txns) {
      final key = _fmtDate(t.dateTime);
      final cur = dayMap[key] ?? (income: 0.0, expense: 0.0);
      dayMap[key] = t.isIncome
          ? (income: cur.income + t.amount, expense: cur.expense)
          : (income: cur.income, expense: cur.expense + t.amount);
    }

    final sortedDays = dayMap.keys.toList()
      ..sort((a, b) => _parseDate(b).compareTo(_parseDate(a)));

    const headers = ['Date', 'Money In', 'Money Out', 'Balance'];
    final rows = sortedDays.map((day) {
      final d = dayMap[day]!;
      return [day, formatCurrency(d.income), formatCurrency(d.expense), formatCurrency(d.income - d.expense)];
    }).toList();

    return _styledTable(
      headers: headers,
      rows: rows,
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Category-wise table
  // ---------------------------------------------------------------------------

  static pw.Widget _buildCategorywiseTable(List<TransactionItem> txns) {
    final Map<String, ({double income, double expense})> map = {};
    for (final t in txns) {
      final cur = map[t.category] ?? (income: 0.0, expense: 0.0);
      map[t.category] = t.isIncome
          ? (income: cur.income + t.amount, expense: cur.expense)
          : (income: cur.income, expense: cur.expense + t.amount);
    }

    final sorted = map.entries.toList()
      ..sort((a, b) => (b.value.income + b.value.expense).compareTo(a.value.income + a.value.expense));

    const headers = ['Category', 'Money In', 'Money Out', 'Balance'];
    final rows = sorted.map((e) => [
      e.key,
      formatCurrency(e.value.income),
      formatCurrency(e.value.expense),
      formatCurrency(e.value.income - e.value.expense),
    ]).toList();

    return _styledTable(
      headers: headers,
      rows: rows,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Payment-wise table
  // ---------------------------------------------------------------------------

  static pw.Widget _buildPaymentwiseTable(List<TransactionItem> txns) {
    final Map<String, ({double income, double expense})> map = {};
    for (final t in txns) {
      final cur = map[t.paymentMethod] ?? (income: 0.0, expense: 0.0);
      map[t.paymentMethod] = t.isIncome
          ? (income: cur.income + t.amount, expense: cur.expense)
          : (income: cur.income, expense: cur.expense + t.amount);
    }

    final sorted = map.entries.toList()
      ..sort((a, b) => (b.value.income + b.value.expense).compareTo(a.value.income + a.value.expense));

    const headers = ['Payment Method', 'Money In', 'Money Out', 'Balance'];
    final rows = sorted.map((e) => [
      e.key,
      formatCurrency(e.value.income),
      formatCurrency(e.value.expense),
      formatCurrency(e.value.income - e.value.expense),
    ]).toList();

    return _styledTable(
      headers: headers,
      rows: rows,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Shared styled table builder
  // ---------------------------------------------------------------------------

  static pw.Widget _styledTable({
    required List<String> headers,
    required List<List<String>> rows,
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    const cellPad = pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5);
    const border = pw.TableBorder(
      left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    );

    // Header row
    final headerCells = headers.asMap().entries.map((e) {
      return pw.Container(
        padding: cellPad,
        color: _primary,
        alignment: pw.Alignment.center,
        child: pw.Text(
          e.value,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    }).toList();

    // Data rows — background set on TableRow so it fills the full row height
    // even when a cell wraps to multiple lines.
    final dataRows = rows.asMap().entries.map((rowEntry) {
      final rowIndex = rowEntry.key;
      final row = rowEntry.value;
      final isOdd = rowIndex.isOdd;
      final bg = isOdd ? _rowAlt : PdfColors.white;

      final cells = row.map((text) {
        return pw.Padding(
          padding: cellPad,
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
          ),
        );
      }).toList();

      return pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: pw.BoxDecoration(color: bg),
        children: cells,
      );
    }).toList();

    return pw.Table(
      border: border,
      columnWidths: columnWidths,
      children: [
        pw.TableRow(children: headerCells),
        ...dataRows,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated by SpendWise',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static DateTime _parseDate(String s) {
    final parts = s.split('/');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  static String _formatDateTime(DateTime d) =>
      '${_fmtDate(d)} ${formatTime(d)}';

  static String _reportTypeLabel(ReportType type) => switch (type) {
    ReportType.allEntries => 'All Entries Report',
    ReportType.daywise => 'Day-wise Report',
    ReportType.categorywise => 'Category-wise Report',
    ReportType.paymentwise => 'Payment Method-wise Report',
  };
}
