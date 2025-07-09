import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'shared/theme/app_theme.dart';
import 'features/expense/presentation/views/home_screen.dart';
import 'features/expense/data/models/expense_model.dart';
import 'features/expense/presentation/views/add_expense_screen.dart';
import 'features/expense/domain/entities/expense.dart';
import 'features/expense/data/datasources/expense_local_data_source_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(ExpenseCategoryAdapter());
  Hive.registerAdapter(ExpenseTypeAdapter());

  // Seed dummy data if empty
  final dummyDataSource = ExpenseLocalDataSourceImpl();
  await dummyDataSource.init();
  await dummyDataSource.seedDummyDataIfEmpty();

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {'/add-expense': (context) => const AddExpenseScreen()},
    );
  }
}
