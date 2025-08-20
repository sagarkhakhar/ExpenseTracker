// Advanced structured logging system for exceptional debugging and monitoring
// This demonstrates production-ready logging with multiple outputs and structured data

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../errors/exceptions.dart';

/// Centralized logging system with structured output and multiple channels
/// Supports different log levels, structured data, and production-ready features
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  /// Get logger instance
  static AppLogger get instance => _instance;

  /// Current log level filter
  LogLevel _logLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Log outputs (console, file, remote, etc.)
  final List<LogOutput> _outputs = [];

  /// Initialize logger with outputs
  void initialize({
    LogLevel logLevel = LogLevel.info,
    List<LogOutput>? outputs,
  }) {
    _logLevel = logLevel;
    
    if (outputs != null) {
      _outputs.clear();
      _outputs.addAll(outputs);
    } else {
      // Default outputs
      _outputs.addAll([
        ConsoleLogOutput(),
        if (kDebugMode) DeveloperLogOutput(),
      ]);
    }
    
    info('Logger initialized', context: {
      'logLevel': _logLevel.name,
      'outputs': _outputs.map((o) => o.runtimeType.toString()).toList(),
    });
  }

  /// Log debug information (development only)
  void debug(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? category,
  }) {
    _log(LogLevel.debug, message, context: context, stackTrace: stackTrace, category: category);
  }

  /// Log informational messages
  void info(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? category,
  }) {
    _log(LogLevel.info, message, context: context, stackTrace: stackTrace, category: category);
  }

  /// Log warning messages
  void warning(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? category,
  }) {
    _log(LogLevel.warning, message, context: context, stackTrace: stackTrace, category: category);
  }

  /// Log error messages
  void error(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? category,
    Object? error,
  }) {
    final enrichedContext = <String, dynamic>{
      ...?context,
      if (error != null) 'error': error.toString(),
    };
    
    _log(LogLevel.error, message, 
        context: enrichedContext, 
        stackTrace: stackTrace ?? StackTrace.current, 
        category: category);
  }

  /// Log critical/fatal errors
  void critical(
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? category,
    Object? error,
  }) {
    final enrichedContext = <String, dynamic>{
      ...?context,
      if (error != null) 'error': error.toString(),
    };
    
    _log(LogLevel.critical, message, 
        context: enrichedContext, 
        stackTrace: stackTrace ?? StackTrace.current, 
        category: category);
  }

  /// Log exceptions with rich context
  void exception(
    AppException exception, {
    String? additionalMessage,
    Map<String, dynamic>? additionalContext,
    String? category,
  }) {
    final message = additionalMessage != null 
        ? '$additionalMessage: ${exception.message}'
        : exception.message;
        
    final context = <String, dynamic>{
      'errorCode': exception.errorCode,
      'severity': exception.severity.name,
      'timestamp': exception.timestamp?.toIso8601String(),
      if (exception.technicalDetails != null) 'technicalDetails': exception.technicalDetails,
      if (exception.context != null) ...exception.context!,
      if (additionalContext != null) ...additionalContext,
    };

    final logLevel = _severityToLogLevel(exception.severity);
    _log(logLevel, message, context: context, stackTrace: exception.stackTrace, category: category);
  }

  /// Log business events for analytics
  void event(
    String eventName, {
    Map<String, dynamic>? properties,
    String? category,
  }) {
    info('Event: $eventName', context: {
      'eventType': 'business_event',
      'eventName': eventName,
      if (properties != null) 'properties': properties,
    }, category: category ?? 'Analytics');
  }

  /// Log performance metrics
  void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metrics,
    String? category,
  }) {
    info('Performance: $operation', context: {
      'eventType': 'performance',
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'duration_readable': duration.toString(),
      if (metrics != null) ...metrics,
    }, category: category ?? 'Performance');
  }

  /// Log user interactions for UX analysis
  void userAction(
    String action,
    String screen, {
    Map<String, dynamic>? details,
  }) {
    info('User Action: $action', context: {
      'eventType': 'user_interaction',
      'action': action,
      'screen': screen,
      if (details != null) ...details,
    }, category: 'UX');
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
    String? category,
  }) {
    // Filter based on log level
    if (level.index < _logLevel.index) {
      return;
    }

    final logEntry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      context: context,
      stackTrace: stackTrace,
      category: category,
    );

    // Send to all outputs
    for (final output in _outputs) {
      try {
        output.write(logEntry);
      } catch (e) {
        // Fallback logging if output fails
        developer.log(
          'Logger output failed: $e',
          name: 'AppLogger',
          level: 1000,
        );
      }
    }
  }

  /// Convert exception severity to log level
  LogLevel _severityToLogLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return LogLevel.info;
      case ErrorSeverity.medium:
        return LogLevel.warning;
      case ErrorSeverity.high:
        return LogLevel.error;
      case ErrorSeverity.critical:
        return LogLevel.critical;
    }
  }
}

/// Log levels in order of severity
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Structured log entry
class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;
  final String? category;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.context,
    this.stackTrace,
    this.category,
  });

  /// Convert to structured JSON for remote logging
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      if (context != null) 'context': context,
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }
}

/// Abstract base class for log outputs
abstract class LogOutput {
  void write(LogEntry entry);
}

/// Console output for development
class ConsoleLogOutput implements LogOutput {
  @override
  void write(LogEntry entry) {
    final emoji = _getLevelEmoji(entry.level);
    final timestamp = entry.timestamp.toIso8601String();
    final category = entry.category != null ? '[${entry.category}] ' : '';
    
    print('$emoji $timestamp $category${entry.message}');
    
    if (entry.context != null && entry.context!.isNotEmpty) {
      print('   Context: ${jsonEncode(entry.context)}');
    }
    
    if (entry.stackTrace != null) {
      print('   Stack: ${entry.stackTrace}');
    }
  }

  String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }
}

/// Developer tools output (Flutter Inspector)
class DeveloperLogOutput implements LogOutput {
  @override
  void write(LogEntry entry) {
    developer.log(
      entry.message,
      name: entry.category ?? 'App',
      level: _getLevelValue(entry.level),
      error: entry.context,
      stackTrace: entry.stackTrace,
    );
  }

  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }
}

/// File output for persistent logging (future enhancement)
class FileLogOutput implements LogOutput {
  final String filePath;
  
  FileLogOutput(this.filePath);
  
  @override
  void write(LogEntry entry) {
    // Implementation for file logging
    // This would write structured JSON to a file for persistence
  }
}

/// Remote logging output for production monitoring (future enhancement)
class RemoteLogOutput implements LogOutput {
  final String endpoint;
  
  RemoteLogOutput(this.endpoint);
  
  @override
  void write(LogEntry entry) {
    // Implementation for remote logging
    // This would send structured data to a logging service
  }
}

/// Extension methods for easy logging from anywhere
extension LoggerExtensions on Object {
  AppLogger get _logger => AppLogger.instance;

  void logDebug(String message, {Map<String, dynamic>? context}) {
    _logger.debug(message, context: context, category: runtimeType.toString());
  }

  void logInfo(String message, {Map<String, dynamic>? context}) {
    _logger.info(message, context: context, category: runtimeType.toString());
  }

  void logWarning(String message, {Map<String, dynamic>? context}) {
    _logger.warning(message, context: context, category: runtimeType.toString());
  }

  void logError(String message, {Object? error, Map<String, dynamic>? context}) {
    _logger.error(message, error: error, context: context, category: runtimeType.toString());
  }

  void logException(AppException exception) {
    _logger.exception(exception, category: runtimeType.toString());
  }
}