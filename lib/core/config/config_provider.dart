import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'environment_config.dart';

/// Provider for environment configuration
/// In real app, this would load from environment variables or secure storage
final environmentConfigProvider = Provider<EnvironmentConfig>((ref) {
  // TODO: Replace with actual environment variables or secure configuration
  // For development/demo purposes only
  return EnvironmentConfig.development(
    supabaseUrl: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://your-project.supabase.co',
    ),
    supabaseAnonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'your-anon-key-here',
    ),
  );
});

/// Provider for configuration validity check
final configValidityProvider = Provider<bool>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return config.supabaseUrl != 'https://your-project.supabase.co' &&
         config.supabaseAnonKey != 'your-anon-key-here' &&
         config.supabaseUrl.isNotEmpty &&
         config.supabaseAnonKey.isNotEmpty;
});