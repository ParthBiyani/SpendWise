import 'package:flutter/material.dart';
import 'package:spendwise/home/models/date_group.dart';
import 'package:spendwise/home/widgets/date_header.dart';
import 'package:spendwise/home/widgets/transaction_tile.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key, required this.groups});

  final List<DateGroup> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No transactions for this period',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final List<Widget> children = [];
    double runningBalance = 0;
    for (final group in groups) {
      children.add(DateHeader(label: group.dateLabel));
      for (final item in group.items) {
        runningBalance += item.isIncome ? item.amount : -item.amount;
        children.add(TransactionTile(item: item, balanceAfter: runningBalance));
        children.add(const SizedBox(height: 0));
      }
      if (children.isNotEmpty) {
        children.removeLast();
      }
      children.add(const SizedBox(height: 16));
    }

    if (children.isNotEmpty) {
      children.removeLast();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: children,
      ),
    );
  }
}
