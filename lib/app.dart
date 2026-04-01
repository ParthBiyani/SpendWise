import 'package:flutter/material.dart';
import 'package:spendwise/data/local/app_database.dart';
import 'package:spendwise/data/repositories/transactions_repository.dart';
import 'package:spendwise/homepage.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
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

  @override
  Widget build(BuildContext context) {
    // TODO: Add authentication logic here in the future
    // For now, we always show the HomePage
    return HomePage(repository: _repository);
  }
}
