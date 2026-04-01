# SpendWise — Improvement Todo List

## Architecture & Separation of Concerns

- [x] Split `homepage.dart` (~560 lines) into smaller focused widgets — extract dialogs, filter logic, and balance calculation
- [x] Split `transaction_form_page.dart` (~565 lines) similarly
- [x] Remove direct `AppDatabase()` instantiation from `_HomePageState.initState()` — use dependency injection or a singleton
- [x] Extract the delete confirmation dialog from `homepage.dart` into its own widget file

## State Management

- [x] Introduce a state management solution (Riverpod or Provider) to replace manual `setState()` across the app
- [x] Memoize the running balance calculation — currently recomputed on every `build()` call
- [x] Replace the three-representation `transactionType` field in `FilterState` (null / empty list / length-2 list all mean "show all") with an enum
- [x] Remove the empty no-op `clear()` method from `FilterState`

## Data Layer

- [ ] Move filtering (date, category, payment method) into SQL `WHERE` clauses instead of filtering in Dart after loading all rows
- [ ] Add database indexes on `date_time`, `category`, and `payment_method` columns
- [ ] Implement pagination for the transaction list
- [ ] Fix the migration bug — `onUpgrade` only handles `from < 3`; add a proper guard structure so future schema versions (4, 5, …) have their own migration paths
- [ ] Unify category classification into a single source of truth (currently duplicated between `app_database.dart` migration SQL and `transaction_form_page.dart` Dart map)

## Constants & Code Duplication

- [ ] Create `lib/config/constants.dart` (or enums) as a single source of truth for: category names, payment methods, class types, category icons
- [ ] Remove duplicate category/payment method lists from `homepage.dart`, `transaction_form_page.dart`, `transaction_tile.dart`, and `category_payment_widgets.dart`
- [ ] Extract the repeated toast-display logic into a shared utility function (currently copy-pasted in `filter_row.dart`, `all_filters_bottom_sheet.dart`, and `transaction_form_page.dart`)

## Error Handling

- [ ] Handle `snapshot.hasError` in the `StreamBuilder` in `homepage.dart` — currently silently swallowed
- [ ] Add `try/catch` to `_deleteSelectedTransactions()` — currently clears selection state even if deletion fails
- [ ] Define custom exception types in the repository layer so callers don't receive raw Drift exceptions
- [ ] Actually call `_formKey.currentState?.validate()` in `TransactionFormPage._submit()` — the form key is created but never used

## Model Design

- [ ] Add `==` and `hashCode` overrides to `TransactionItem` — it is used as a map key in `homepage.dart` without them
- [ ] Make nullable columns in the Drift schema explicit with `.nullable()` (e.g., `referenceId`, `entryBy`)

## Performance

- [ ] Add `const` constructors to eligible widgets in `all_filters_bottom_sheet.dart`, `transaction_form_page.dart`, and `filter_row.dart`
- [ ] Fix the `FocusNode` listener in `TransactionFormPage` — calling `setState(() {})` on every focus change rebuilds the entire form
- [ ] Optimize category usage sorting — currently watches all transactions on every stream event just to rank categories by frequency; move to a SQL `GROUP BY` query or cache the result

## Accessibility

- [ ] Add `Semantics` labels to `TransactionTile` (transaction description, amount, selection state)
- [ ] Add `Semantics` labels to the summary card values
- [ ] Replace hardcoded `Colors.red.shade700` with `theme.colorScheme.error`
- [ ] Verify color contrast on all text-on-colored-background combinations (WCAG AA)

## Linting & Code Quality

- [ ] Enable lint rules in `analysis_options.yaml`: `avoid_print`, `prefer_single_quotes`, `prefer_const_constructors`, `prefer_const_declarations`, `unnecessary_lambdas`
- [ ] Replace raw hex color constants in `main.dart` with a dedicated theme/constants file

## Testing

- [ ] Set up unit tests for `TransactionsRepository`
- [ ] Set up unit tests for `FilterState` and filter logic in `homepage.dart`
- [ ] Set up widget tests for `TransactionTile` and `SummaryCard`
- [ ] Add `mockito` (or `mocktail`) to dev dependencies for mocking the database in tests
