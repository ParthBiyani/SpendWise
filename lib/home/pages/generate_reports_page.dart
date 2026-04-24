import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spendwise/config/constants.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/utils/pdf_report_generator.dart';
import 'package:spendwise/home/utils/toast_utils.dart';
import 'package:spendwise/providers.dart';

// ---------------------------------------------------------------------------
// Report type enum
// ---------------------------------------------------------------------------

enum _ReportType {
  allEntries('All Entries Report', 'Full list of every transaction with details', Icons.list_alt),
  daywise('Day-wise Report', 'Daily totals of money in, out & balance', Icons.calendar_today),
  categorywise('Category-wise Report', 'Money in & out totals per category', Icons.category),
  paymentwise('Payment method-wise Report', 'Money in & out totals per payment method', Icons.payment);

  const _ReportType(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class GenerateReportsPage extends ConsumerStatefulWidget {
  const GenerateReportsPage({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<GenerateReportsPage> createState() => _GenerateReportsPageState();
}

class _GenerateReportsPageState extends ConsumerState<GenerateReportsPage> {
  // Filters
  String _dateFilter = defaultDateFilter;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedPaymentMethods = {};
  bool _includeIncome = true;
  bool _includeExpense = true;

  // Report type
  _ReportType _reportType = _ReportType.allEntries;

  // Generation state
  bool _isGenerating = false;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _dateFilterLabel {
    if (_dateFilter != 'Custom Range') return _dateFilter;
    if (_customStartDate == null || _customEndDate == null) return 'Custom Range';
    return '${_compactDate(_customStartDate!)} - ${_compactDate(_customEndDate!)}';
  }

  static String _compactDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year.toString().substring(2)}';

  // ---------------------------------------------------------------------------
  // Custom date range picker (same style as filter_row)
  // ---------------------------------------------------------------------------

  Future<bool> _pickCustomRange() async {
    final now = DateTime.now();
    DateTime start = _customStartDate ?? DateTime(now.year, now.month, now.day);
    DateTime end = _customEndDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Custom Date Range'),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: start,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(now.year + 10),
                    );
                    if (picked != null) {
                      setDialog(() => start = DateTime(picked.year, picked.month, picked.day));
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Start: ${formatDate(start)}'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: end,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(now.year + 10),
                    );
                    if (picked != null) {
                      setDialog(() => end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999));
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('End: ${formatDate(end)}'),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text('Cancel',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(ctx).colorScheme.onSurface,
                            backgroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: 0.15),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.18),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              if (start.isAfter(end)) {
                                showAppToast(ctx, 'Start date must be before end date');
                                return;
                              }
                              Navigator.pop(dialogContext, DateTimeRange(start: start, end: end));
                            },
                            icon: const Icon(Icons.check, color: Colors.white, size: 20),
                            label: const Text('Apply',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _customStartDate = result.start;
        _customEndDate = result.end;
      });
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Multi-select bottom sheet
  // ---------------------------------------------------------------------------

