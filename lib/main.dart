import 'package:flutter/material.dart';
import 'package:spendwise/app.dart';

void main() {
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  static const Color _accentColor = Color(0xFF1E394E);
  static const Color _incomeColor = Color(0xFF27AE60);
  static const Color _expenseColor = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: _accentColor,
          secondary: _accentColor,
          tertiary: _incomeColor,
          error: _expenseColor,
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
