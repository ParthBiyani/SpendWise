# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter analyze          # Static analysis / linting
flutter pub run build_runner build  # Regenerate Drift database code (app_database.g.dart)
flutter pub run build_runner watch  # Watch and regenerate on changes
```

> No tests are configured — the `test/` directory is empty.

## Architecture

**SpendWise** is a Flutter expense-tracking app targeting the Indian market (₹, Indian banks). It is an offline-first, single-screen app with modal navigation.

### Screen Structure

- **`lib/homepage.dart`** — The only real screen (~559 lines). Hosts the transaction list, filters, summary card, and all state logic in a single `StatefulWidget`. All filtering, grouping, and UI coordination lives here.
- **`lib/home/pages/transaction_form_page.dart`** — Add/Edit transaction form, opened as a modal sheet from HomePage.
- **`lib/app.dart`** — Minimal router stub; currently just routes to `HomePage`. Has a TODO for authentication.

### State Management

There is **no global state management** (no Riverpod, Provider, BLoC). All state lives in `_HomePageState`. The `FilterState` class (`lib/home/models/filter_state.dart`) is an immutable value object with `copyWith`, passed around manually.

### Data Layer

```
lib/data/
├── local/
│   ├── app_database.dart     # Drift (SQLite) schema, DAOs, and queries
│   └── app_database.g.dart   # Generated — do not edit manually
└── repositories/
    └── transactions_repository.dart  # Thin abstraction over the Drift DAO
```

**Drift** is used as the ORM over SQLite. The database is at schema v3 with migration logic in `app_database.dart`. The primary access method is `watchAllTransactions()`, which returns a reactive `Stream<List<Transaction>>`.

**`Transactions` table columns:** `id`, `remarks`, `category`, `class_type`, `amount`, `is_income`, `payment_method`, `reference_id`, `entry_by`, `date_time`

**Allowed values:**
- `category`: 17 fixed values (Income, Dining, Snacks, Shopping, Groceries, Travel, Bills, Health, Education, Investment, Personal Care, Entertainment, Gifts, EMIs, Transfers, Housing, Others)
- `class_type`: Necessity, Desire, Investment, Others
- `payment_method`: Cash, UPI, Card, Bank

### Key Dependencies

| Package | Purpose |
|---|---|
| `drift` | SQLite ORM (code-gen based) |
| `sqlite3_flutter_libs` | Native SQLite bindings |
| `flutter_sticky_header` | Sticky date-group headers in transaction list |
| `fluttertoast` | Toast messages for user feedback |
| `path_provider` | Locating the database file on device |

### Code Generation

Drift requires generated code. After modifying `app_database.dart`, always run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

The generated file `app_database.g.dart` must be committed alongside schema changes.
