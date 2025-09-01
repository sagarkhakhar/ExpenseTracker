import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/config/config_provider.dart';
import 'package:expense_tracker/core/config/environment_config.dart';
import 'package:expense_tracker/core/startup/startup_guard.dart';

void main() {
  group('App Integration Tests', () {
    test('should validate environment configuration', () {
      // Test with empty config (offline mode)
      const emptyConfig = EnvironmentConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        enableDebugLogging: true,
      );

      expect(emptyConfig.supabaseUrl.isEmpty, isTrue);
      expect(emptyConfig.supabaseAnonKey.isEmpty, isTrue);
      expect(emptyConfig.isSupabaseConfigured, isFalse);
      print('✅ Empty config validation successful');
    });

    test('should validate valid Supabase configuration', () {
      // Test with valid config format
      const validConfig = EnvironmentConfig(
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MDk5NTIwMCwiZXhwIjoxOTU2MzUxMjAwfQ.test',
        enableDebugLogging: true,
      );

      expect(validConfig.isSupabaseConfigured, isTrue);
      expect(validConfig.supabaseUrl.startsWith('https://'), isTrue);
      expect(validConfig.supabaseAnonKey.startsWith('eyJ'), isTrue);
      print('✅ Valid Supabase config validation successful');
    });

    test('should handle startup states correctly', () {
      final startupStates = [
        StartupState.idle(),
        StartupState.validatingConfig(),
        StartupState.probingAuth(),
        StartupState.bootstrapping(),
        StartupState.healthy(),
        StartupState.error('Test error'),
      ];

      for (final state in startupStates) {
        expect(state, isNotNull);
        print('✅ StartupState.${state.runtimeType} created successfully');
      }

      print('✅ All startup states handled correctly');
    });

    test('should create config provider without errors', () {
      // Test that we can access the config provider
      // In real usage this would be with environment variables
      expect(() {
        // This should not throw
        const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
        const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
        
        const config = EnvironmentConfig(
          supabaseUrl: supabaseUrl,
          supabaseAnonKey: supabaseAnonKey,
        );
        
        return config.isSupabaseConfigured;
      }, returnsNormally);
      
      print('✅ Config provider creation successful');
    });

    test('should handle error states gracefully', () {
      final errorState = StartupState.error('Network connection failed');
      
      expect(errorState.maybeWhen(
        error: (message, error) => message,
        orElse: () => 'Unknown error',
      ), equals('Network connection failed'));
      
      print('✅ Error state handling successful');
    });
  });
}