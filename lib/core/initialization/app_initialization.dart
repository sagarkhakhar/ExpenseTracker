// Comprehensive app initialization with exceptional coding practices
// Sets up logging, performance monitoring, and error handling systems

import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';
import '../performance/performance_monitor.dart';
import '../errors/exceptions.dart';

/// Centralized app initialization class that sets up all exceptional systems
class AppInitialization {
  static bool _isInitialized = false;
  static final AppLogger _logger = AppLogger.instance;

  /// Initialize all app systems with exceptional coding practices
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.warning('App already initialized, skipping duplicate initialization');
      return;
    }

    try {
      _logger.info('Starting app initialization with exceptional systems');

      // Initialize logging system first
      await _initializeLogging();

      // Initialize performance monitoring
      await _initializePerformanceMonitoring();

      // Initialize error handling
      await _initializeErrorHandling();

      // Mark as initialized
      _isInitialized = true;

      _logger.info('App initialization completed successfully', context: {
        'systems': ['logging', 'performance', 'error_handling'],
        'environment': kDebugMode ? 'debug' : 'release',
      });

      // Business event for successful initialization
      _logger.event('app_initialized', properties: {
        'success': true,
        'environment': kDebugMode ? 'debug' : 'release',
        'systems_count': 3,
      });

    } catch (error, stackTrace) {
      final exception = AppException.create(
        message: 'Failed to initialize app systems',
        errorCode: 'APP_INITIALIZATION_FAILED',
        technicalDetails: error.toString(),
        stackTrace: stackTrace,
        severity: ErrorSeverity.critical,
      );

      _logger.exception(exception);
      
      // Business event for initialization failure
      _logger.event('app_initialization_failed', properties: {
        'success': false,
        'error': error.toString(),
      });

      rethrow;
    }
  }

  /// Initialize structured logging system
  static Future<void> _initializeLogging() async {
    try {
      _logger.initialize(
        logLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
        outputs: [
          ConsoleLogOutput(),
          if (kDebugMode) DeveloperLogOutput(),
          // Add file and remote outputs in the future
        ],
      );

      _logger.info('Logging system initialized', context: {
        'logLevel': kDebugMode ? 'debug' : 'info',
        'outputs': kDebugMode ? ['console', 'developer'] : ['console'],
      });

    } catch (error) {
      // Fallback to basic logging if structured logging fails
      debugPrint('Failed to initialize logging system: $error');
      rethrow;
    }
  }

  /// Initialize performance monitoring system
  static Future<void> _initializePerformanceMonitoring() async {
    try {
      PerformanceMonitor.instance.initialize();

      _logger.info('Performance monitoring initialized', context: {
        'features': ['operation_timing', 'memory_tracking', 'slow_operation_detection'],
        'environment': kDebugMode ? 'debug' : 'release',
      });

    } catch (error, stackTrace) {
      final exception = AppException.create(
        message: 'Failed to initialize performance monitoring',
        errorCode: 'PERFORMANCE_INIT_FAILED',
        technicalDetails: error.toString(),
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      _logger.exception(exception);
      // Don't rethrow as this is not critical
    }
  }

  /// Initialize error handling system
  static Future<void> _initializeErrorHandling() async {
    try {
      // Set up global error handlers
      if (kDebugMode) {
        // In debug mode, let errors bubble up for debugging
        _logger.info('Error handling: Debug mode - errors will bubble up');
      } else {
        // In release mode, catch and log unhandled errors
        FlutterError.onError = (FlutterErrorDetails details) {
          final exception = AppException.create(
            message: 'Unhandled Flutter error',
            errorCode: 'FLUTTER_ERROR',
            technicalDetails: details.toString(),
            stackTrace: details.stack,
            context: {
              'library': details.library,
              'context': details.context?.toString(),
            },
            severity: ErrorSeverity.high,
          );

          _logger.exception(exception);
        };

        _logger.info('Error handling: Release mode - global error handlers set');
      }

      _logger.info('Error handling system initialized', context: {
        'mode': kDebugMode ? 'debug' : 'release',
        'globalHandlers': !kDebugMode,
      });

    } catch (error, stackTrace) {
      final exception = AppException.create(
        message: 'Failed to initialize error handling',
        errorCode: 'ERROR_HANDLING_INIT_FAILED',
        technicalDetails: error.toString(),
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      _logger.exception(exception);
      // Don't rethrow as this is not critical
    }
  }

  /// Check if app is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Get initialization status with diagnostics
  static Map<String, dynamic> getInitializationStatus() {
    return {
      'isInitialized': _isInitialized,
      'logging': _logger.toString(),
      'performance': PerformanceMonitor.instance.toString(),
      'environment': kDebugMode ? 'debug' : 'release',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Generate system health report
  static Map<String, dynamic> generateHealthReport() {
    final performanceReport = PerformanceMonitor.instance.generateReport();
    
    return {
      'initialization': getInitializationStatus(),
      'performance': performanceReport.toJson(),
      'logging': {
        'isActive': true,
        'level': kDebugMode ? 'debug' : 'info',
      },
      'memory': {
        'rss_mb': performanceReport.memoryUsage.rss / (1024 * 1024),
        'heap_mb': performanceReport.memoryUsage.heap / (1024 * 1024),
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}