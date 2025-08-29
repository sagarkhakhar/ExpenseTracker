// This file is the entry point of the Expense Tracker application.
// It initializes all dependencies, sets up the app configuration, and launches the UI.
// This demonstrates proper app initialization following Flutter best practices.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'shared/theme/app_theme.dart';
import 'features/expense/presentation/views/home_screen.dart';
import 'presentation/startup/startup_gate.dart';
import 'features/expense/data/models/expense_model.dart';
import 'features/expense/presentation/views/add_expense_screen.dart';
import 'features/expense/domain/entities/expense.dart';
import 'features/budget/data/models/budget_model.dart';
import 'features/expense/data/models/receipt_photo_model.dart';
import 'features/export/domain/entities/export_history.dart';
import 'features/statistics/domain/entities/financial_goal.dart';
import 'features/statistics/domain/entities/trend_analysis.dart';
import 'core/data/entities/sync_metadata.dart';
import 'core/data/entities/mutation_queue_item.dart';
import 'core/services/hive_initialization_service.dart';

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
  _registerHiveAdapters();

  // Skip background Hive initialization to prevent main thread blocking
  // Let providers initialize lazily as needed
  // _initializeHiveBoxesInBackground().ignore();

  // Launch the app immediately with loading screen
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

/// Register Hive adapters with conflict prevention and performance optimization
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
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(ExportFormatAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(ExportStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(ExportHistoryAdapter());
  }
  // Add missing adapters for statistics feature
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(GoalStatusAdapter()); // typeId 10
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(FinancialGoalAdapter()); // typeId 11
  }
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(TrendDirectionAdapter());
  }
  if (!Hive.isAdapterRegistered(18)) {
    Hive.registerAdapter(TrendAnalysisAdapter());
  }
  // Register sync metadata adapters
  if (!Hive.isAdapterRegistered(100)) {
    Hive.registerAdapter(SyncMetadataAdapter());
  }
  if (!Hive.isAdapterRegistered(101)) {
    Hive.registerAdapter(MutationQueueItemAdapter());
  }
  if (!Hive.isAdapterRegistered(102)) {
    Hive.registerAdapter(MutationTypeAdapter());
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
        theme: AppTheme.getCupertinoTheme(Brightness.light),
        home: const StartupGate(child: HomeScreen()),
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
        home: const StartupGate(child: HomeScreen()),
        debugShowCheckedModeBanner: false,
        routes: {'/add-expense': (context) => const AddExpenseScreen()},
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }
  }
}

/// Initialize Hive boxes in background to prevent main thread blocking
Future<void> _initializeHiveBoxesInBackground() async {
  try {
    // Use compute to run in isolate if needed, or just delay to let UI render first
    await Future.delayed(const Duration(milliseconds: 100));
    await HiveInitializationService.instance.initializeAllBoxes();
  } catch (error) {
    debugPrint('Background Hive initialization failed: $error');
    // App can still work with lazy box initialization
  }
}
