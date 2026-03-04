import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/widgets/all_filters_bottom_sheet.dart';
import 'package:spendwise/home/widgets/filter_dropdown.dart';
import 'package:spendwise/home/utils/formatters.dart';

class FilterRow extends StatelessWidget {
  const FilterRow({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
    required this.availableCategories,
    required this.availablePaymentMethods,
  });

  final FilterState filterState;
  final ValueChanged<FilterState> onFilterChanged;
  final List<String> availableCategories;
  final List<String> availablePaymentMethods;

  static const List<String> _dateFilters = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'Custom Range',
  ];

  static const List<String> _transactionTypes = [
    'Money In',
    'Money Out',
  ];

  Future<void> _showAllFiltersBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<FilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AllFiltersBottomSheet(
        initialFilters: filterState,
        availableCategories: availableCategories,
        availablePaymentMethods: availablePaymentMethods,
      ),
    );

    if (result != null) {
      onFilterChanged(result);
    }
  }

  Future<void> _handleDateFilterChanged(
    BuildContext context,
    List<String> selected,
  ) async {
    if (selected.isEmpty) return;
    final value = selected.first;

    if (value == 'Custom Range') {
      final picked = await _showCustomRangeDialog(context);

      if (picked != null) {
        final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
        final end = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        );
        onFilterChanged(
          filterState.copyWith(
            dateFilter: 'Custom Range',
            customStartDate: () => start,
            customEndDate: () => end,
          ),
        );
      }
      return;
    }

    onFilterChanged(
      filterState.copyWith(
        dateFilter: value,
        customStartDate: () => null,
        customEndDate: () => null,
      ),
    );
  }

  void _showDateRangeErrorToast(BuildContext context) {
    final fToast = FToast()..init(context);
    fToast.showToast(
      toastDuration: const Duration(seconds: 2),
      positionedToastBuilder: (context, child, _) {
        return Positioned(
          left: 24,
          right: 24,
          bottom: 100,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Start date must be before end date',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTimeRange?> _showCustomRangeDialog(BuildContext context) async {
    final now = DateTime.now();
    DateTime startDate =
        filterState.customStartDate ?? DateTime(now.year, now.month, now.day);
    DateTime endDate =
        filterState.customEndDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                          startDate = DateTime(picked.year, picked.month, picked.day);
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
                            picked.year,
                            picked.month,
                            picked.day,
                            23,
                            59,
                            59,
                            999,
                          );
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
                            label: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              // Validate that start date is not after end date
                              if (startDate.isAfter(endDate)) {
                                _showDateRangeErrorToast(context);
                                return;
                              }
                              Navigator.of(dialogContext).pop(
                                DateTimeRange(start: startDate, end: endDate),
                              );
                            },
                            icon: const Icon(Icons.check, color: Colors.white, size: 20),
                            label: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: Icon(
                Icons.filter_alt,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Date Filter
          FilterDropdown(
            icon: Icons.calendar_today,
            label: _getDateFilterLabel(filterState),
            items: _dateFilters,
            selectedItems: [filterState.dateFilter],
            onChanged: (selected) => _handleDateFilterChanged(context, selected),
            highlightWhenSelected: filterState.dateFilter != 'All Time',
          ),
          const SizedBox(width: 8),
          // Categories Filter
          FilterDropdown(
            label: 'Categories',
            items: availableCategories,
            selectedItems: filterState.categories,
            onChanged: (selected) {
              onFilterChanged(filterState.copyWith(categories: selected));
            },
            isMultiSelect: true,
            badge: filterState.categories.isNotEmpty ? filterState.categories.length : null,
            showIcon: false,
            showAllOption: true,
          ),
          const SizedBox(width: 8),
          // Payment Method Filter
          FilterDropdown(
            label: 'Payment',
            items: availablePaymentMethods,
            selectedItems: filterState.paymentMethods,
            onChanged: (selected) {
              onFilterChanged(filterState.copyWith(paymentMethods: selected));
            },
            isMultiSelect: true,
            badge: filterState.paymentMethods.isNotEmpty ? filterState.paymentMethods.length : null,
            showIcon: false,
            showAllOption: true,
          ),
          const SizedBox(width: 8),
          // Transaction Type Filter
          FilterDropdown(
            label: _getTypeFilterLabel(filterState.transactionType),
            items: _transactionTypes,
            selectedItems: filterState.transactionType ?? [],
            onChanged: (selected) {
              onFilterChanged(
                filterState.copyWith(
                  transactionType: () => selected.isEmpty || selected.length == 2 ? null : selected,
                ),
              );
            },
            isMultiSelect: true,
            showIcon: false,
            showAllOption: true,
          ),
          const SizedBox(width: 8),
          // Clear All button
          if (filterState.hasActiveFilters)
            InkWell(
              onTap: () => onFilterChanged(filterState.cleared()),
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
                    Icon(
                      Icons.clear,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
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

  static String _getTypeFilterLabel(List<String>? transactionType) {
    if (transactionType == null || transactionType.isEmpty || transactionType.length == 2) {
      return 'Type';
    }
    return transactionType.first;
  }

  static String _getDateFilterLabel(FilterState filterState) {
    if (filterState.dateFilter != 'Custom Range') {
      return filterState.dateFilter;
    }
    if (filterState.customStartDate == null || filterState.customEndDate == null) {
      return 'Custom Range';
    }
    final start = formatDate(filterState.customStartDate!);
    final end = formatDate(filterState.customEndDate!);
    return '$start - $end';
  }
}
