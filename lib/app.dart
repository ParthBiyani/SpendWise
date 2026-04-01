import 'package:flutter/material.dart';
import 'package:spendwise/homepage.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Add authentication logic here in the future
    // For now, we always show the HomePage
    return const HomePage();
  }
}
