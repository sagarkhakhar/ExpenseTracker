import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/config_validator.dart';
import '../config/config_provider.dart';
import '../initialization/legacy_data_initialization.dart';
import 'startup_state.dart';

/// Notifier for managing startup validation process
class StartupGuardNotifier extends AutoDisposeAsyncNotifier<StartupState> {
  @override
  FutureOr<StartupState> build() {
    return StartupState.idle();
  }

  /// Start the complete validation process
  Future<void> validateStartup() async {
    try {
      state = const AsyncValue.loading();
      
      // Step 1: Validate configuration
      await _validateConfiguration();
      
      // Step 2: Probe network connectivity
      await _probeNetworkConnectivity();
      
      // Step 3: Bootstrap database if needed
      await _bootstrapDatabase();
      
      // Step 4: Initialize legacy Hive data and demo data
      await _initializeLegacyData();
      
      // Step 5: Mark as healthy
      state = AsyncValue.data(StartupState.healthy());
      
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Retry the validation process
  Future<void> retry() async {
    await validateStartup();
  }

  /// Step 1: Validate environment configuration
  Future<void> _validateConfiguration() async {
    state = AsyncValue.data(StartupState.validatingConfig());
    
    final config = ref.read(environmentConfigProvider);
    
    // Quick validation first
    if (!ConfigValidator.isConfigQuickValid(config)) {
      throw StartupValidationException(
        'Configuration validation failed: Missing or invalid Supabase credentials',
      );
    }
    
    // Detailed validation
    final validation = ConfigValidator.validateConfig(config);
    
    if (!validation.isValid) {
      throw StartupValidationException(
        'Configuration validation failed: ${validation.errors.join(', ')}',
      );
    }
    
    // Store validation result
    final currentState = state.value!;
    state = AsyncValue.data(
      currentState.copyWith(
        configValidation: validation,
        message: 'Configuration validated successfully',
      ),
    );
  }

  /// Step 2: Probe network connectivity to Supabase
  Future<void> _probeNetworkConnectivity() async {
    state = AsyncValue.data(StartupState.probingAuth());
    
    final config = ref.read(environmentConfigProvider);
    final networkProbe = await ConfigValidator.probeNetworkConnectivity(config);
    
    final currentState = state.value!;
    state = AsyncValue.data(
      currentState.copyWith(
        networkProbe: networkProbe,
        message: networkProbe.isHealthy 
          ? 'Network connectivity verified' 
          : 'Network connectivity issues detected',
      ),
    );
    
    // Don't fail on network issues in offline-first mode
    // Just log the status for diagnostics
    if (!networkProbe.isHealthy) {
      debugPrint('Warning: Network connectivity issue - ${networkProbe.error}');
    }
  }

  /// Step 3: Bootstrap database schema via Edge Function
  Future<void> _bootstrapDatabase() async {
    state = AsyncValue.data(StartupState.bootstrapping());
    
    final config = ref.read(environmentConfigProvider);
    final networkProbe = state.value?.networkProbe;
    
    // Skip bootstrap if we can't reach Supabase
    if (networkProbe != null && !networkProbe.canReachSupabase) {
      final details = {
        'skipped': true,
        'reason': 'No network connectivity to Supabase',
        'offline_mode': true,
      };
      
      final currentState = state.value!;
      state = AsyncValue.data(
        currentState.copyWith(
          bootstrapDetails: details,
          message: 'Bootstrap skipped - operating in offline mode',
        ),
      );
      return;
    }
    
    try {
      // Initialize Supabase client for bootstrap call
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );
      
      // Call bootstrap Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'bootstrap',
        body: {'validate_only': false},
      );
      
      final bootstrapDetails = response.data as Map<String, dynamic>?;
      final isBootstrapOk = bootstrapDetails?['ok'] == true;
      
      if (!isBootstrapOk) {
        final errorDetails = bootstrapDetails?['details'] ?? 'Unknown error';
        throw StartupValidationException(
          'Database bootstrap failed: $errorDetails',
        );
      }
      
      final currentState = state.value!;
      state = AsyncValue.data(
        currentState.copyWith(
          bootstrapDetails: bootstrapDetails,
          message: 'Database schema initialized successfully',
        ),
      );
      
    } catch (e) {
      // In offline-first mode, we can still continue without bootstrap
      debugPrint('Bootstrap failed (continuing in offline mode): $e');
      
      final details = {
        'skipped': true,
        'reason': 'Bootstrap failed: $e',
        'offline_mode': true,
      };
      
      final currentState = state.value!;
      state = AsyncValue.data(
        currentState.copyWith(
          bootstrapDetails: details,
          message: 'Bootstrap failed - continuing in offline mode',
        ),
      );
    }
  }

  /// Step 4: Initialize legacy Hive data and demo data
  Future<void> _initializeLegacyData() async {
    state = AsyncValue.data(StartupState.bootstrapping().copyWith(
      message: 'Initializing local data and demo content...'
    ));
    
    try {
      final legacyService = ref.read(legacyDataInitializationServiceProvider);
      await legacyService.initializeLegacyData();
      
      final currentState = state.value!;
      state = AsyncValue.data(
        currentState.copyWith(
          message: 'Local data initialized successfully',
        ),
      );
    } catch (e) {
      // Don't fail the entire startup for demo data issues
      debugPrint('Warning: Legacy data initialization failed: $e');
      
      final currentState = state.value!;
      state = AsyncValue.data(
        currentState.copyWith(
          message: 'Local data initialization completed with warnings',
        ),
      );
    }
  }

  /// Get diagnostic information
  Map<String, dynamic> getDiagnostics() {
    final currentState = state.value;
    if (currentState == null) return {'status': 'not_initialized'};

    return {
      'status': currentState.status.toString(),
      'message': currentState.message,
      'is_healthy': currentState.isHealthy,
      'config_valid': currentState.configValidation?.isValid ?? false,
      'config_errors': currentState.configValidation?.errors ?? [],
      'config_warnings': currentState.configValidation?.warnings ?? [],
      'network_connected': currentState.networkProbe?.isConnected ?? false,
      'network_reachable': currentState.networkProbe?.canReachSupabase ?? false,
      'network_latency_ms': currentState.networkProbe?.latencyMs,
      'network_error': currentState.networkProbe?.error,
      'bootstrap_details': currentState.bootstrapDetails,
      'error': currentState.error,
    };
  }
}

/// Custom exception for startup validation failures
class StartupValidationException implements Exception {
  const StartupValidationException(this.message);
  
  final String message;
  
  @override
  String toString() => 'StartupValidationException: $message';
}

/// Provider for the startup guard
final startupGuardProvider = AsyncNotifierProvider.autoDispose<
    StartupGuardNotifier, StartupState>(
  () => StartupGuardNotifier(),
);

/// Convenience provider to check if startup is complete and healthy
final isStartupHealthyProvider = Provider.autoDispose<bool>((ref) {
  final startupState = ref.watch(startupGuardProvider);
  return startupState.when(
    data: (state) => state.isHealthy,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for startup diagnostics
final startupDiagnosticsProvider = Provider.autoDispose<Map<String, dynamic>>((ref) {
  final startupNotifier = ref.read(startupGuardProvider.notifier);
  return startupNotifier.getDiagnostics();
});