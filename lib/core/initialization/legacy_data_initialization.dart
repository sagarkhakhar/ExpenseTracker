import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/expense/data/datasources/expense_local_data_source_impl.dart';
import '../../features/budget/data/datasources/budget_local_data_source.dart';
import '../../features/expense/data/datasources/receipt_photo_local_data_source.dart';

/// Service for initializing legacy Hive data and demo data
class LegacyDataInitializationService {
  /// Initialize categories and seed comprehensive demo data
  Future<void> initializeLegacyData() async {
    try {
      debugPrint('Starting legacy data initialization...');

      // Initialize categories on main thread (Hive requirement)
      await _initializeCategories();

      debugPrint('Legacy data initialization complete');
    } catch (e) {
      debugPrint('Error during legacy data initialization: $e');
      // Don't rethrow - we want the app to continue even if demo data fails
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
}

/// Provider for legacy data initialization service
final legacyDataInitializationServiceProvider = Provider<LegacyDataInitializationService>((ref) {
  return LegacyDataInitializationService();
});

/// Provider for legacy data initialization status
final legacyDataInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.read(legacyDataInitializationServiceProvider);
  await service.initializeLegacyData();
});