import 'package:flutter/material.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/widgets/category_payment_widgets.dart';

class AllFiltersBottomSheet extends StatefulWidget {
  const AllFiltersBottomSheet({
    super.key,
    required this.initialFilters,
    required this.availableCategories,
    required this.availablePaymentMethods,
  });

  final FilterState initialFilters;
  final List<String> availableCategories;
  final List<String> availablePaymentMethods;

  @override
  State<AllFiltersBottomSheet> createState() => _AllFiltersBottomSheetState();
}

class _AllFiltersBottomSheetState extends State<AllFiltersBottomSheet> {
  late FilterState _currentFilters;

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

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_currentFilters.customStartDate ?? now)
        : (_currentFilters.customEndDate ?? _currentFilters.customStartDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        final start = DateTime(picked.year, picked.month, picked.day);
        DateTime? end = _currentFilters.customEndDate;
        if (end != null && end.isBefore(start)) {
          end = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
            999,
          );
        }
        _currentFilters = _currentFilters.copyWith(
          dateFilter: 'Custom Range',
          customStartDate: () => start,
          customEndDate: () => end,
        );
      } else {
        final end = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
          999,
        );
        DateTime? start = _currentFilters.customStartDate;
        if (start != null && start.isAfter(end)) {
          start = DateTime(picked.year, picked.month, picked.day);
        }
        _currentFilters = _currentFilters.copyWith(
          dateFilter: 'Custom Range',
          customStartDate: () => start,
          customEndDate: () => end,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.8,
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
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
                          onPressed: () {
                            setState(() {
                              _currentFilters = _currentFilters.cleared();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        final isSelected = _currentFilters.dateFilter == filter;
                        return ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: Colors.grey[100],
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _currentFilters = _currentFilters.copyWith(
                                dateFilter: filter,
                                customStartDate:
                                    filter == 'Custom Range'
                                        ? null
                                        : () => null,
                                customEndDate:
                                    filter == 'Custom Range'
                                        ? null
                                        : () => null,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_currentFilters.dateFilter == 'Custom Range') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickCustomDate(isStart: true),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _currentFilters.customStartDate == null
                                    ? 'Start Date'
                                    : formatDate(_currentFilters.customStartDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickCustomDate(isStart: false),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _currentFilters.customEndDate == null
                                    ? 'End Date'
                                    : formatDate(_currentFilters.customEndDate!),
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
                        // All button for Transaction Type
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _currentFilters.transactionType == null,
                          showCheckmark: false,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: Colors.grey[100],
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          side: BorderSide(
                            color: _currentFilters.transactionType == null
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                          labelStyle: TextStyle(
                            color: _currentFilters.transactionType == null
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: _currentFilters.transactionType == null
                                ? FontWeight.w600
                                : null,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _currentFilters = _currentFilters.copyWith(
                                transactionType: () => null,
                              );
                            });
                          },
                        ),
                        ..._transactionTypes.map((type) {
                        final isSelected = _currentFilters.transactionType?.contains(type) ?? false;
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type == 'Money In'
                                    ? Icons.south_west
                                    : Icons.north_east,
                                size: 16,
                                color: isSelected ? Colors.white : Colors.black87,
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
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          side: BorderSide(
                            color: isSelected
                                ? (type == 'Money In'
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.error)
                                : Colors.transparent,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                          onSelected: (_) {
                            setState(() {
                              final currentTypes = List<String>.from(_currentFilters.transactionType ?? []);
                              if (isSelected) {
                                // Clicking the already selected type - deselect it
                                currentTypes.remove(type);
                              } else {
                                // Clicking a different type
                                if (currentTypes.isNotEmpty) {
                                  // Replace the current selection with the new one
                                  currentTypes.clear();
                                }
                                currentTypes.add(type);
                              }
                              _currentFilters = _currentFilters.copyWith(
                                transactionType: () => currentTypes.isEmpty ? null : currentTypes,
                              );
                            });
                          },
                        );
                      }).toList(),
                   ] ),
                    const SizedBox(height: 16),
                    // Categories
                    _buildSectionTitle(context, 'Categories'),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 16.0;
                        final tileWidth = (constraints.maxWidth - (spacing * 4)) / 5;
                        final tileSize = tileWidth.clamp(56.0, 72.0);
                        return SizedBox(
                          height: tileSize + 28,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.availableCategories.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: spacing),
                            itemBuilder: (context, index) {
                              // All button for Categories
                              if (index == 0) {
                                final isAllSelected = _currentFilters.categories.isEmpty;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentFilters = _currentFilters.copyWith(
                                        categories: [],
                                      );
                                    });
                                  },
                                  child: SizedBox(
                                    width: tileSize,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: tileSize,
                                          height: tileSize,
                                          decoration: BoxDecoration(
                                            color: isAllSelected
                                                ? theme.colorScheme.primary
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.apps,
                                              size: tileSize * 0.38,
                                              color: isAllSelected
                                                  ? Colors.white
                                                  : theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'All',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isAllSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface,
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
                              
                              final category = widget.availableCategories[index - 1];
                              final isSelected = _currentFilters.categories.contains(category);
                              final icon = categoryIcons[category] ?? Icons.category;
                              return CategoryTile(
                                label: category,
                                icon: icon,
                                size: tileSize,
                                selected: isSelected,
                                hasSelection: false,
                                selectedColor: theme.colorScheme.primary,
                                onTap: () {
                                  setState(() {
                                    final newCategories = List<String>.from(_currentFilters.categories);
                                    if (isSelected) {
                                      newCategories.remove(category);
                                    } else {
                                      newCategories.add(category);
                                    }
                                    _currentFilters = _currentFilters.copyWith(
                                      categories: newCategories,
                                    );
                                  });
                                },
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
                        itemCount: widget.availablePaymentMethods.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 15),
                        itemBuilder: (context, index) {
                          // All button for Payment Methods
                          if (index == 0) {
                            final isAllSelected = _currentFilters.paymentMethods.isEmpty;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentFilters = _currentFilters.copyWith(
                                    paymentMethods: [],
                                  );
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isAllSelected
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'All',
                                    style: theme.textTheme.labelMedium?.copyWith(
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
                          
                          final method = widget.availablePaymentMethods[index - 1];
                          final isSelected = _currentFilters.paymentMethods.contains(method);
                          final icon = paymentMethodIcons[method];
                          return FilledPill(
                            label: method,
                            icon: icon,
                            selected: isSelected,
                            hasSelection: false,
                            onTap: () {
                              setState(() {
                                final newMethods = List<String>.from(_currentFilters.paymentMethods);
                                if (isSelected) {
                                  newMethods.remove(method);
                                } else {
                                  newMethods.add(method);
                                }
                                _currentFilters = _currentFilters.copyWith(
                                  paymentMethods: newMethods,
                                );
                              });
                            },
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
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_currentFilters),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
