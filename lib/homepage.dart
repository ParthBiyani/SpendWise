import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/pages/transaction_form_page.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/utils/date_filters.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/widgets/filter_row.dart';
import 'package:spendwise/home/widgets/summary_card.dart';
import 'package:spendwise/home/widgets/transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FilterState _filterState = const FilterState();
  late final AppDatabase _database;
  late final TransactionsRepository _repository;
  final Set<int> _selectedTransactionIds = {};
  bool _isSelectionMode = false;

  static const List<String> _availableCategories = [
    'Income',
    'Dining',
    'Snacks',
    'Shopping',
    'Groceries',
    'Travel',
    'Bills',
    'Health',
    'Education',
    'Investment',
    'Personal Care',
    'Entertainment',
    'Gifts',
    'EMIs',
    'Transfers',
    'Housing',
    'Others',
  ];

  static const List<String> _availablePaymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Bank',
  ];

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _repository = TransactionsRepository(_database);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  List<TransactionItem> _applyFilter(List<TransactionItem> items) {
    final DateTime now = DateTime.now();
    return items.where((item) {
      // Apply date filter
      bool dateMatch = true;
      switch (_filterState.dateFilter) {
        case 'Today':
          dateMatch = isSameDay(item.dateTime, now);
          break;
        case 'This Week':
          dateMatch = isSameWeek(item.dateTime, now);
          break;
        case 'This Month':
          dateMatch = item.dateTime.year == now.year && item.dateTime.month == now.month;
          break;
        case 'This Year':
          dateMatch = item.dateTime.year == now.year;
          break;
        case 'Custom Range':
          final start = _filterState.customStartDate;
          final end = _filterState.customEndDate;
          if (start != null && end != null) {
            dateMatch = !item.dateTime.isBefore(start) && !item.dateTime.isAfter(end);
          } else if (start != null) {
            dateMatch = !item.dateTime.isBefore(start);
          } else if (end != null) {
            dateMatch = !item.dateTime.isAfter(end);
          } else {
            dateMatch = true;
          }
          break;
        case 'All Time':
        default:
          dateMatch = true;
      }
      if (!dateMatch) return false;

      // Apply category filter
      if (_filterState.categories.isNotEmpty) {
        if (!_filterState.categories.contains(item.category)) {
          return false;
        }
      }

      // Apply payment method filter
      if (_filterState.paymentMethods.isNotEmpty) {
        if (!_filterState.paymentMethods.contains(item.paymentMethod)) {
          return false;
        }
      }

      // Apply transaction type filter
      if (_filterState.transactionType != null && 
          _filterState.transactionType!.isNotEmpty &&
          _filterState.transactionType!.length != 2) {
        if (_filterState.transactionType!.contains('Money In') && !item.isIncome) {
          return false;
        }
        if (_filterState.transactionType!.contains('Money Out') && item.isIncome) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<DateGroup> _groupTransactions(List<TransactionItem> items) {
    final sortedItems = [...items]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final Map<String, List<TransactionItem>> grouped = {};
    for (final item in sortedItems) {
      final key = formatDate(item.dateTime);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries
        .map((entry) => DateGroup(dateLabel: entry.key, items: entry.value))
        .toList();
  }

  void _toggleSelection(int transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
        if (_selectedTransactionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void _startSelectionMode(int transactionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactionIds.add(transactionId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  Future<void> _showDeleteConfirmation() async {
    final theme = Theme.of(context);
    final destructiveRed = Colors.red.shade700;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Padding above header
            const SizedBox(height: 16),
            // Header with warning icon and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.red.shade700,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedTransactionIds.length == 1
                          ? 'Delete Transaction'
                          : 'Delete Transactions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 1),
              child: Text(
                _selectedTransactionIds.length == 1
                    ? 'Are you sure you want to delete this transaction?'
                    : 'Are you sure you want to delete ${_selectedTransactionIds.length} transactions?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 1, 20, 24),
              child: Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Divider - 75% width and centered
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                child: Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
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
                    child: SizedBox(
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: destructiveRed,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: destructiveRed.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(true),
                          icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
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

    if (confirmed == true) {
      await _deleteSelectedTransactions();
    }
  }

  Future<void> _deleteSelectedTransactions() async {
    for (final id in _selectedTransactionIds) {
      await _repository.delete(id);
    }
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                )
              : null,
          title: _isSelectionMode
              ? Text('${_selectedTransactionIds.length} selected')
              : const Text('SpendWise'),
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _showDeleteConfirmation,
                  ),
                ]
              : null,
        ),
      body: SafeArea(
        child: StreamBuilder<List<TransactionItem>>(
          stream: _repository.watchAll(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <TransactionItem>[];
            final filteredItems = _applyFilter(items);
            final totalIncome = filteredItems
                .where((item) => item.isIncome)
                .fold(0.0, (sum, item) => sum + item.amount);
            final totalExpense = filteredItems
                .where((item) => !item.isIncome)
                .fold(0.0, (sum, item) => sum + item.amount);
            final netBalance = totalIncome - totalExpense;
            final groupedTransactions = _groupTransactions(filteredItems);

            final List<TransactionItem> ascendingItems = [...filteredItems]
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
            double runningBalance = 0;
            final Map<TransactionItem, double> balanceByItem = {};
            for (final item in ascendingItems) {
              runningBalance += item.isIncome ? item.amount : -item.amount;
              balanceByItem[item] = runningBalance;
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: FilterRow(
                    filterState: _filterState,
                    onFilterChanged: (newState) => setState(() => _filterState = newState),
                    availableCategories: _availableCategories,
                    availablePaymentMethods: _availablePaymentMethods,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SummaryCard(
                      netBalance: netBalance,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    ),
                  ),
                ),
                if (groupedTransactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading transactions...'
                            : 'No transactions for this period',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  ...groupedTransactions.map((group) => SliverStickyHeader(
                        header: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          alignment: Alignment.centerLeft,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Text(
                            group.dateLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index < group.items.length) {
                                final item = group.items[index];
                                final balanceAfter = balanceByItem[item] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TransactionTile(
                                    item: item,
                                    balanceAfter: balanceAfter,
                                    isSelected: _selectedTransactionIds.contains(item.id),
                                    isSelectionMode: _isSelectionMode,
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleSelection(item.id!);
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TransactionFormPage(
                                              repository: _repository,
                                              isEditing: true,
                                              initialItem: item,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_isSelectionMode && item.id != null) {
                                        _startSelectionMode(item.id!);
                                      }
                                    },
                                  ),
                                );
                              }
                              return const SizedBox(height: 16);
                            },
                            childCount: group.items.length + 1,
                          ),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TransactionFormPage(
                          repository: _repository,
                          initialIsIncome: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.north_east),
                  label: Text(
                    'Money Out',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TransactionFormPage(
                          repository: _repository,
                          initialIsIncome: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.south_west),
                  label: Text(
                    'Money In',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}