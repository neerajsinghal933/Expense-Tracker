# 💰 Pulse Money — Premium Offline Finance Tracker

A privacy-first, offline-first Android expense tracker with intelligent SMS parsing, automatic categorization, beautiful analytics, and zero tracking.

**Your financial data is yours alone. It never leaves your device.**

## ✨ Features

### Smart Transaction Detection
- **SMS Parser** — Automatically detects bank alerts from Indian banks (HDFC, SBI, ICICI, etc.)
- **Multiple Formats** — Handles debit, credit, refund, EMI, ATM, and failed transactions
- **Auto-Categorization** — Intelligent categorization based on merchant patterns
- **Learning System** — Improves accuracy over time with merchant rules

### Financial Insights
- **Dashboard** — Monthly spending summary and recent transactions
- **Analytics** — Category breakdown with beautiful pie charts and daily trends
- **Calendar View** — Browse transactions by date
- **Budget Management** — Set and track monthly budgets per category
- **Detailed Reports** — Export to Excel for deeper analysis

### Privacy & Security
- **100% Offline** — All data stays on your device. No cloud sync.
- **No Tracking** — No analytics, no ads, no user profiling
- **Open Permissions** — Only requests necessary permissions
- **Transparent** — Clear privacy policy explaining exactly how data is used

### User Experience
- **Beautiful Dark Theme** — Premium Material 3 design
- **Smooth Animations** — Polished interactions throughout
- **Responsive Layout** — Works great on all screen sizes
- **Multi-Currency** — Support for INR, USD, EUR, and more

## 🚀 Quick Start

### Prerequisites
- Flutter 3.0+
- Android SDK 21+ (5.0 Lollipop)
- Physical device or emulator with SMS support

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd "Pulse Money"

# Install dependencies
flutter pub get

# Generate database code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run -d <device-id>
```

### Development Build

```bash
flutter run                    # Debug mode
flutter run --profile         # Profile mode
flutter run --release         # Release mode
```

## 📦 Build for Release

See [PRODUCTION_RELEASE_GUIDE.md](./PRODUCTION_RELEASE_GUIDE.md) for complete instructions.

Quick commands:
```bash
bash scripts/production_build.sh              # Interactive setup
flutter build apk --release --split-per-abi   # Build APK
flutter build appbundle --release             # Build for Play Store
```

See [BUILD_COMMANDS.md](./BUILD_COMMANDS.md) for detailed reference.

## 🏗️ Architecture

```
lib/
  ├── core/              # App-wide configuration
  │   ├── app.dart       # App initialization
  │   ├── navigation/    # GoRouter setup
  │   ├── providers/     # Riverpod state management
  │   ├── security/      # Security architecture
  │   └── theme/         # Material 3 theme
  ├── data/              # Data layer
  │   ├── db/            # Drift database
  │   └── repositories/  # Data repositories
  ├── domain/            # Domain layer
  ├── services/          # Business logic
  ├── features/          # UI screens
  └── widgets/           # Shared UI components
```

- **State Management**: Riverpod (type-safe, reactive)
- **Database**: Drift (type-safe SQLite ORM)
- **Routing**: GoRouter (modern navigation)

## 🔒 Privacy & Security

### Data Privacy
- ✅ **Zero Cloud Storage** — All data stays locally
- ✅ **No Tracking** — No analytics or user profiling
- ✅ **No Third Parties** — No external data sharing
- ✅ **Offline First** — Works completely without internet

### Permission Transparency
- **READ_SMS** — Detects bank transaction alerts (processed locally)
- **RECEIVE_SMS** — Handles SMS in background
- **POST_NOTIFICATIONS** — For budget reminders

See in-app Privacy Policy and Data Usage screens for full details.

### Security Features
- ✅ ProGuard/R8 obfuscation in release builds
- ✅ Secure input validation
- ✅ No hardcoded credentials
- ✅ No sensitive data in logs

## 📊 Project Information

- **App Name**: Pulse Money
- **Package**: com.pulsemoney.finance
- **Minimum SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: 34 (Android 14)
- **Version**: 1.0.0

## 🧪 Testing

```bash
flutter test                          # Run unit tests
flutter test integration_test/        # Run integration tests
dart analyze                          # Static analysis
```

## 📝 Documentation

- [Production Release Guide](./PRODUCTION_RELEASE_GUIDE.md) — Google Play submission guide
- [Build Commands](./BUILD_COMMANDS.md) — Build reference
- [Security Architecture](./lib/core/security/security_architecture.dart) — Security implementation

## 🛠️ Dependencies

- **riverpod** — State management
- **go_router** — Navigation
- **drift** — Database ORM
- **fl_chart** — Analytics charts
- **permission_handler** — Permissions
- **excel** — Export functionality
- **google_fonts** — Typography

## 🐛 Troubleshooting

### Build Issues
```bash
flutter clean && rm -rf build pubspec.lock
flutter pub get
flutter build apk --debug
```

### SMS Not Working
- Check Android 21+ (minimum requirement)
- Grant SMS permission in Settings
- Use physical device for testing

### Export Fails
- Ensure sufficient storage space
- Verify transaction data exists
- Check permissions in Settings

## 📄 License

[Add license here]

## 🎉 Changelog

### Version 1.0.0 (May 26, 2026)
- 🎉 Initial release
- 📊 Complete feature set
- 🔒 Privacy-first architecture
- 🎨 Premium Material 3 UI

---

**Built with ❤️ for privacy-conscious users**

*Pulse Money — Your financial data is yours alone.*
