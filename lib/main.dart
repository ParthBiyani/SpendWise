import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/app.dart';
import 'package:spendwise/config/constants.dart'
    show appPrimaryColor, appIncomeColor, appExpenseColor;

void main() {
  runApp(const ProviderScope(child: SpendWiseApp()));
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: appPrimaryColor,
          secondary: appPrimaryColor,
          tertiary: appIncomeColor,
          error: appExpenseColor,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.black,
          onError: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
