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
import 'features/budget/data/models/budget_model.dart';
import 'features/budget/data/datasources/budget_local_data_source.dart';
import 'features/expense/data/models/receipt_photo_model.dart';
import 'features/expense/data/datasources/receipt_photo_local_data_source.dart';

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
  // Use a more robust registration approach to prevent conflicts
  _registerHiveAdapters();

  // Launch the app immediately with loading screen
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

/// Register Hive adapters with conflict prevention
void _registerHiveAdapters() {
  // Check if adapters are already registered before attempting to register
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ExpenseTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(BudgetModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ReceiptPhotoModelAdapter());
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
        home: const AppLoadingScreen(),
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
        home: const AppLoadingScreen(),
        debugShowCheckedModeBanner: false,
        routes: {'/add-expense': (context) => const AddExpenseScreen()},
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }
  }
}

/// Loading screen that handles app initialization
class AppLoadingScreen extends ConsumerStatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  ConsumerState<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends ConsumerState<AppLoadingScreen> {
  bool _isInitialized = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _status = 'Loading...');

      // Initialize categories on main thread (Hive requirement)
      await _initializeCategories();

      setState(() => _status = 'Ready!');
      // Minimal delay for stability
      await Future.delayed(const Duration(milliseconds: 25));

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      // Continue to app even if initialization fails
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _initializeCategories() async {
    try {
      final categoryDataSource = CategoryLocalDataSourceImpl();
      await categoryDataSource.init();

      // Initialize comprehensive dummy data for all features
      await _initializeComprehensiveDummyData();
    } catch (e) {
      debugPrint('Error initializing categories: $e');
    }
  }

  Future<void> _initializeComprehensiveDummyData() async {
    try {
      debugPrint('Initializing comprehensive dummy data...');

      // Clear existing data to ensure fresh seeding
      await _clearExistingData();

      // Initialize expense dummy data
      final expenseDataSource = ExpenseLocalDataSourceImpl();
      await expenseDataSource.init();

      // Initialize budget dummy data
      final budgetDataSource = BudgetLocalDataSourceImpl();
      await budgetDataSource.seedComprehensiveBudgetData();

      // Initialize photo dummy data
      final photoDataSource = ReceiptPhotoLocalDataSourceImpl();
      await photoDataSource.init();
      await photoDataSource.seedComprehensivePhotoData();

      debugPrint('Comprehensive dummy data initialization complete');

      // Verify data was loaded
      await _verifyDataLoaded();
    } catch (e) {
      debugPrint('Error initializing dummy data: $e');
    }
  }

  Future<void> _clearExistingData() async {
    try {
      debugPrint('Clearing existing data...');

      // Clear expense data
      if (Hive.isBoxOpen('expenses')) {
        await Hive.box('expenses').clear();
      }

      // Clear budget data
      if (Hive.isBoxOpen('budgets')) {
        await Hive.box('budgets').clear();
      }

      // Clear photo data
      if (Hive.isBoxOpen('receipt_photos')) {
        await Hive.box('receipt_photos').clear();
      }

      // Clear category data - handle type mismatch
      try {
        if (Hive.isBoxOpen('categories')) {
          await Hive.box('categories').clear();
        }
      } catch (e) {
        debugPrint('Categories box clear error (expected): $e');
        // Close and reopen categories box
        if (Hive.isBoxOpen('categories')) {
          await Hive.box('categories').close();
        }
      }

      debugPrint('Existing data cleared');
    } catch (e) {
      debugPrint('Error clearing existing data: $e');
    }
  }

  Future<void> _verifyDataLoaded() async {
    try {
      debugPrint('Verifying data was loaded...');

      // Check expense data
      if (Hive.isBoxOpen('expenses')) {
        final expenseCount = Hive.box('expenses').length;
        debugPrint('Expenses loaded: $expenseCount');
      }

      // Check budget data
      if (Hive.isBoxOpen('budgets')) {
        final budgetCount = Hive.box('budgets').length;
        debugPrint('Budgets loaded: $budgetCount');
      }

      // Check photo data
      if (Hive.isBoxOpen('receipt_photos')) {
        final photoCount = Hive.box('receipt_photos').length;
        debugPrint('Photos loaded: $photoCount');
      }

      // Check category data
      if (Hive.isBoxOpen('categories')) {
        final categoryCount = Hive.box('categories').length;
        debugPrint('Categories loaded: $categoryCount');
      }

      debugPrint('Data verification complete');
    } catch (e) {
      debugPrint('Error verifying data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return const HomeScreen();
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (PlatformWidgets.isIOS)
              const CupertinoActivityIndicator(radius: 20)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
