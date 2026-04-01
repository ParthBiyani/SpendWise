import 'package:flutter/material.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/pages/transaction_form_page.dart';
import 'package:spendwise/home/utils/transaction_utils.dart';
import 'package:spendwise/home/widgets/delete_confirmation_dialog.dart';
import 'package:spendwise/home/widgets/filter_row.dart';
import 'package:spendwise/home/widgets/grouped_transaction_sliver.dart';
import 'package:spendwise/home/widgets/home_bottom_bar.dart';
import 'package:spendwise/home/widgets/summary_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});

  final TransactionsRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FilterState _filterState = const FilterState();
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

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedTransactionIds.contains(id)) {
        _selectedTransactionIds.remove(id);
        if (_selectedTransactionIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedTransactionIds.add(id);
      }
    });
  }

  void _startSelectionMode(int id) {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactionIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      count: _selectedTransactionIds.length,
    );
    if (confirmed) {
      for (final id in _selectedTransactionIds) {
        await widget.repository.delete(id);
      }
      _exitSelectionMode();
    }
  }

  void _openForm({bool isIncome = false, TransactionItem? item}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => item != null
            ? TransactionFormPage(
                repository: widget.repository,
                isEditing: true,
                initialItem: item,
              )
            : TransactionFormPage(
                repository: widget.repository,
                initialIsIncome: isIncome,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _isSelectionMode) _exitSelectionMode();
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
                    onPressed: _confirmAndDelete,
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: StreamBuilder<List<TransactionItem>>(
            stream: widget.repository.watchAll(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <TransactionItem>[];
              final filtered = applyFilter(items, _filterState);
              final groups = groupTransactions(filtered);
              final balances = computeRunningBalances(filtered);

              final totalIncome = filtered
                  .where((i) => i.isIncome)
                  .fold(0.0, (sum, i) => sum + i.amount);
              final totalExpense = filtered
                  .where((i) => !i.isIncome)
                  .fold(0.0, (sum, i) => sum + i.amount);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: FilterRow(
                      filterState: _filterState,
                      onFilterChanged: (s) =>
                          setState(() => _filterState = s),
                      availableCategories: _availableCategories,
                      availablePaymentMethods: _availablePaymentMethods,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SummaryCard(
                        netBalance: totalIncome - totalExpense,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                      ),
                    ),
                  ),
                  if (groups.isEmpty)
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
                    GroupedTransactionSliver(
                      groups: groups,
                      balances: balances,
                      selectedIds: _selectedTransactionIds,
                      isSelectionMode: _isSelectionMode,
                      onTap: (item) {
                        if (_isSelectionMode) {
                          _toggleSelection(item.id!);
                        } else {
                          _openForm(item: item);
                        }
                      },
                      onLongPress: (item) {
                        if (!_isSelectionMode && item.id != null) {
                          _startSelectionMode(item.id!);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: HomeBottomBar(
          onMoneyOut: () => _openForm(isIncome: false),
          onMoneyIn: () => _openForm(isIncome: true),
        ),
      ),
    );
  }
}
