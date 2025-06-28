# Expense Tracker

A modern, intelligent Expense Tracker application built with Flutter using MVVM architecture and Clean Architecture principles. This production-grade app features robust state management with Riverpod, efficient local storage with Hive, and a beautiful Material Design 3 UI.

## 🚀 Features

- **Add & Track Expenses**: Easily add expenses and income with categories
- **Real-time Statistics**: View monthly summaries, category breakdowns, and balance tracking
- **Modern UI**: Beautiful Material Design 3 interface with light/dark theme support
- **Offline First**: All data stored locally using Hive database
- **Responsive Design**: Works seamlessly across mobile, tablet, and desktop
- **Clean Architecture**: Modular, testable, and maintainable codebase

## 🏗️ Architecture

This app follows **Clean Architecture** principles with **MVVM** pattern:

### Layers:

- **Domain Layer**: Business logic, entities, use cases, and repository interfaces
- **Data Layer**: Repository implementations, data sources, and models
- **Presentation Layer**: UI components, providers, and state management

### Key Technologies:

- **Flutter**: Cross-platform UI framework
- **Riverpod**: State management and dependency injection
- **Hive**: Fast, lightweight local database
- **Dartz**: Functional programming utilities
- **Equatable**: Value equality for entities

## 📱 Screenshots

_Screenshots will be added after first run_

## 🛠️ Setup & Installation

### Prerequisites

- Flutter SDK (3.2.3 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation Steps

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd expense_tracker
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code** (for Hive adapters and Riverpod providers)

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants and theme
│   ├── errors/            # Error handling and failures
│   └── utils/             # Utility functions
├── features/
│   └── expense/
│       ├── data/          # Data layer
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/        # Domain layer
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/  # Presentation layer
│           ├── providers/
│           ├── views/
│           └── widgets/
├── shared/
│   ├── theme/             # App theming
│   └── widgets/           # Shared UI components
└── main.dart              # App entry point
```

## 🎨 UI Components

- **Home Screen**: Overview of expenses with summary cards
- **Add Expense Screen**: Form to add new expenses/income
- **Stats Screen**: Detailed statistics and category breakdown
- **Expense List**: Scrollable list of all transactions
- **Summary Cards**: Visual representation of financial data

## 🔧 Configuration

### Environment Setup

The app is configured for production use with:

- Material Design 3 theming
- Responsive layouts
- Error handling and loading states
- Local data persistence

### Customization

- Colors and themes can be modified in `lib/core/constants/app_constants.dart`
- Add new expense categories in `lib/features/expense/domain/entities/expense.dart`

## 🧪 Testing

Run tests with:

```bash
flutter test
```

## 📦 Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod for excellent state management
- Hive for fast local storage
- Material Design team for the design system

---

**Built with ❤️ using Flutter**
