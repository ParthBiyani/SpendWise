import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
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
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'All',
  ];

  String _selectedFilter = _filters.first;

  final List<TransactionItem> _transactions = <TransactionItem>[
    TransactionItem(
      remarks: 'Salary',
      category: 'Income',
      subcategory: 'Primary',
      paymentMethod: 'Bank',
      referenceId: 'REF-1001',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 1, 9, 10, 12),
      amount: 5200000.00,
      isIncome: true,
    ),
    TransactionItem(
      remarks: 'Fuel',
      category: 'Transportation',
      subcategory: 'Commute',
      paymentMethod: 'Card',
      referenceId: 'REF-1003',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 11, 9, 5, 45),
      amount: 42000.75,
      isIncome: false,
    ),
    TransactionItem(
      remarks: 'Freelance',
      category: 'Income',
      subcategory: 'Client Work',
      paymentMethod: 'Bank',
      referenceId: 'REF-1004',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 9, 14, 15, 5),
      amount: 650000.00,
      isIncome: true,
    ),
    TransactionItem(
      remarks: 'Streaming',
      category: 'Entertainment',
      subcategory: 'Subscription',
      paymentMethod: 'Card',
      referenceId: 'REF-1005',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 6, 6, 45, 33),
      amount: 12000.99,
      isIncome: false,
    ),
    TransactionItem(
      remarks: 'Chips x2, chocolate & bread and some random shit',
      category: 'Necessity',
      subcategory: 'Grocery',
      paymentMethod: 'GPay',
      referenceId: 'REF-1002',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 6, 18, 30, 8),
      amount: 86000.40,
      isIncome: true,
    ),
    TransactionItem(
      remarks: 'Streaming',
      category: 'Entertainment',
      subcategory: 'Subscription',
      paymentMethod: 'Card',
      referenceId: 'REF-1005',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 6, 17, 45, 58),
      amount: 12000.99,
      isIncome: true,
    ),
    TransactionItem(
      remarks: 'Chips x2, chocolate & bread and some random shit',
      category: 'Necessity',
      subcategory: 'Grocery',
      paymentMethod: 'GPay',
      referenceId: 'REF-1002',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 6, 12, 30, 21),
      amount: 86000.40,
      isIncome: false,
    ),
    TransactionItem(
      remarks: 'Streaming',
      category: 'Entertainment',
      subcategory: 'Subscription',
      paymentMethod: 'Card',
      referenceId: 'REF-1005',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 6, 14, 45, 12),
      amount: 12000.99,
      isIncome: false,
    ),
    TransactionItem(
      remarks: 'Chips x2, chocolate & bread and some random shit',
      category: 'Necessity',
      subcategory: 'Grocery',
      paymentMethod: 'GPay',
      referenceId: 'REF-1002',
      entryBy: 'You',
      dateTime: DateTime(2026, 2, 6, 2, 30, 48),
      amount: 86000.40,
      isIncome: true,
    ),
  ];

  List<TransactionItem> get _filteredTransactions {
    final DateTime now = DateTime.now();
    return _transactions.where((item) {
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

  double get _totalIncome {
    return _filteredTransactions
        .where((item) => item.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get _totalExpense {
    return _filteredTransactions
        .where((item) => !item.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get _netBalance => _totalIncome - _totalExpense;

  List<DateGroup> get _groupedTransactions {
    final items = [..._filteredTransactions]
      ..sort((a, b) {
        final dateCompare = b.dateTime.compareTo(a.dateTime);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return compareTimeOfDay(b.dateTime, a.dateTime);
      });

    final Map<String, List<TransactionItem>> grouped = {};
    for (final item in items) {
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
    final groupedTransactions = _groupedTransactions;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('SpendWise'),
      ),
      body: SafeArea(
        child: CustomScrollView(
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
                  netBalance: _netBalance,
                  totalIncome: _totalIncome,
                  totalExpense: _totalExpense,
                ),
              ),
            ),
            if (groupedTransactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No transactions for this period',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...groupedTransactions.map((group) => SliverStickyHeader(
                    header: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TransactionTile(item: group.items[index]),
                            );
                          }
                          return const SizedBox(height: 16);
                        },
                        childCount: group.items.length + 1,
                      ),
                    ),
                  )),
          ],
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
                    // TODO: Add Money Out entry
                  },
                  icon: const Icon(Icons.north_east),
                  label: const Text('Money Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    // TODO: Add Money In entry
                  },
                  icon: const Icon(Icons.south_west),
                  label: const Text('Money In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
