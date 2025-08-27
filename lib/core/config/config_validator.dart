import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'environment_config.dart';

/// Validation result for environment configuration
class ConfigValidationResult {
  const ConfigValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() => 'ConfigValidationResult('
      'isValid: $isValid, '
      'errors: ${errors.length}, '
      'warnings: ${warnings.length})';
}

/// Network connectivity check result
class NetworkProbeResult {
  const NetworkProbeResult({
    required this.isConnected,
    required this.canReachSupabase,
    this.latencyMs,
    this.error,
  });

  final bool isConnected;
  final bool canReachSupabase;
  final int? latencyMs;
  final String? error;

  bool get isHealthy => isConnected && canReachSupabase;

  @override
  String toString() => 'NetworkProbeResult('
      'connected: $isConnected, '
      'reachable: $canReachSupabase, '
      'latency: ${latencyMs}ms)';
}

/// Validates environment configuration and network connectivity
class ConfigValidator {
  static const Duration _networkTimeout = Duration(seconds: 10);

  /// Validate environment configuration format and structure
  static ConfigValidationResult validateConfig(EnvironmentConfig config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate Supabase URL
    final urlValidation = _validateSupabaseUrl(config.supabaseUrl);
    if (urlValidation != null) {
      errors.add(urlValidation);
    }

    // Validate anonymous key
    final keyValidation = _validateAnonKey(config.supabaseAnonKey);
    if (keyValidation != null) {
      errors.add(keyValidation);
    }

    // Validate numeric parameters
    if (config.syncBatchSize <= 0 || config.syncBatchSize > 1000) {
      warnings.add('Sync batch size ${config.syncBatchSize} may be inefficient');
    }

    if (config.syncTimeoutMs < 5000 || config.syncTimeoutMs > 300000) {
      warnings.add('Sync timeout ${config.syncTimeoutMs}ms may be problematic');
    }

    if (config.maxRetryAttempts < 1 || config.maxRetryAttempts > 10) {
      warnings.add('Retry attempts ${config.maxRetryAttempts} may be excessive');
    }

    return ConfigValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Probe network connectivity and Supabase reachability
  static Future<NetworkProbeResult> probeNetworkConnectivity(
    EnvironmentConfig config,
  ) async {
    try {
      // Basic connectivity check
      final stopwatch = Stopwatch()..start();
      
      final client = HttpClient();
      client.connectionTimeout = _networkTimeout;
      
      final uri = Uri.parse('${config.supabaseUrl}/rest/v1/');
      final request = await client.getUrl(uri);
      request.headers.set('apikey', config.supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer ${config.supabaseAnonKey}');
      
      final response = await request.close().timeout(_networkTimeout);
      client.close();
      
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      // Check if we get expected Supabase response
      final canReachSupabase = response.statusCode == 200 || 
                              response.statusCode == 401 || // Auth required is OK
                              response.statusCode == 403;   // Forbidden is OK
      
      return NetworkProbeResult(
        isConnected: true,
        canReachSupabase: canReachSupabase,
        latencyMs: latency,
      );
    } on SocketException catch (e) {
      return NetworkProbeResult(
        isConnected: false,
        canReachSupabase: false,
        error: 'No internet connection: ${e.message}',
      );
    } on HttpException catch (e) {
      return NetworkProbeResult(
        isConnected: true,
        canReachSupabase: false,
        error: 'HTTP error: ${e.message}',
      );
    } catch (e) {
      return NetworkProbeResult(
        isConnected: false,
        canReachSupabase: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Validate Supabase URL format
  static String? _validateSupabaseUrl(String url) {
    if (url.isEmpty) {
      return 'Supabase URL is required';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return 'Invalid URL format';
    }

    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL must use http or https scheme';
    }

    if (uri.scheme == 'http') {
      return 'Production environments should use HTTPS';
    }

    if (!uri.host.contains('.supabase.co') && !uri.host.contains('localhost')) {
      return 'URL should be a Supabase domain or localhost for development';
    }

    return null;
  }

  /// Validate Supabase anonymous key format
  static String? _validateAnonKey(String key) {
    if (key.isEmpty) {
      return 'Supabase anonymous key is required';
    }

    // Supabase keys are JWT tokens, should be long base64-like strings
    if (key.length < 100) {
      return 'Anonymous key appears to be too short';
    }

    // Should not contain spaces
    if (key.contains(' ')) {
      return 'Anonymous key should not contain spaces';
    }

    // Should be alphanumeric with dots, underscores, and hyphens
    final keyPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!keyPattern.hasMatch(key)) {
      return 'Anonymous key contains invalid characters';
    }

    return null;
  }

  /// Quick validation for startup (no network calls)
  static bool isConfigQuickValid(EnvironmentConfig config) {
    return config.supabaseUrl.isNotEmpty &&
           config.supabaseAnonKey.isNotEmpty &&
           Uri.tryParse(config.supabaseUrl) != null;
  }
}