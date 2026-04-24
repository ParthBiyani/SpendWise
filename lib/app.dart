import 'package:flutter/material.dart';
import 'package:spendwise/books/pages/books_list_page.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Add authentication logic here in the future
    return const BooksListPage();
  }
}
