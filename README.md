# SpendWise

A cross-platform personal finance management application for iOS and Android that helps you track, analyze, and manage your spending with intelligent transaction tracking and automated features.

## Features

### Core Transaction Management
- **Manual transaction entry** with rich metadata (amount, date, time, category, payment mode, remarks, person)
- **Transaction search and filtering** by text, date range, amount range, category, and person
- **Transaction templates** for frequently used entries
- **Transaction tagging** for custom organization
- **Bulk import/export** with CSV and Excel support
- **Offline-first architecture** with local storage only

### Android-Exclusive Feature
- **Intelligent SMS Auto-Recording**
  - Real-time SMS monitoring with background service
  - Pattern recognition for 100+ Indian banks and payment providers
  - Automatic category assignment and UPI ID extraction
  - Privacy-first: SMS processed locally, never sent to servers

### Reporting & Analytics
- **Reports** can be generated on-demand
- **Multi-dimensional filtering** by date range, category, person, and payment mode
- **Visual charts** including pie charts, bar graphs, and line charts
- **Income vs Expense breakdown**
- **Category-wise spending analysis**

### Categories & Customization
- **15+ pre-defined categories** including:
  - Food & Dining
  - Transportation
  - Shopping
  - Bills & Utilities
  - Entertainment
  - Health
  - Education
  - Investment
  - Personal Care
  - Travel
  - Gifts & Donations
  - And more

### Additional Features
- **Biometric authentication** (fingerprint/face recognition)
- **Banner ads and occasional interstitials**
- **Multi-language support**


## Supported Platforms

- **Android** 8.0 (API 26) and above with full SMS auto-recording capabilities
- **iOS** 13.0 and above with manual transaction entry and smart suggestions

## System Requirements

- **Android**: Minimum Android 8.0, Recommended Android 12.0 or later
- **iOS**: Minimum iOS 13.0, Recommended iOS 15.0 or later
- **Storage**: ~50 MB available space

## Installation

<!-- ### From App Store
- **iOS**: [Download on App Store](https://apps.apple.com/app/spendwise)
- **Android**: [Download on Google Play](https://play.google.com/store/apps/details?id=com.spendwise) -->

As this project is still under development, right now only manual installation is possible.

### Manual Installation (Development)
```bash
# Clone the repository
git clone https://github.com/yourusername/spendwise.git
cd spendwise

# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build for release
flutter build apk      # Android
flutter build ios      # iOS
```

## Quick Start

1. **Launch the app** and create your first account
2. **Add transactions** manually by tapping the action button
3. **Grant SMS permissions** (Android) to enable automatic transaction recording
4. **View your spending** in the reports section
5. **Organize with categories** and track your finances

## Technology Stack

- **Framework**: Flutter 3.19+ with Dart 3.3+
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Local Database**: Drift (SQLite)
- **Authentication**: Email and Google login
- **Charts & Visualization**: fl_chart
- **Platform-Specific**:
  - Android: Material Design 3, SMS parsing via telephony package
  - iOS: Cupertino widgets, native gestures

## Permissions
### Android
- `READ_SMS` - For automatic transaction recording
- `RECEIVE_SMS` - For SMS monitoring
- `READ_PHONE_STATE` - For context detection
- `INTERNET` - For authentication

## Privacy & Data

- All transaction data is stored locally on your device
- SMS is processed locally and never sent to external servers
- Your data is never shared without explicit consent
- No cloud backup in the free version


## Support

Report bugs on [GitHub Issues](https://github.com/ParthBiyani/spendwise/issues)

---

**SpendWise**  
*Manage your money with intelligence, track your spending with ease.*