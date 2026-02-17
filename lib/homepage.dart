import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/home/pages/transaction_form_page.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/date_filters.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/widgets/filter_chips.dart';
import 'package:spendwise/home/widgets/summary_card.dart';
import 'package:spendwise/home/widgets/transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<String> _filters = <String>[
    'All',
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  String _selectedFilter = _filters.first;
  late final AppDatabase _database;
  late final TransactionsRepository _repository;

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
      switch (_selectedFilter) {
        case 'Today':
          return isSameDay(item.dateTime, now);
        case 'This Week':
          return isSameWeek(item.dateTime, now);
        case 'This Month':
          return item.dateTime.year == now.year && item.dateTime.month == now.month;
        case 'This Year':
          return item.dateTime.year == now.year;
        case 'All':
        default:
          return true;
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('SpendWise'),
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
                  child: FilterChips(
                    filters: _filters,
                    selected: _selectedFilter,
                    onSelected: (value) => setState(() => _selectedFilter = value),
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
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransactionFormPage(
                                            repository: _repository,
                                            isEditing: true,
                                            initialItem: item,
                                          ),
                                        ),
                                      );
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
    );
  }
}
