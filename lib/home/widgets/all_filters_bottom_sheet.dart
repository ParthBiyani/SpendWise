import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spendwise/home/models/filter_state.dart'
    show FilterState, TransactionTypeFilter;
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';
import 'package:spendwise/providers.dart';

class AllFiltersBottomSheet extends ConsumerStatefulWidget {
  const AllFiltersBottomSheet({super.key});

  @override
  ConsumerState<AllFiltersBottomSheet> createState() =>
      _AllFiltersBottomSheetState();
}

class _AllFiltersBottomSheetState extends ConsumerState<AllFiltersBottomSheet> {
  late FilterState _currentFilters;

  static const List<String> _dateFilters = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'Custom Range',
  ];

  static const List<String> _transactionTypes = ['Money In', 'Money Out'];

  @override
  void initState() {
    super.initState();
    _currentFilters = ref.read(filterStateProvider);
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_currentFilters.customStartDate ?? now)
        : (_currentFilters.customEndDate ??
            _currentFilters.customStartDate ??
            now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _currentFilters = _currentFilters.copyWith(
          dateFilter: 'Custom Range',
          customStartDate: () =>
              DateTime(picked.year, picked.month, picked.day),
        );
      } else {
        _currentFilters = _currentFilters.copyWith(
          dateFilter: 'Custom Range',
          customEndDate: () =>
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999),
        );
      }
    });
  }

  void _showDateRangeErrorToast(BuildContext context) {
    final fToast = FToast()..init(context);
    fToast.showToast(
      toastDuration: const Duration(seconds: 2),
      positionedToastBuilder: (context, child, _) =>
          Positioned(left: 24, right: 24, bottom: 100, child: child),
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
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.8),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt,
                          color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'All Filters',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (_currentFilters.hasActiveFilters)
                        TextButton(
                          onPressed: () => setState(
                              () => _currentFilters = _currentFilters.cleared()),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey[300]),
              // Filters content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Filter
                      _buildSectionTitle(context, 'Date Range'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 0,
                        children: _dateFilters.map((filter) {
                          final isSelected =
                              _currentFilters.dateFilter == filter;
                          return ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: theme.colorScheme.primary,
                            backgroundColor: Colors.grey[100],
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                            ),
                            labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : null,
                            ),
                            onSelected: (_) => setState(() {
                              _currentFilters = _currentFilters.copyWith(
                                dateFilter: filter,
                                customStartDate:
                                    filter == 'Custom Range' ? null : () => null,
                                customEndDate:
                                    filter == 'Custom Range' ? null : () => null,
                              );
                            }),
                          );
                        }).toList(),
                      ),
                      if (_currentFilters.dateFilter == 'Custom Range') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickCustomDate(isStart: true),
                                icon: const Icon(Icons.calendar_today,
                                    size: 16),
                                label: Text(
                                  _currentFilters.customStartDate == null
                                      ? 'Start Date'
                                      : formatDate(
                                          _currentFilters.customStartDate!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickCustomDate(isStart: false),
                                icon: const Icon(Icons.calendar_today,
                                    size: 16),
                                label: Text(
                                  _currentFilters.customEndDate == null
                                      ? 'End Date'
                                      : formatDate(
                                          _currentFilters.customEndDate!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Transaction Type
                      _buildSectionTitle(context, 'Transaction Type'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _currentFilters.transactionType ==
                                TransactionTypeFilter.all,
                            showCheckmark: false,
                            selectedColor: theme.colorScheme.primary,
                            backgroundColor: Colors.grey[100],
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            side: BorderSide(
                              color: _currentFilters.transactionType ==
                                      TransactionTypeFilter.all
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                            ),
                            labelStyle: TextStyle(
                              color: _currentFilters.transactionType ==
                                      TransactionTypeFilter.all
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: _currentFilters.transactionType ==
                                      TransactionTypeFilter.all
                                  ? FontWeight.w600
                                  : null,
                            ),
                            onSelected: (_) => setState(() {
                              _currentFilters = _currentFilters.copyWith(
                                  transactionType: TransactionTypeFilter.all);
                            }),
                          ),
                          ..._transactionTypes.map((type) {
                            final enumValue = _typeForLabel(type);
                            final isSelected =
                                _currentFilters.transactionType == enumValue;
                            return FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type == 'Money In'
                                        ? Icons.south_west
                                        : Icons.north_east,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(type),
                                ],
                              ),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: type == 'Money In'
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.error,
                              backgroundColor: Colors.grey[100],
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              side: BorderSide(
                                color: isSelected
                                    ? (type == 'Money In'
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.error)
                                    : Colors.transparent,
                              ),
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : null,
                              ),
                              onSelected: (_) => setState(() {
                                _currentFilters = _currentFilters.copyWith(
                                  transactionType: isSelected
                                      ? TransactionTypeFilter.all
                                      : enumValue,
                                );
                              }),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Categories
                      _buildSectionTitle(context, 'Categories'),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 16.0;
                          final tileWidth =
                              (constraints.maxWidth - (spacing * 4)) / 5;
                          final tileSize = tileWidth.clamp(56.0, 72.0);
                          return SizedBox(
                            height: tileSize + 28,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: availableCategories.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: spacing),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  final isAllSelected =
                                      _currentFilters.categories.isEmpty;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _currentFilters = _currentFilters
                                          .copyWith(categories: []);
                                    }),
                                    child: SizedBox(
                                      width: tileSize,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            width: tileSize,
                                            height: tileSize,
                                            decoration: BoxDecoration(
                                              color: isAllSelected
                                                  ? theme.colorScheme.primary
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.12),
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.apps,
                                                size: tileSize * 0.38,
                                                color: isAllSelected
                                                    ? Colors.white
                                                    : theme
                                                        .colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'All',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              fontWeight: isAllSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isAllSelected
                                                  ? theme.colorScheme.primary
                                                  : theme
                                                      .colorScheme.onSurface,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final category =
                                    availableCategories[index - 1];
                                final isSelected = _currentFilters.categories
                                    .contains(category);
                                return CategoryTile(
                                  label: category,
                                  icon: categoryIcons[category] ??
                                      Icons.category,
                                  size: tileSize,
                                  selected: isSelected,
                                  hasSelection: false,
                                  selectedColor: theme.colorScheme.primary,
                                  onTap: () => setState(() {
                                    final updated = List<String>.from(
                                        _currentFilters.categories);
                                    if (isSelected) {
                                      updated.remove(category);
                                    } else {
                                      updated.add(category);
                                    }
                                    _currentFilters = _currentFilters
                                        .copyWith(categories: updated);
                                  }),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Payment Methods
                      _buildSectionTitle(context, 'Payment Methods'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: availablePaymentMethods.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 15),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isAllSelected =
                                  _currentFilters.paymentMethods.isEmpty;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _currentFilters = _currentFilters
                                      .copyWith(paymentMethods: []);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isAllSelected
                                        ? theme.colorScheme.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'All',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: isAllSelected
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            final method =
                                availablePaymentMethods[index - 1];
                            final isSelected = _currentFilters.paymentMethods
                                .contains(method);
                            return FilledPill(
                              label: method,
                              icon: paymentMethodIcons[method],
                              selected: isSelected,
                              hasSelection: false,
                              onTap: () => setState(() {
                                final updated = List<String>.from(
                                    _currentFilters.paymentMethods);
                                if (isSelected) {
                                  updated.remove(method);
                                } else {
                                  updated.add(method);
                                }
                                _currentFilters = _currentFilters
                                    .copyWith(paymentMethods: updated);
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side:
                              BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentFilters.dateFilter == 'Custom Range') {
                            if (_currentFilters.customStartDate != null &&
                                _currentFilters.customEndDate != null) {
                              if (_currentFilters.customStartDate!
                                  .isAfter(_currentFilters.customEndDate!)) {
                                _showDateRangeErrorToast(context);
                                return;
                              }
                            }
                          }
                          ref
                              .read(filterStateProvider.notifier)
                              .update(_currentFilters);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Filters',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TransactionTypeFilter _typeForLabel(String label) {
    return label == 'Money In'
        ? TransactionTypeFilter.income
        : TransactionTypeFilter.expense;
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