  Future<void> _showMultiSelect({
    required String title,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
    Map<String, IconData>? icons,
  }) async {
    final theme = Theme.of(context);
    final temp = Set<String>.from(selected);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setSheet(temp.clear),
                      child: Text('Clear all',
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((opt) {
                    final isSelected = temp.contains(opt);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (v) => setSheet(() {
                        if (v == true) { temp.add(opt); } else { temp.remove(opt); }
                      }),
                      title: Row(
                        children: [
                          if (icons != null && icons[opt] != null) ...[
                            Icon(icons[opt], size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                          ],
                          Text(opt),
                        ],
                      ),
                      activeColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.18),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        onChanged(temp);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF generation
  // ---------------------------------------------------------------------------

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);
    try {
      // 1. On Android API <= 29, request WRITE_EXTERNAL_STORAGE.
      //    On API 30+ no permission is needed to write to Downloads.
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (status.isDenied) {
          final requested = await Permission.storage.request();
          // On API 30+ the permission is permanently denied by the OS
          // (not user-facing) — that's fine, we can still write to Downloads.
          // Only bail out if the user explicitly denied it on API <= 29.
          if (requested.isPermanentlyDenied) {
            if (mounted) {
              showAppToast(context, 'Storage permission required. Please enable it in app settings.');
              openAppSettings();
            }
            return;
          }
        }
      }

      // 2. Fetch all transactions matching current filters
      final transactionType = !_includeIncome && !_includeExpense
          ? TransactionTypeFilter.all
          : _includeIncome && !_includeExpense
              ? TransactionTypeFilter.income
              : !_includeIncome && _includeExpense
                  ? TransactionTypeFilter.expense
                  : TransactionTypeFilter.all;

      final filterState = FilterState(
        dateFilter: _dateFilter,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
        categories: _selectedCategories.toList(),
        paymentMethods: _selectedPaymentMethods.toList(),
        transactionType: transactionType,
      );

      final repo = ref.read(repositoryProvider);
      if (repo == null) return;
      // Fetch all (no paging) by using a very large limit
      final transactions = await repo.fetchPaged(filterState, limit: 1000000, offset: 0);

      // 3. Build save path in Downloads folder
      late final String savePath;
      if (Platform.isAndroid) {
        const downloadsPath = '/storage/emulated/0/Download';
        savePath = '$downloadsPath/SpendWise_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/SpendWise_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      // 4. Build report config
      final bookName = ref.read(bookNameProvider).valueOrNull ?? 'Wallet Transactions';
      final reportType = switch (_reportType) {
        _ReportType.allEntries => ReportType.allEntries,
        _ReportType.daywise => ReportType.daywise,
        _ReportType.categorywise => ReportType.categorywise,
        _ReportType.paymentwise => ReportType.paymentwise,
      };

      final entryTypeLabel = !_includeIncome && !_includeExpense
          ? 'None'
          : _includeIncome && !_includeExpense
              ? 'Money In only'
              : !_includeIncome && _includeExpense
                  ? 'Money Out only'
                  : 'Money In & Out';

      final config = ReportConfig(
        bookName: bookName,
        reportType: reportType,
        transactions: transactions,
        durationLabel: _dateFilterLabel,
        categoryFilter: _selectedCategories.toList(),
        paymentMethodFilter: _selectedPaymentMethods.toList(),
        entryTypeLabel: entryTypeLabel,
      );

      // 5. Generate PDF
      final file = await PdfReportGenerator.generate(config, savePath);

      if (!mounted) return;

      // 6. Show toast with save path
      showAppToast(context, 'Report saved to ${file.path}');

      // 7. Open the file
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) showAppToast(context, 'Failed to generate report: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> allCategories = ref.watch(sortedCategoriesProvider).valueOrNull
        ?? ref.watch(availableCategoriesProvider);
    final categoryIcons = ref.watch(categoryIconsProvider);
    final allPaymentMethods = ref.watch(availablePaymentMethodsProvider);
    final paymentIcons = ref.watch(paymentMethodIconsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Generate Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          // ── Filters ──────────────────────────────────────────────────────
          const _SectionHeader(title: 'Filters'),

          // Row 1: Time Frame + Entry Type
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FilterTile(
                    icon: Icons.calendar_today,
                    label: 'Duration',
                    value: _dateFilterLabel,
                    onTap: () async {
                      final picked = await showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _DateFilterSheet(selected: _dateFilter),
                      );
                      if (picked == null) return;
                      if (picked == 'Custom Range') {
                        final picked2 = await _pickCustomRange();
                        if (picked2) setState(() => _dateFilter = 'Custom Range');
                      } else {
                        setState(() {
                          _dateFilter = picked;
                          _customStartDate = null;
                          _customEndDate = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterTile(
                    icon: Icons.swap_vert,
                    label: 'Entry Type',
                    value: _includeIncome && _includeExpense
                        ? 'Money In & Out'
                        : _includeIncome
                            ? 'Money In only'
                            : _includeExpense
                                ? 'Money Out only'
                                : 'None selected',
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => StatefulBuilder(
                          builder: (ctx, setSheet) => Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  width: 36, height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text('Entry Type',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  value: _includeIncome,
                                  onChanged: (v) => setSheet(() => _includeIncome = v ?? true),
                                  title: Row(children: [
                                    Icon(Icons.south_west, size: 18, color: theme.colorScheme.tertiary),
                                    const SizedBox(width: 10),
                                    const Text('Money In'),
                                  ]),
                                  activeColor: theme.colorScheme.primary,
                                ),
                                CheckboxListTile(
                                  value: _includeExpense,
                                  onChanged: (v) => setSheet(() => _includeExpense = v ?? true),
                                  title: Row(children: [
                                    Icon(Icons.north_east, size: 18, color: theme.colorScheme.error),
                                    const SizedBox(width: 10),
                                    const Text('Money Out'),
                                  ]),
                                  activeColor: theme.colorScheme.primary,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.18),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {});
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Apply',
                                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Row 2: Categories + Payment Methods
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FilterTile(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    value: _selectedCategories.isEmpty
                        ? 'All categories'
                        : '${_selectedCategories.length} selected',
                    badge: _selectedCategories.isNotEmpty ? _selectedCategories.length : null,
                    onTap: () => _showMultiSelect(
                      title: 'Select Categories',
                      options: allCategories,
                      selected: _selectedCategories,
                      icons: categoryIcons,
                      onChanged: (v) => setState(() {
                        _selectedCategories.clear();
                        _selectedCategories.addAll(v);
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterTile(
                    icon: Icons.payment_outlined,
                    label: 'Payment Methods',
                    value: _selectedPaymentMethods.isEmpty
                        ? 'All payment methods'
                        : '${_selectedPaymentMethods.length} selected',
                    badge: _selectedPaymentMethods.isNotEmpty ? _selectedPaymentMethods.length : null,
                    onTap: () => _showMultiSelect(
                      title: 'Select Payment Methods',
                      options: allPaymentMethods,
                      selected: _selectedPaymentMethods,
                      icons: paymentIcons,
                      onChanged: (v) => setState(() {
                        _selectedPaymentMethods.clear();
                        _selectedPaymentMethods.addAll(v);
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Report Type ───────────────────────────────────────────────────
          const _SectionHeader(title: 'Report Type'),
          ...(_ReportType.values.map((type) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReportTypeTile(
              type: type,
              isSelected: _reportType == type,
              onTap: () => setState(() => _reportType = type),
            ),
          ))),
        ],
      ),

      // ── Generate PDF button ───────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: _isGenerating ? null : _generatePdf,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  'Generate PDF Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header (same style as settings page)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter tile — tappable row showing current value
// ---------------------------------------------------------------------------

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row: icon + label + badge + chevron
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 6),
            // Value row
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report type tile — selectable card
// ---------------------------------------------------------------------------

class _ReportTypeTile extends StatelessWidget {
  const _ReportTypeTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final _ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(type.icon,
                  size: 20,
                  color: isSelected ? Colors.white : theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? theme.colorScheme.primary : null,
                      )),
                  const SizedBox(height: 2),
                  Text(type.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      )),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date filter bottom sheet
// ---------------------------------------------------------------------------

class _DateFilterSheet extends StatelessWidget {
  const _DateFilterSheet({required this.selected});
  final String selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Duration',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          ...dateFilters.map((filter) => ListTile(
            title: Text(filter),
            leading: Icon(
              filter == selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            onTap: () => Navigator.pop(context, filter),
            selected: filter == selected,
            selectedColor: theme.colorScheme.primary,
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
