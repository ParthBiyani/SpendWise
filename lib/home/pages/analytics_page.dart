import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/home/models/filter_state.dart';
import 'package:spendwise/home/models/transaction_item.dart';
import 'package:spendwise/home/utils/formatters.dart';
import 'package:spendwise/home/widgets/filter_row.dart';
import 'package:spendwise/providers.dart';

// ---------------------------------------------------------------------------
// Visualization palette (15 colors, cycled as needed)
// ---------------------------------------------------------------------------

const _vizPalette = <Color>[
  Color(0xFF4F7FD1), // 0 vivid cornflower
  Color(0xFFE47D5A), // 1 coral
  Color(0xFF43AA92), // 2 sea green
  Color(0xFF8D7CC4), // 3 lavender
  Color(0xFFF2A65A), // 4 amber peach
  Color(0xFF5E9CCE), // 5 airy blue
  Color(0xFF4FB07A), // 6 leafy green
  Color(0xFFB577C3), // 7 orchid
  Color(0xFFE8849A), // 8 rose
  Color(0xFF6C85D8), // 9 indigo blue
  Color(0xFF2F9EAF), // 10 deep turquoise
  Color(0xFFB56AA0), // 11 berry mauve
  Color(0xFF7CA7E8), // 12 sky blue
  Color(0xFF66B96E), // 13 spring green
  Color(0xFFA382D6), // 14 iris
];

const _categoryBarTrack = Color(0xFFE3EBFB);

Color _paletteAt(int index) => _vizPalette[index % _vizPalette.length];

Color _classTypeColor(String classType) {
  switch (classType) {
    case 'Necessity':
      return _paletteAt(0);
    case 'Desire':
      return _paletteAt(1);
    case 'Investment':
      return _paletteAt(2);
    default:
      return _paletteAt(3);
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(allFilteredStreamProvider);
    final filterState = ref.watch(filterStateProvider);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: FilterRow()),
        txnAsync.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Error: $e')),
          ),
          data: (txns) {
            if (txns.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              );
            }
            return SliverToBoxAdapter(
              child: _AnalyticsContent(txns: txns, filterState: filterState),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text('No transactions for this period',
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 6),
            Text('Try changing the filters above.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content — all 5 sections
// ---------------------------------------------------------------------------

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.txns, required this.filterState});

  final List<TransactionItem> txns;
  final FilterState filterState;

  @override
  Widget build(BuildContext context) {
    final expenses = txns.where((t) => !t.isIncome).toList();
    final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insights strip
          _InsightsCard(txns: txns, filterState: filterState),
          const SizedBox(height: 4),
          // Section 1 — Class type donut
          _ClassTypeSection(expenses: expenses, totalExpense: totalExpense),
          const SizedBox(height: 4),
          // Section 2 — Top categories
          _TopCategoriesSection(expenses: expenses, totalExpense: totalExpense),
          const SizedBox(height: 4),
          // Section 3 — Expense trend line chart
          _ExpenseTrendSection(txns: txns, filterState: filterState),
          const SizedBox(height: 4),
          // Section 4 — Payment method split
          _PaymentMethodSection(expenses: expenses, totalExpense: totalExpense),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section card wrapper
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.question,
    required this.icon,
    required this.child,
  });

  final String question;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    question.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1 — Spending by class type (donut chart)
// ---------------------------------------------------------------------------

class _ClassTypeSection extends StatelessWidget {
  const _ClassTypeSection(
      {required this.expenses, required this.totalExpense});

  final List<TransactionItem> expenses;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {
      'Necessity': 0, 'Desire': 0, 'Investment': 0, 'Others': 0
    };
    for (final t in expenses) {
      final ct = t.classType;
      if (totals.containsKey(ct)) totals[ct] = totals[ct]! + t.amount;
    }

    final hasData = totals.values.any((v) => v > 0);
    if (!hasData) {
      return const _SectionCard(
        question: 'Am I overspending on wants?',
        icon: Icons.balance_outlined,
        child: _NoExpenseData(),
      );
    }

