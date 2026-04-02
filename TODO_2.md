# SpendWise — Post-Refactor Cleanup Todo List

## Dead Code Removal

- [x] Delete `lib/home/widgets/transaction_list.dart` — never imported anywhere; superseded by `grouped_transaction_sliver.dart`; also contains a stale running-balance calculation that doesn't use repository-computed balances
- [x] Delete `lib/home/widgets/date_header.dart` — only used by the dead `transaction_list.dart`; the app uses `StickyDateHeaderDelegate` in `sticky_date_header.dart` instead

## Test Cleanup

- [x] Delete `test/widget_test.dart` — the unmodified Flutter template smoke test that references a non-existent `MyApp()` class; it fails on every `flutter test` run; proper widget tests already live in `test/widgets_test.dart`

## Constants & Code Duplication

- [x] Extract date-filter strings to `lib/config/constants.dart` — `['All Time', 'Today', 'This Week', 'This Month', 'This Year', 'Custom Range']` is declared independently in `filter_row.dart` and `all_filters_bottom_sheet.dart`, and `'All Time'` is used as a magic literal in `filter_state.dart` (default value) and `app_database.dart` (switch cases); add `const List<String> dateFilters` and `const String defaultDateFilter = 'All Time'` to `constants.dart` and update all four files

## Incomplete / Misleading UI

- [x] Remove the no-op "Add" pill from `lib/home/widgets/form/payment_method_selector.dart` — `onTap: () {}` does nothing; the button implies functionality (adding a custom payment method) that was never implemented; remove it until the feature is ready

## Minor Cleanup

- [x] Remove the commented-out `// const SizedBox(height: 4),` line at `lib/home/widgets/transaction_tile.dart:101` — leftover from a spacing refactor
