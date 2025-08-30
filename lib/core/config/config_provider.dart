import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'environment_config.dart';

/// Provider for environment configuration
/// Loads configuration from environment variables only (no defaults)
final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  const bypassStartup = String.fromEnvironment('BYPASS_STARTUP_VALIDATION', defaultValue: 'false');
  
  // If no environment variables are provided, return a config that will fail validation
  // This forces proper setup and prevents accidental use of hardcoded values
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    return EnvironmentConfig.development(
      supabaseUrl: supabaseUrl.isEmpty ? 'MISSING_SUPABASE_URL' : supabaseUrl,
      supabaseAnonKey: supabaseAnonKey.isEmpty ? 'MISSING_SUPABASE_ANON_KEY' : supabaseAnonKey,
    );
  }
  
  return EnvironmentConfig.development(
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
  );
});

/// Provider to check if startup validation should be bypassed
final bypassStartupValidationProvider = Provider<bool>((ref) {
  const bypassStartup = String.fromEnvironment('BYPASS_STARTUP_VALIDATION', defaultValue: 'false');
  return bypassStartup.toLowerCase() == 'true';
});

/// Provider for configuration validity check
final configValidityProvider = Provider<bool>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return !config.supabaseUrl.startsWith('MISSING_') &&
         !config.supabaseAnonKey.startsWith('MISSING_') &&
         config.supabaseUrl.isNotEmpty &&
         config.supabaseAnonKey.isNotEmpty &&
         config.supabaseUrl.startsWith('https://') &&
         config.supabaseAnonKey.startsWith('eyJ'); // JWT tokens start with eyJ
});