import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/config/constants.dart';
import 'package:spendwise/home/models/filter_state.dart'
    show FilterState, TransactionTypeFilter;
import 'package:spendwise/home/widgets/all_filters_bottom_sheet.dart';
import 'package:spendwise/home/widgets/filter_dropdown.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/utils/toast_utils.dart';
import 'package:spendwise/providers.dart';

class FilterRow extends ConsumerWidget {
  const FilterRow({super.key});

  static const List<String> _transactionTypes = ['Money In', 'Money Out'];

  void _showAllFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AllFiltersBottomSheet(),
    );
  }

  Future<void> _handleDateFilterChanged(
    BuildContext context,
    WidgetRef ref,
    List<String> selected,
  ) async {
    if (selected.isEmpty) return;
    final value = selected.first;
    final filterState = ref.read(filterStateProvider);
    final notifier = ref.read(filterStateProvider.notifier);

    if (value == 'Custom Range') {
      final picked = await _showCustomRangeDialog(context, filterState);
      if (picked != null) {
        final start =
            DateTime(picked.start.year, picked.start.month, picked.start.day);
        final end = DateTime(
            picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
        notifier.update(filterState.copyWith(
          dateFilter: 'Custom Range',
          customStartDate: () => start,
          customEndDate: () => end,
        ));
      }
      return;
    }

    notifier.update(filterState.copyWith(
      dateFilter: value,
      customStartDate: () => null,
      customEndDate: () => null,
    ));
  }


  Future<DateTimeRange?> _showCustomRangeDialog(
    BuildContext context,
    FilterState filterState,
  ) async {
    final now = DateTime.now();
    DateTime startDate =
        filterState.customStartDate ?? DateTime(now.year, now.month, now.day);
    DateTime endDate = filterState.customEndDate ??
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Custom Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startDate =
                          DateTime(picked.year, picked.month, picked.day);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('Start: ${formatDate(startDate)}'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      endDate = DateTime(
                          picked.year, picked.month, picked.day, 23, 59, 59, 999);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('End: ${formatDate(endDate)}'),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          if (startDate.isAfter(endDate)) {
                            showAppToast(context, 'Start date must be before end date');
                            return;
                          }
                          Navigator.of(dialogContext).pop(
                              DateTimeRange(start: startDate, end: endDate));
                        },
                        icon:
                            const Icon(Icons.check, color: Colors.white, size: 20),
                        label: const Text('Apply',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(filterStateProvider);
    final notifier = ref.read(filterStateProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // All Filters button
          InkWell(
            onTap: () => _showAllFiltersBottomSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.filter_alt,
                  size: 16, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          // Date Filter
          FilterDropdown(
            icon: Icons.calendar_today,
            label: _getDateFilterLabel(filterState),
            items: dateFilters,
            selectedItems: [filterState.dateFilter],
            onChanged: (selected) =>
                _handleDateFilterChanged(context, ref, selected),
            highlightWhenSelected: filterState.dateFilter != defaultDateFilter,
          ),
          const SizedBox(width: 8),
          // Categories Filter
          FilterDropdown(
            label: 'Categories',
            items: ref.watch(sortedCategoriesProvider).valueOrNull
                ?? ref.watch(availableCategoriesProvider),
            selectedItems: filterState.categories,
            onChanged: (selected) =>
                notifier.update(filterState.copyWith(categories: selected)),
            isMultiSelect: true,
            badge: filterState.categories.isNotEmpty
                ? filterState.categories.length
                : null,
            showIcon: false,
            showAllOption: true,
          ),
          const SizedBox(width: 8),
          // Payment Method Filter
          FilterDropdown(
            label: 'Payment',
            items: ref.watch(availablePaymentMethodsProvider),
            selectedItems: filterState.paymentMethods,
            onChanged: (selected) =>
                notifier.update(filterState.copyWith(paymentMethods: selected)),
            isMultiSelect: true,
            badge: filterState.paymentMethods.isNotEmpty
                ? filterState.paymentMethods.length
                : null,
            showIcon: false,
            showAllOption: true,
          ),
          const SizedBox(width: 8),
          // Transaction Type Filter
          FilterDropdown(
            label: _getTypeFilterLabel(filterState.transactionType),
            items: _transactionTypes,
            selectedItems: _typeToSelectedItems(filterState.transactionType),
            onChanged: (selected) => notifier.update(
              filterState.copyWith(
                transactionType: _selectedItemsToType(selected),
              ),
            ),
            isMultiSelect: true,
            showIcon: false,
            showAllOption: true,
          ),
          const SizedBox(width: 8),
          // Clear All button
          if (filterState.hasActiveFilters)
            InkWell(
              onTap: notifier.reset,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: theme.colorScheme.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear, size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Text(
                      'Clear All',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _getTypeFilterLabel(TransactionTypeFilter type) {
    return switch (type) {
      TransactionTypeFilter.all => 'Type',
      TransactionTypeFilter.income => 'Money In',
      TransactionTypeFilter.expense => 'Money Out',
    };
  }

  static List<String> _typeToSelectedItems(TransactionTypeFilter type) {
    return switch (type) {
      TransactionTypeFilter.all => [],
      TransactionTypeFilter.income => ['Money In'],
      TransactionTypeFilter.expense => ['Money Out'],
    };
  }

  static TransactionTypeFilter _selectedItemsToType(List<String> selected) {
    if (selected.isEmpty || selected.length == 2) {
      return TransactionTypeFilter.all;
    }
    return selected.first == 'Money In'
        ? TransactionTypeFilter.income
        : TransactionTypeFilter.expense;
  }

  static String _getDateFilterLabel(FilterState filterState) {
    if (filterState.dateFilter != 'Custom Range') return filterState.dateFilter;
    if (filterState.customStartDate == null ||
        filterState.customEndDate == null) { return 'Custom Range'; }
    return '${formatDate(filterState.customStartDate!)} - ${formatDate(filterState.customEndDate!)}';
  }
}
