import 'package:flutter/material.dart';
import 'package:spendwise/homepage.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  @override
  Widget build(BuildContext context) {
    // TODO: Add authentication logic here in the future
    // For now, we always show the HomePage
    return const HomePage();
  }
}
