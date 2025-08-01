// This file is the entry point of the Expense Tracker application.
// It initializes all dependencies, sets up the app configuration, and launches the UI.
// This demonstrates proper app initialization following Flutter best practices.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'shared/theme/app_theme.dart';
import 'features/expense/presentation/views/home_screen.dart';
import 'features/expense/data/models/expense_model.dart';
import 'features/expense/presentation/views/add_expense_screen.dart';
import 'features/expense/domain/entities/expense.dart';
import 'features/expense/data/datasources/expense_local_data_source_impl.dart';
import 'features/budget/data/models/budget_model.dart';
import 'features/expense/data/models/receipt_photo_model.dart';
import 'shared/widgets/platform_widgets.dart';
import 'l10n/app_localizations.dart';

/// Main function that initializes the app and all its dependencies.
/// This is called when the app starts and sets up everything needed for the app to run.
void main() async {
  // Ensure Flutter bindings are initialized (required for async operations)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local database storage
  // Hive is a lightweight, fast NoSQL database for Flutter
  await Hive.initFlutter();

  // Register Hive adapters for data serialization
  // These adapters tell Hive how to convert our objects to/from binary format
  // Use try-catch to handle cases where adapters are already registered
  try {
    Hive.registerAdapter(ExpenseModelAdapter()); // For expense data models
    Hive.registerAdapter(ExpenseTypeAdapter()); // For expense type enums
    Hive.registerAdapter(BudgetModelAdapter()); // For budget data models
    Hive.registerAdapter(
        ReceiptPhotoModelAdapter()); // For receipt photo data models
  } catch (e) {
    // Adapters already registered, continue
    debugPrint('Hive adapters already registered: $e');
  }

  // Launch the app wrapped in ProviderScope for Riverpod state management
  // Move heavy initialization to background thread
  runApp(const ProviderScope(child: ExpenseTrackerApp()));

  // Initialize data sources in background to avoid blocking main thread
  _initializeDataSourcesInBackground();
}

/// Initialize data sources in background thread to avoid blocking main thread
Future<void> _initializeDataSourcesInBackground() async {
  try {
    // Use compute to run heavy operations in isolate
    await Future.wait([
      _initializeCategories(),
      _initializeExpenses(),
    ]);
  } catch (e) {
    // Log error but don't crash the app
    debugPrint('Error initializing data sources: $e');
  }
}

/// Initialize categories in background
Future<void> _initializeCategories() async {
  try {
    final categoryDataSource = CategoryLocalDataSourceImpl();
    await categoryDataSource.init();
  } catch (e) {
    debugPrint('Error initializing categories: $e');
  }
}

/// Initialize expenses in background with reduced dummy data
Future<void> _initializeExpenses() async {
  try {
    final dummyDataSource = ExpenseLocalDataSourceImpl();
    await dummyDataSource.init();

    // Only seed minimal data to avoid performance issues
    await dummyDataSource.seedMinimalDummyDataIfEmpty();

    // Process recurring expenses in background
    await dummyDataSource.processRecurringExpenses();
  } catch (e) {
    debugPrint('Error initializing expenses: $e');
  }
}

/// The root widget of the Expense Tracker application.
/// This widget configures the app theme, navigation, and platform-specific settings.
class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Platform-specific app configuration
    // iOS uses CupertinoApp for native iOS look and feel
    if (PlatformWidgets.isIOS) {
      return CupertinoApp(
        title: AppLocalizations.of(context)?.appTitle ?? 'Expense Tracker',
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        routes: {'/add-expense': (context) => const AddExpenseScreen()},
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    } else {
      // Android and other platforms use MaterialApp for Material Design
      return MaterialApp(
        title: AppLocalizations.of(context)?.appTitle ?? 'Expense Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Automatically adapts to system theme
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        routes: {'/add-expense': (context) => const AddExpenseScreen()},
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }
  }
}
