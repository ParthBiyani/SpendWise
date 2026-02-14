import 'package:spendwise/home/models/transaction_item.dart';

class DateGroup {
  const DateGroup({required this.dateLabel, required this.items});

  final String dateLabel;
  final List<TransactionItem> items;
}
