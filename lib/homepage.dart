import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/pages/transaction_form_page.dart';
import 'package:spendwise/home/widgets/delete_confirmation_dialog.dart';
import 'package:spendwise/home/widgets/filter_row.dart';
import 'package:spendwise/home/widgets/grouped_transaction_sliver.dart';
import 'package:spendwise/home/widgets/home_bottom_bar.dart';
import 'package:spendwise/home/widgets/summary_card.dart';
import 'package:spendwise/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Set<int> _selectedTransactionIds = {};
  bool _isSelectionMode = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(transactionPageProvider.notifier).loadNextPage();
    }
  }

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
      final repo = ref.read(repositoryProvider);
      for (final id in _selectedTransactionIds) {
        await repo.delete(id);
      }
      _exitSelectionMode();
    }
  }

  void _openForm({bool isIncome = false, TransactionItem? item}) {
    final repo = ref.read(repositoryProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => item != null
            ? TransactionFormPage(
                repository: repo,
                isEditing: true,
                initialItem: item,
              )
            : TransactionFormPage(
                repository: repo,
                initialIsIncome: isIncome,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final groups = ref.watch(groupedTransactionsProvider);
    final balances = ref.watch(runningBalancesProvider);
    final summary = ref.watch(summaryProvider);
    final pageState = ref.watch(transactionPageProvider);
    final isLoading = pageState.isLoading;
    final isLoadingMore = pageState.valueOrNull?.isLoadingMore ?? false;

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
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: FilterRow()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SummaryCard(
                    netBalance: summary.netBalance,
                    totalIncome: summary.totalIncome,
                    totalExpense: summary.totalExpense,
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      isLoading
                          ? 'Loading transactions...'
                          : 'No transactions for this period',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else ...[
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
                if (isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ],
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
