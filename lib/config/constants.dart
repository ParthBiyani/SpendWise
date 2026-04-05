import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// App colour palette
// ---------------------------------------------------------------------------

const Color appPrimaryColor = Color(0xFF1E394E);
const Color appIncomeColor = Color(0xFF27AE60);
const Color appExpenseColor = Color(0xFFE74C3C);

/// Describes a single transaction category.
class CategoryInfo {
  const CategoryInfo({
    required this.name,
    required this.icon,
    required this.classType,
  });

  /// Display name and database value (e.g. 'Dining').
  final String name;

  /// Icon shown in category selectors and transaction tiles.
  final IconData icon;

  /// Class type stored on the transaction: 'Necessity', 'Desire',
  /// 'Investment', or 'Others'.
  final String classType;
}

/// All supported categories, in display order.
/// This is the single source of truth for names, icons, and class types.
/// The v2→v3 migration SQL contains a frozen copy of the classification —
/// this list governs all live reads and writes.
const List<CategoryInfo> categories = [
  CategoryInfo(name: 'Income',        icon: Icons.currency_rupee,  classType: 'Others'),
  CategoryInfo(name: 'Dining',        icon: Icons.restaurant,       classType: 'Desire'),
  CategoryInfo(name: 'Snacks',        icon: Icons.fastfood,         classType: 'Desire'),
  CategoryInfo(name: 'Shopping',      icon: Icons.shopping_bag,     classType: 'Desire'),
  CategoryInfo(name: 'Groceries',     icon: Icons.shopping_cart,    classType: 'Necessity'),
  CategoryInfo(name: 'Travel',        icon: Icons.directions_car,   classType: 'Necessity'),
  CategoryInfo(name: 'Bills',         icon: Icons.receipt_long,     classType: 'Necessity'),
  CategoryInfo(name: 'Health',        icon: Icons.health_and_safety, classType: 'Necessity'),
  CategoryInfo(name: 'Education',     icon: Icons.school,           classType: 'Investment'),
  CategoryInfo(name: 'Investment',    icon: Icons.trending_up,      classType: 'Investment'),
  CategoryInfo(name: 'Personal Care', icon: Icons.spa,              classType: 'Necessity'),
  CategoryInfo(name: 'Entertainment', icon: Icons.movie,            classType: 'Desire'),
  CategoryInfo(name: 'Gifts',         icon: Icons.card_giftcard,    classType: 'Desire'),
  CategoryInfo(name: 'EMIs',          icon: Icons.payments,         classType: 'Necessity'),
  CategoryInfo(name: 'Transfers',     icon: Icons.swap_horiz,       classType: 'Others'),
  CategoryInfo(name: 'Housing',       icon: Icons.home,             classType: 'Necessity'),
  CategoryInfo(name: 'Others',        icon: Icons.category,         classType: 'Desire'),
];

/// Describes a payment method with its display name and icon.
class PaymentMethodInfo {
  const PaymentMethodInfo({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

/// All supported payment methods, in display order.
const List<PaymentMethodInfo> paymentMethods = [
  PaymentMethodInfo(name: 'Cash', icon: Icons.payments),
  PaymentMethodInfo(name: 'UPI',  icon: Icons.qr_code),
  PaymentMethodInfo(name: 'Card', icon: Icons.credit_card),
  PaymentMethodInfo(name: 'Bank', icon: Icons.account_balance),
];

/// Valid class types for transactions.
const List<String> classTypes = [
  'Necessity',
  'Desire',
  'Investment',
  'Others',
];

/// Available date filters shown across the app.
const List<String> dateFilters = [
  'All Time',
  'Today',
  'This Week',
  'This Month',
  'This Year',
  'Custom Range',
];

/// Default date filter when no date constraint is applied.
const String defaultDateFilter = 'All Time';

/// Payment method name for cash — used to conditionally disable the reference
/// ID field (cash transactions have no reference number).
const String cashPaymentMethod = 'Cash';
