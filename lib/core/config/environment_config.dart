import 'package:equatable/equatable.dart';

/// Environment configuration for Supabase integration
/// Contains all configuration needed for offline-first sync
class EnvironmentConfig extends Equatable {
  const EnvironmentConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.isProduction = false,
    this.syncBatchSize = 100,
    this.syncTimeoutMs = 30000,
    this.maxRetryAttempts = 3,
    this.retryBackoffMs = 1000,
  });

  /// Supabase project URL (e.g., https://your-project.supabase.co)
  final String supabaseUrl;
  
  /// Supabase anonymous key (public key for client authentication)
  final String supabaseAnonKey;
  
  /// Whether running in production environment
  final bool isProduction;
  
  /// Number of records to sync in each batch
  final int syncBatchSize;
  
  /// Timeout for sync operations in milliseconds
  final int syncTimeoutMs;
  
  /// Maximum number of retry attempts for failed sync operations
  final int maxRetryAttempts;
  
  /// Base backoff time between retries in milliseconds
  final int retryBackoffMs;

  @override
  List<Object?> get props => [
        supabaseUrl,
        supabaseAnonKey,
        isProduction,
        syncBatchSize,
        syncTimeoutMs,
        maxRetryAttempts,
        retryBackoffMs,
      ];

  /// Create development configuration
  factory EnvironmentConfig.development({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) =>
      EnvironmentConfig(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
        isProduction: false,
        syncBatchSize: 50, // Smaller batches for development
        syncTimeoutMs: 15000, // Shorter timeout for development
      );

  /// Create production configuration
  factory EnvironmentConfig.production({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) =>
      EnvironmentConfig(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
        isProduction: true,
        syncBatchSize: 200, // Larger batches for production
        syncTimeoutMs: 60000, // Longer timeout for production
      );

  EnvironmentConfig copyWith({
    String? supabaseUrl,
    String? supabaseAnonKey,
    bool? isProduction,
    int? syncBatchSize,
    int? syncTimeoutMs,
    int? maxRetryAttempts,
    int? retryBackoffMs,
  }) {
    return EnvironmentConfig(
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
      isProduction: isProduction ?? this.isProduction,
      syncBatchSize: syncBatchSize ?? this.syncBatchSize,
      syncTimeoutMs: syncTimeoutMs ?? this.syncTimeoutMs,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      retryBackoffMs: retryBackoffMs ?? this.retryBackoffMs,
    );
  }

  @override
  String toString() => 'EnvironmentConfig('
      'supabaseUrl: ${supabaseUrl.replaceAll(RegExp(r'https?://'), '***')}, '
      'anonKey: ${supabaseAnonKey.substring(0, 8)}..., '
      'isProduction: $isProduction)';
}