    final slices = <({String label, double amount, Color color})>[
      (
        label: 'Necessity',
        amount: totals['Necessity']!,
        color: _classTypeColor('Necessity')
      ),
      (
        label: 'Desire',
        amount: totals['Desire']!,
        color: _classTypeColor('Desire')
      ),
      (
        label: 'Investment',
        amount: totals['Investment']!,
        color: _classTypeColor('Investment')
      ),
      (label: 'Others', amount: totals['Others']!, color: _classTypeColor('Others')),
    ].where((s) => s.amount > 0).toList();

    return _SectionCard(
      question: 'Am I overspending on wants?',
      icon: Icons.balance_outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: slices.map((s) {
                  final pct = totalExpense > 0 ? s.amount / totalExpense : 0.0;
                  return PieChartSectionData(
                    value: s.amount,
                    color: s.color,
                    radius: 32,
                    title: '${(pct * 100).round()}%',
                    titleStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    showTitle: pct >= 0.08,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slices.map((s) {
                final pct = totalExpense > 0
                    ? (s.amount / totalExpense * 100).round()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.label,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatCurrency(s.amount),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text('$pct%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
                                  )),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2 — Top 5 spending categories
// ---------------------------------------------------------------------------

class _TopCategoriesSection extends ConsumerWidget {
  const _TopCategoriesSection(
      {required this.expenses, required this.totalExpense});

  final List<TransactionItem> expenses;
  final double totalExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const _SectionCard(
        question: 'Where does my money go?',
        icon: Icons.pie_chart_outline,
        child: _NoExpenseData(),
      );
    }

    final Map<String, double> catTotals = {};
    for (final t in expenses) {
      catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
    }

    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    final icons = ref.watch(categoryIconsProvider);
    final theme = Theme.of(context);

    return _SectionCard(
      question: 'Where does my money go?',
      icon: Icons.pie_chart_outline,
      child: Column(
        children: top.asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          final fillColor = _paletteAt(4 + idx);
          final pct =
              totalExpense > 0 ? (e.value / totalExpense * 100).round() : 0;
          final icon = icons[e.key] ?? Icons.category;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(e.key,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          Text(formatCurrency(e.value),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 34,
                            child: Text(
                              '$pct%',
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalExpense > 0 ? e.value / totalExpense : 0,
                          minHeight: 5,
                          backgroundColor: _categoryBarTrack,
                          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3 — Expense trend line chart
// ---------------------------------------------------------------------------

class _ExpenseTrendSection extends StatelessWidget {
  const _ExpenseTrendSection(
      {required this.txns, required this.filterState});

  final List<TransactionItem> txns;
  final FilterState filterState;

  @override
  Widget build(BuildContext context) {
    final buckets = _buildBuckets(txns, filterState);
    final theme = Theme.of(context);
    final trendColor = _paletteAt(9);

    final maxExpense = buckets.map((b) => b.expense).reduce((a, b) => a > b ? a : b);

    if (maxExpense == 0) {
      return const _SectionCard(
        question: 'Are my spends rising?',
        icon: Icons.show_chart,
        child: _NoExpenseData(message: 'No expense data for this period.'),
      );
    }
    final axis = _axisForFiveLines(maxExpense);
    final interval = axis.interval;
    final maxY = axis.maxY;

    final spots = buckets.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
        .toList();

    return _SectionCard(
      question: 'Are my spends rising?',
      icon: Icons.show_chart,
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            extraLinesData: ExtraLinesData(
              extraLinesOnTop: false,
              horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
                HorizontalLine(
                  y: maxY,
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ],
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  interval: interval,
                  getTitlesWidget: (value, _) => Text(
                    _compactCurrency(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                    ),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= buckets.length) {
                      return const SizedBox.shrink();
                    }
                    // Only show first, last, and middle label to avoid crowding.
                    final n = buckets.length;
                    final show = idx == 0 || idx == n - 1 || idx == n ~/ 2;
                    if (!show) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        buckets[idx].label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                preventCurveOverShooting: true,
                color: trendColor,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                    radius: 3,
                    color: trendColor,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      trendColor.withValues(alpha: 0.33),
                      trendColor.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.white,
                tooltipBorder: BorderSide(color: Colors.grey.shade200),
                getTooltipItems: (spots) => spots.map((s) {
                  final idx = s.x.toInt();
                  final label = (idx >= 0 && idx < buckets.length)
                      ? buckets[idx].fullLabel
                      : '';
                  return LineTooltipItem(
                    '$label\n${formatCurrency(s.y)}',
                    TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<_Bucket> _buildBuckets(
      List<TransactionItem> txns, FilterState filter) {
    final useMonthly = _useMonthlyGranularity(filter);
    final now = DateTime.now();

    // Determine the true start and end of the filter window.
    DateTime rangeStart;
    DateTime rangeEnd;
    switch (filter.dateFilter) {
      case 'Today':
        rangeStart = DateTime(now.year, now.month, now.day);
        rangeEnd = now;
      case 'This Week':
        rangeStart = now.subtract(Duration(days: now.weekday - 1));
        rangeStart =
            DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
        rangeEnd = now;
      case 'This Month':
        rangeStart = DateTime(now.year, now.month, 1);
        rangeEnd = now;
      case 'This Year':
        rangeStart = DateTime(now.year, 1, 1);
        rangeEnd = now;
      case 'Custom Range':
        rangeStart =
            filter.customStartDate ?? now.subtract(const Duration(days: 364));
        rangeEnd = filter.customEndDate ?? now;
      default:
        final expenses = txns.where((t) => !t.isIncome).toList();
        if (expenses.isEmpty) {
          rangeStart = now.subtract(const Duration(days: 364));
          rangeEnd = now;
        } else {
          rangeStart = expenses
              .map((t) => t.dateTime)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          rangeEnd = expenses
              .map((t) => t.dateTime)
              .reduce((a, b) => a.isAfter(b) ? a : b);
        }
    }

    // Build exactly 12 evenly-spaced buckets from rangeStart to rangeEnd.
    final buckets = List<_Bucket>.generate(12, (i) {
      DateTime dt;
      if (useMonthly) {
        final totalMonths = (rangeEnd.year - rangeStart.year) * 12 +
            (rangeEnd.month - rangeStart.month);
        final monthOffset = (totalMonths * i / 11).round();
        dt = DateTime(rangeStart.year, rangeStart.month + monthOffset);
      } else {
        final totalDays = rangeEnd.difference(rangeStart).inDays;
        final dayOffset = (totalDays * i / 11).round();
        final d = rangeStart.add(Duration(days: dayOffset));
        dt = DateTime(d.year, d.month, d.day);
      }
      return _Bucket(
        key: useMonthly ? _monthKey(dt) : _dayKey(dt),
        label: useMonthly ? _monthLabel(dt) : _dayLabel(dt),
        fullLabel: useMonthly ? _monthFullLabel(dt) : _dayFullLabel(dt),
      );
    });

    final keyToIndex = {for (var i = 0; i < 12; i++) buckets[i].key: i};
    for (final t in txns) {
      if (t.isIncome) continue;
      final key = useMonthly ? _monthKey(t.dateTime) : _dayKey(t.dateTime);
      final idx = keyToIndex[key];
      if (idx == null) continue;
      final b = buckets[idx];
      buckets[idx] = _Bucket(
        key: b.key,
        label: b.label,
        fullLabel: b.fullLabel,
        expense: b.expense + t.amount,
      );
    }

    return buckets;
  }

  static bool _useMonthlyGranularity(FilterState filter) {
    final df = filter.dateFilter;
    if (df == 'All Time' || df == 'This Year') return true;
    if (df == 'Today' || df == 'This Week' || df == 'This Month') return false;
    if (df == 'Custom Range') {
      final start = filter.customStartDate;
      final end = filter.customEndDate;
      if (start != null && end != null) {
        return end.difference(start).inDays > 60;
      }
    }
    return false;
  }

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _monthLabel(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[d.month - 1];
  }

  static String _monthFullLabel(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  static String _dayLabel(DateTime d) => '${d.day}/${d.month}';

  static String _dayFullLabel(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _Bucket {
  const _Bucket({
    required this.key,
    required this.label,
    required this.fullLabel,
    this.expense = 0,
  });

  final String key;
  final String label;
  final String fullLabel;
  final double expense;
}

// ---------------------------------------------------------------------------
// Section 4 — Payment method split
// ---------------------------------------------------------------------------

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection(
      {required this.expenses, required this.totalExpense});

  final List<TransactionItem> expenses;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const _SectionCard(
        question: 'How am I paying for things?',
        icon: Icons.payments_outlined,
        child: _NoExpenseData(),
      );
    }

    final Map<String, double> totals = {};
    for (final t in expenses) {
      totals[t.paymentMethod] = (totals[t.paymentMethod] ?? 0) + t.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final theme = Theme.of(context);

    final maxAmount = sorted.first.value;
    final axis = _axisForFiveLines(maxAmount);
    final interval = axis.interval;
    final maxY = axis.maxY;

    return _SectionCard(
      question: 'How am I paying for things?',
      icon: Icons.payments_outlined,
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            extraLinesData: ExtraLinesData(
              extraLinesOnTop: false,
              horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
                HorizontalLine(
                  y: maxY,
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ],
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  interval: interval,
                  getTitlesWidget: (value, _) => Text(
                    _compactCurrency(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                    ),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, _) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sorted.length) {
                      return const SizedBox.shrink();
                    }
                    final pct = totalExpense > 0
                        ? (sorted[idx].value / totalExpense * 100).round()
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(sorted[idx].key,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                          Text('$pct%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 8,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: sorted.asMap().entries.map((e) {
              final color = _paletteAt(10 + e.key);
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value,
                    color: color,
                    width: 36,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                ],
              );
            }).toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.white,
                tooltipBorder: BorderSide(color: Colors.grey.shade200),
                getTooltipItem: (group, _, rod, i) => BarTooltipItem(
                  '${sorted[group.x].key}\n${formatCurrency(rod.toY)}',
                  TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _paletteAt(10 + group.x),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insights card — single rotating insight with headline + detail
// ---------------------------------------------------------------------------

class _Insight {
  const _Insight({required this.headline, required this.detail, required this.icon});
  final String headline;
  final String detail;
  final IconData icon;
}

List<_Insight> _buildInsights(
    List<TransactionItem> txns, FilterState filterState) {
  final insights = <_Insight>[];

  final expenses = txns.where((t) => !t.isIncome).toList();
  final incomes  = txns.where((t) =>  t.isIncome).toList();
  final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);
  final totalIncome  = incomes.fold(0.0,  (s, t) => s + t.amount);
  final days = _periodDays(filterState);

  // ── 1. Avg daily spend ───────────────────────────────────────────────────
  if (totalExpense > 0 && days > 0) {
    final avg = totalExpense / days;
    final detail = avg > 1000
        ? 'That\'s ${formatCurrency(avg * 30)} a month at this rate.'
        : avg > 500
            ? 'Moderate pace — ${formatCurrency(avg * 30)} projected monthly.'
            : 'You\'re keeping daily costs tight.';
    insights.add(_Insight(
      icon: Icons.speed_outlined,
      headline: '${formatCurrency(avg)} / day',
      detail: detail,
    ));
  }

  // ── 2. Top category ──────────────────────────────────────────────────────
  final Map<String, double> catTotals = {};
  for (final t in expenses) {
    catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
  }
  if (catTotals.isNotEmpty) {
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final pct = (top.value / totalExpense * 100).round();
    insights.add(_Insight(
      icon: Icons.category_outlined,
      headline: '${top.key} — $pct% of spend',
      detail: pct >= 40
          ? '${formatCurrency(top.value)} — your single biggest drain.'
          : '${formatCurrency(top.value)} spent here this period.',
    ));

    // ── 3. Second category ────────────────────────────────────────────────
    if (sorted.length >= 2 && pct < 50) {
      final second = sorted[1];
      final pct2 = (second.value / totalExpense * 100).round();
      insights.add(_Insight(
        icon: Icons.bar_chart_outlined,
        headline: '${second.key} — $pct2% of spend',
        detail: '${formatCurrency(second.value)} · second biggest after ${top.key}.',
      ));
    }
  }

  // ── 4. Savings rate ──────────────────────────────────────────────────────
  if (totalIncome > 0 && totalExpense > 0) {
    final saved = totalIncome - totalExpense;
    if (saved >= 0) {
      final pct = (saved / totalIncome * 100).round();
      insights.add(_Insight(
        icon: Icons.savings_outlined,
        headline: '$pct% of income saved',
        detail: pct >= 30
            ? '${formatCurrency(saved)} kept — excellent discipline.'
            : pct >= 10
                ? '${formatCurrency(saved)} saved. Aim for 20–30%.'
                : '${formatCurrency(saved)} saved. Try cutting one category.',
      ));
    } else {
      final overpct = ((-saved) / totalIncome * 100).round();
      insights.add(_Insight(
        icon: Icons.warning_amber_outlined,
        headline: 'Overspent by $overpct%',
        detail: '${formatCurrency(-saved)} more than earned this period.',
      ));
    }
  }

  // ── 5. Desire vs Necessity ───────────────────────────────────────────────
  final desireExp = expenses
      .where((t) => t.classType == 'Desire')
      .fold(0.0, (s, t) => s + t.amount);
  final necessityExp = expenses
      .where((t) => t.classType == 'Necessity')
      .fold(0.0, (s, t) => s + t.amount);
  if (totalExpense > 0 && (desireExp > 0 || necessityExp > 0)) {
    final desirePct = (desireExp / totalExpense * 100).round();
    final needPct   = (necessityExp / totalExpense * 100).round();
    insights.add(_Insight(
      icon: Icons.balance_outlined,
      headline: 'Wants $desirePct% · Needs $needPct%',
      detail: desirePct > 50
          ? 'Trimming wants by 20% frees up ${formatCurrency(desireExp * 0.2)}.'
          : needPct > 70
              ? 'Living lean — most spend is unavoidable.'
              : 'A healthy wants-vs-needs balance.',
    ));
  }

  // ── 6. Investment ratio ──────────────────────────────────────────────────
  final investExp = expenses
      .where((t) => t.classType == 'Investment')
      .fold(0.0, (s, t) => s + t.amount);
  if (totalExpense > 0) {
    final pct = (investExp / totalExpense * 100).round();
    insights.add(_Insight(
      icon: Icons.trending_up_outlined,
      headline: investExp == 0 ? 'No investments yet' : '$pct% invested',
      detail: investExp == 0
          ? 'Consider allocating some this period.'
          : pct < 10
              ? '${formatCurrency(investExp)} — aim for 20% of spend.'
              : '${formatCurrency(investExp)} invested — great habit.',
    ));
  }

  // ── 7. Weekend vs weekday ────────────────────────────────────────────────
  final weekendExp = expenses
      .where((t) => t.dateTime.weekday >= 6)
      .fold(0.0, (s, t) => s + t.amount);
  if (weekendExp > 0 && totalExpense - weekendExp > 0) {
    final pct = (weekendExp / totalExpense * 100).round();
    insights.add(_Insight(
      icon: Icons.weekend_outlined,
      headline: pct > 40 ? 'Heavy weekend spender' : 'Weekday-driven spend',
      detail: pct > 40
          ? '$pct% of spend happens on weekends.'
          : '${100 - pct}% of spend falls on weekdays.',
    ));
  }

  // ── 8. Most expensive day of week ───────────────────────────────────────
  if (expenses.length >= 5) {
    final Map<int, double> dayTotals = {};
    for (final t in expenses) {
      dayTotals[t.dateTime.weekday] =
          (dayTotals[t.dateTime.weekday] ?? 0) + t.amount;
    }
    final topDay =
        dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    insights.add(_Insight(
      icon: Icons.today_outlined,
      headline: '${dayNames[topDay.key]}s cost the most',
      detail: '${formatCurrency(topDay.value)} total across all ${dayNames[topDay.key]}s.',
    ));
  }

  // ── 9. Cash vs digital ──────────────────────────────────────────────────
  final cashCount = expenses.where((t) => t.paymentMethod == 'Cash').length;
  if (expenses.length >= 3 && cashCount > 0) {
    final cashPct = (cashCount / expenses.length * 100).round();
    insights.add(_Insight(
      icon: Icons.payments_outlined,
      headline: cashPct > 40 ? '$cashPct% cash transactions' : '${100 - cashPct}% digital',
      detail: cashPct > 40
          ? 'Cash is harder to track — consider going digital.'
          : 'Good visibility over your spending.',
    ));
  }

  // ── 10. Top payment method by amount ────────────────────────────────────
  if (expenses.isNotEmpty) {
    final Map<String, double> pmAmount = {};
    for (final t in expenses) {
      pmAmount[t.paymentMethod] = (pmAmount[t.paymentMethod] ?? 0) + t.amount;
    }
    final top = pmAmount.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = (top.value / totalExpense * 100).round();
    insights.add(_Insight(
      icon: Icons.credit_card_outlined,
      headline: '${top.key} — $pct% of spend',
      detail: '${formatCurrency(top.value)} paid via ${top.key} this period.',
    ));
  }

  // ── 11. Largest single expense ──────────────────────────────────────────
  if (expenses.isNotEmpty) {
    final largest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    final sharePct = totalExpense > 0
        ? (largest.amount / totalExpense * 100).round()
        : 0;
    insights.add(_Insight(
      icon: Icons.receipt_long_outlined,
      headline: '${formatCurrency(largest.amount)} on ${largest.category}',
      detail: 'Your largest single expense — $sharePct% of total spend.',
    ));
  }

  // ── 12. Transaction velocity ─────────────────────────────────────────────
  if (txns.isNotEmpty && days > 0) {
    final perDay = txns.length / days;
    insights.add(_Insight(
      icon: Icons.receipt_outlined,
      headline: '${txns.length} transaction${txns.length == 1 ? '' : 's'} recorded',
      detail: perDay >= 2
          ? '${perDay.toStringAsFixed(1)} per day over $days days.'
          : 'Across $days day${days == 1 ? '' : 's'} in this period.',
    ));
  }

  while (insights.length < 3) {
    insights.add(const _Insight(
      icon: Icons.lightbulb_outline,
      headline: 'Keep tracking',
      detail: 'More insights unlock as you add transactions.',
    ));
  }

  return insights;
}

int _periodDays(FilterState filter) {
  final now = DateTime.now();
  switch (filter.dateFilter) {
    case 'Today':      return 1;
    case 'This Week':  return 7;
    case 'This Month':
      return now.day.clamp(1, DateTime(now.year, now.month + 1, 0).day);
    case 'This Year':
      return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    case 'Custom Range':
      final s = filter.customStartDate;
      final e = filter.customEndDate;
      if (s != null && e != null) return e.difference(s).inDays + 1;
      return 30;
    default: return 30;
  }
}

class _InsightsCard extends StatefulWidget {
  const _InsightsCard({required this.txns, required this.filterState});

  final List<TransactionItem> txns;
  final FilterState filterState;

  @override
  State<_InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<_InsightsCard>
    with SingleTickerProviderStateMixin {
  late List<_Insight> _all;
  late int _current;
  Timer? _timer;
  late final AnimationController _progressCtrl;

  // +1 = going forward (slide left), -1 = going backward (slide right).
  int _direction = 1;
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _rebuild();
    _scheduleNext();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _firstBuild = false);
    });
  }

  @override
  void didUpdateWidget(_InsightsCard old) {
    super.didUpdateWidget(old);
    if (old.filterState != widget.filterState || old.txns != widget.txns) {
      setState(_rebuild);
      _scheduleNext();
    }
  }

  void _rebuild() {
    _all = _buildInsights(widget.txns, widget.filterState);
    _current = 0;
    _direction = 1;
  }

  void _scheduleNext() {
    _timer?.cancel();
    _progressCtrl.forward(from: 0);
    _timer = Timer(const Duration(seconds: 6), _advance);
  }

  void _goTo(int next, int dir) {
    if (!mounted) return;
    setState(() {
      _direction = dir;
      _current = next % _all.length;
    });
    _scheduleNext();
  }

  void _advance() => _goTo((_current + 1) % _all.length, 1);

  void _onSwipe(double velocityX) {
    if (velocityX < -200) {
      // Swipe left → next
      _goTo((_current + 1) % _all.length, 1);
    } else if (velocityX > 200) {
      // Swipe right → previous
      _goTo((_current - 1 + _all.length) % _all.length, -1);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final insight = _all[_current];

    const radius = 16.0;
    const borderWidth = 2.5;

    return Padding(
      // External spacing around the card (keeps internals unchanged).
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.95),
              theme.colorScheme.secondary.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.23),
              blurRadius: 22,
              spreadRadius: 1.5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(borderWidth),
        child: GestureDetector(
          onHorizontalDragEnd: (d) => _onSwipe(d.primaryVelocity ?? 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius - borderWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 14, color: primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 5),
                      Text(
                        'INSIGHT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (context, _) {
                          final progress = _progressCtrl.value.clamp(0.0, 1.0);
                          return Row(
                            children: List.generate(_all.length, (i) {
                              final active = i == _current;
                              final activeWidth = 5 + (14 - 5) * progress;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(left: 4),
                                width: active ? activeWidth : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active
                                      ? primary
                                      : primary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, anim) {
                          if (_firstBuild) {
                            return child;
                          }
                          final isOutgoing =
                              anim.status == AnimationStatus.reverse ||
                                  anim.status == AnimationStatus.dismissed;
                          final startOffset = _direction > 0
                              ? const Offset(0.12, 0)
                              : const Offset(-0.12, 0);
                          final endOffset = _direction > 0
                              ? const Offset(-0.12, 0)
                              : const Offset(0.12, 0);
                          final slideTween = Tween<Offset>(
                            begin: isOutgoing ? Offset.zero : startOffset,
                            end: isOutgoing ? endOffset : Offset.zero,
                          );
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: slideTween.animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: _InsightContent(
                            key: ValueKey(_current),
                            insight: insight,
                            primary: primary,
                            theme: theme,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightContent extends StatelessWidget {
  const _InsightContent({
    super.key,
    required this.insight,
    required this.primary,
    required this.theme,
  });

  final _Insight insight;
  final Color primary;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(insight.icon, size: 20, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.headline,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                insight.detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a separate 5-line axis for a chart:
/// 0, 1×interval, 2×interval, 3×interval, 4×interval.
/// The top line is kept close to the chart's local max value with slight headroom.
({double maxY, double interval}) _axisForFiveLines(double maxValue) {
  if (maxValue <= 0) {
    return (maxY: 4, interval: 1);
  }
  final targetTop = maxValue * 1.06;
  final interval = _ceilToPleasant(targetTop / 4);
  return (maxY: interval * 4, interval: interval);
}

/// Rounds [raw] to a "pleasant" interval while keeping it close to data,
/// so chart max doesn't jump too high (e.g. avoids unnecessary 800 caps).
double _ceilToPleasant(double raw) {
  if (raw <= 0) return 1;

  final exponent = (math.log(raw) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final normalized = raw / magnitude;

  const steps = <double>[
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    2.25,
    2.5,
    3.0,
    3.5,
    4.0,
    5.0,
    6.0,
    7.5,
    10.0,
  ];

  final step = steps.firstWhere(
    (s) => normalized <= s,
    orElse: () => 10.0,
  );
  return step * magnitude;
}

/// Compact currency label for axis ticks: ₹1.2L, ₹45K, ₹500 etc.
String _compactCurrency(double value) {
  if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000)   return '₹${(value / 1000).toStringAsFixed(1)}K';
  return '₹${value.toStringAsFixed(0)}';
}

// ---------------------------------------------------------------------------
// Shared "no expense data" placeholder
// ---------------------------------------------------------------------------

class _NoExpenseData extends StatelessWidget {
  const _NoExpenseData({this.message = 'No expense data for this period.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
