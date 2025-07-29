// This file is the entry point of the Expense Tracker application.
// It initializes all dependencies, sets up the app configuration, and launches the UI.
// This demonstrates proper app initialization following Flutter best practices.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'shared/theme/app_theme.dart';
import 'features/expense/presentation/views/home_screen.dart';
import 'features/expense/data/models/expense_model.dart';
import 'features/expense/presentation/views/add_expense_screen.dart';
import 'features/expense/domain/entities/expense.dart';
import 'features/expense/data/datasources/expense_local_data_source_impl.dart';
import 'shared/widgets/platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  Hive.registerAdapter(ExpenseModelAdapter()); // For expense data models
  Hive.registerAdapter(ExpenseTypeAdapter()); // For expense type enums

  // Initialize the category data source and populate default categories
  // This ensures the app has basic categories available on first launch
  final categoryDataSource = CategoryLocalDataSourceImpl();
  await categoryDataSource.init();

  // Initialize the expense data source and seed with dummy data if empty
  // This provides sample data for new users to see how the app works
  final dummyDataSource = ExpenseLocalDataSourceImpl();
  await dummyDataSource.init();
  await dummyDataSource.seedDummyDataIfEmpty();

  // Process any recurring expenses that are due
  // This automatically creates new expense entries for recurring transactions
  await dummyDataSource.processRecurringExpenses();

  // Launch the app wrapped in ProviderScope for Riverpod state management
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
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
