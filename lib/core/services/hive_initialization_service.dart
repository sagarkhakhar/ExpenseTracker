import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/entities/sync_metadata.dart';
import '../data/entities/mutation_queue_item.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/budget/data/models/budget_model.dart';
import '../../features/expense/data/models/receipt_photo_model.dart';
import '../../features/export/domain/entities/export_history.dart';
import '../../features/statistics/domain/entities/financial_goal.dart';
import '../../features/statistics/domain/entities/trend_analysis.dart';

/// Centralized Hive initialization service to prevent concurrent box opening
/// and reduce main thread blocking during app startup
class HiveInitializationService {
  static HiveInitializationService? _instance;
  static HiveInitializationService get instance {
    _instance ??= HiveInitializationService._();
    return _instance!;
  }
  
  HiveInitializationService._();
  
  /// Track initialization status
  bool _isInitialized = false;
  final Map<String, Box> _openBoxes = {};
  final Set<String> _initializingBoxes = {};
  
  /// Completer to ensure single initialization
  Completer<void>? _initCompleter;
  
  /// Initialize all Hive boxes in background thread-friendly way
  Future<void> initializeAllBoxes() async {
    if (_isInitialized) return;
    
    // Prevent concurrent initialization
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    
    _initCompleter = Completer<void>();
    
    try {
      debugPrint('🗄️ Starting centralized Hive initialization...');
      
      // Define all boxes to initialize with their types
      final boxesToInit = [
        {'name': 'expenses', 'type': ExpenseModel},
        {'name': 'categories', 'type': String},
        {'name': 'budgets', 'type': BudgetModel},
        {'name': 'receipt_photos', 'type': ReceiptPhotoModel},
        {'name': 'export_history', 'type': ExportHistory},
        {'name': 'financial_goals', 'type': FinancialGoal},
        {'name': 'trend_analysis', 'type': TrendAnalysis},
        {'name': 'sync_metadata', 'type': SyncMetadata},
        {'name': 'mutation_queue', 'type': MutationQueueItem},
        {'name': 'sync_expenses', 'type': null}, // Generic box
        {'name': 'sync_categories', 'type': null}, // Generic box
        {'name': 'sync_budgets', 'type': null}, // Generic box
        {'name': 'sync_accounts', 'type': null}, // Generic box
      ];
      
      // Initialize boxes in batches with UI-friendly delays
      const batchSize = 3;
      for (int i = 0; i < boxesToInit.length; i += batchSize) {
        final batch = boxesToInit.skip(i).take(batchSize);
        
        // Process batch concurrently but yield to UI thread
        await Future.wait(
          batch.map((boxInfo) => _initializeBox(boxInfo['name'] as String)),
        );
        
        // Yield to UI thread between batches
        if (i + batchSize < boxesToInit.length) {
          await Future.delayed(const Duration(milliseconds: 16));
        }
      }
      
      _isInitialized = true;
      _initCompleter!.complete();
      
      debugPrint('✅ Hive initialization completed successfully');
      
    } catch (error, stackTrace) {
      debugPrint('❌ Hive initialization failed: $error');
      _initCompleter!.completeError(error, stackTrace);
      rethrow;
    }
  }
  
  /// Initialize individual box with error handling
  Future<Box> _initializeBox(String boxName) async {
    // Return existing box if already open
    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]!;
    }
    
    // Wait if box is currently being initialized by another caller
    while (_initializingBoxes.contains(boxName)) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    // Check again after waiting
    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]!;
    }
    
    _initializingBoxes.add(boxName);
    
    try {
      debugPrint('📦 Opening Hive box: $boxName');
      final box = await Hive.openBox(boxName);
      _openBoxes[boxName] = box;
      return box;
      
    } catch (error) {
      debugPrint('❌ Failed to open box $boxName: $error');
      rethrow;
      
    } finally {
      _initializingBoxes.remove(boxName);
    }
  }
  
  /// Get an already opened box (must call initializeAllBoxes first)
  Box<T> getBox<T>(String boxName) {
    if (!_isInitialized) {
      throw StateError('Hive not initialized. Call initializeAllBoxes() first.');
    }
    
    final box = _openBoxes[boxName];
    if (box == null) {
      throw StateError('Box $boxName not found. Was it included in initialization?');
    }
    
    return box as Box<T>;
  }
  
  /// Get a typed box safely
  Box<T> getTypedBox<T>(String boxName) {
    return getBox<T>(boxName);
  }
  
  /// Check if initialization is complete
  bool get isInitialized => _isInitialized;
  
  /// Close all boxes (for cleanup)
  Future<void> closeAllBoxes() async {
    for (final box in _openBoxes.values) {
      await box.close();
    }
    _openBoxes.clear();
    _isInitialized = false;
    _initCompleter = null;
  }
}