import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/pages/transaction_form_page.dart';
import 'package:spendwise/home/widgets/delete_confirmation_dialog.dart';
import 'package:spendwise/home/widgets/filter_row.dart';
import 'package:spendwise/home/widgets/grouped_transaction_sliver.dart';
import 'package:spendwise/home/widgets/home_bottom_bar.dart';
import 'package:spendwise/home/widgets/summary_card.dart';
import 'package:spendwise/home/utils/toast_utils.dart';
import 'package:spendwise/home/pages/generate_reports_page.dart';
import 'package:spendwise/home/pages/import_transactions_page.dart';
import 'package:spendwise/home/pages/settings_page.dart';
import 'package:spendwise/providers.dart';

class _AppSegmentedToggle extends StatelessWidget {
  const _AppSegmentedToggle({
    required this.showAnalytics,
    required this.onChanged,
  });

  final bool showAnalytics;
  final ValueChanged<bool> onChanged;

  static const double _height = 40;
  static const double _padding = 4;
  static const double _radius = 14;
  static const double _pillRadius = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(0.0, 260.0)
            : 240.0;
        final pillWidth = (totalWidth - _padding * 2) / 2;

        return Container(
          width: totalWidth,
          height: _height,
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: showAnalytics
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: pillWidth,
                  height: _height - _padding * 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_pillRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _AppToggleLabel(
                      label: 'Transactions',
                      selected: !showAnalytics,
                      onTap: () => onChanged(false),
                      theme: theme,
                    ),
                  ),
                  Expanded(
                    child: _AppToggleLabel(
                      label: 'Analytics',
                      selected: showAnalytics,
                      onTap: () => onChanged(true),
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppToggleLabel extends StatelessWidget {
  const _AppToggleLabel({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

enum _AppMenu { settings, generateReports, importTransactions, deleteAll }

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: effectiveColor)),
      ],
    );
  }
}


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Set<int> _selectedTransactionIds = {};
  bool _isSelectionMode = false;
  bool _showAnalytics = false;
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

  Future<void> _confirmAndDeleteAll() async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      count: 0,
      deleteAll: true,
    );
    if (confirmed) {
      final repo = ref.read(repositoryProvider);
      try {
        await repo.deleteAll();
      } catch (e) {
        if (mounted) showAppToast(context, 'Failed to delete all transactions: $e');
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      count: _selectedTransactionIds.length,
    );
    if (confirmed) {
      final repo = ref.read(repositoryProvider);
      try {
        for (final id in _selectedTransactionIds) {
          await repo.delete(id);
        }
        _exitSelectionMode();
      } catch (e) {
        if (mounted) showAppToast(context, 'Failed to delete transactions: $e');
      }
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
    final bookName = ref.watch(bookNameProvider).valueOrNull ?? 'Wallet Transactions';
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
              : IconButton(
                  icon: Icon(
                    theme.platform == TargetPlatform.iOS
                        ? Icons.arrow_back_ios
                        : Icons.arrow_back,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
          title: _isSelectionMode
              ? Text('${_selectedTransactionIds.length} selected')
              : _AppSegmentedToggle(
                  showAnalytics: _showAnalytics,
                  onChanged: (value) => setState(() => _showAnalytics = value),
                ),
          centerTitle: true,
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _confirmAndDelete,
                  ),
                ]
              : [
                  PopupMenuButton<_AppMenu>(
                    icon: const Icon(Icons.more_vert),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    offset: const Offset(0, 48),
                    onSelected: (item) {
                      switch (item) {
                        case _AppMenu.settings:
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ));
                        case _AppMenu.generateReports:
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const GenerateReportsPage(),
                          ));
                        case _AppMenu.importTransactions:
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ImportTransactionsPage(),
                          ));
                        case _AppMenu.deleteAll:
                          _confirmAndDeleteAll();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _AppMenu.settings,
                        height: 40,
                        child: _MenuItem(icon: Icons.settings_outlined, label: 'Settings'),
                      ),
                      const PopupMenuItem(
                        value: _AppMenu.generateReports,
                        height: 40,
                        child: _MenuItem(icon: Icons.picture_as_pdf_outlined, label: 'Generate reports'),
                      ),
                      const PopupMenuItem(
                        value: _AppMenu.importTransactions,
                        height: 40,
                        child: _MenuItem(icon: Icons.upload_file_outlined, label: 'Import transactions'),
                      ),
                      PopupMenuItem(
                        value: _AppMenu.deleteAll,
                        height: 40,
                        child: _MenuItem(
                          icon: Icons.delete_outline,
                          label: 'Delete all transactions',
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
        ),
        body: SafeArea(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final dx = details.primaryVelocity ?? 0;
              if (!_showAnalytics && dx < -300) {
                setState(() => _showAnalytics = true);
              } else if (_showAnalytics && dx > 300) {
                setState(() => _showAnalytics = false);
              }
            },
            child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showAnalytics
                ? const Center(
                    key: ValueKey('analytics'),
                    child: Text('Analytics page'),
                  )
                : CustomScrollView(
                    key: const ValueKey('transactions'),
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
                          bookName: bookName,
                        ),
                      ),
                    ),
                    if (pageState.hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 48, color: theme.colorScheme.error),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load transactions',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${pageState.error}',
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (groups.isEmpty)
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
          ),
        ),
        bottomNavigationBar: _showAnalytics
            ? null
            : HomeBottomBar(
                onMoneyOut: () => _openForm(isIncome: false),
                onMoneyIn: () => _openForm(isIncome: true),
              ),
      ),
    );
  }
}
