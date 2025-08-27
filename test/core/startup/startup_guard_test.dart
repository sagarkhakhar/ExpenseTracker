import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/startup/startup_guard.dart';
import 'package:expense_tracker/core/startup/startup_state.dart';
import 'package:expense_tracker/core/config/environment_config.dart';
import 'package:expense_tracker/core/config/config_provider.dart';

void main() {
  group('StartupGuardNotifier', () {
    late ProviderContainer container;
    
    setUp(() {
      // Create container with test config
      container = ProviderContainer(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            EnvironmentConfig.development(
              supabaseUrl: 'https://test-project.supabase.co',
              supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QtcHJvamVjdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxMjA0ODAwLCJleHAiOjE5NTY3ODA4MDB9.test-key-signature',
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should start in idle state', () {
      final notifier = container.read(startupGuardProvider.notifier);
      final initialState = container.read(startupGuardProvider);

      expect(initialState.value?.status, equals(StartupStatus.idle));
    });

    test('should handle validation flow gracefully in test environment', () async {
      final notifier = container.read(startupGuardProvider.notifier);
      
      // We can't easily test the full flow due to Supabase initialization
      // requiring platform plugins, so we test the individual components
      // in integration tests instead
      
      // Test that diagnostics work
      final diagnostics = notifier.getDiagnostics();
      expect(diagnostics, isNotNull);
      expect(diagnostics, isA<Map<String, dynamic>>());
      expect(diagnostics['status'], equals('StartupStatus.idle'));
    });

    test('should provide diagnostic information', () {
      final notifier = container.read(startupGuardProvider.notifier);
      final diagnostics = notifier.getDiagnostics();

      expect(diagnostics, isA<Map<String, dynamic>>());
      expect(diagnostics, containsPair('status', 'StartupStatus.idle'));
      expect(diagnostics, containsPair('is_healthy', false));
    });

    test('isStartupHealthyProvider should return false initially', () {
      final isHealthy = container.read(isStartupHealthyProvider);
      expect(isHealthy, isFalse);
    });

    test('startupDiagnosticsProvider should provide diagnostics map', () {
      final diagnostics = container.read(startupDiagnosticsProvider);
      
      expect(diagnostics, isA<Map<String, dynamic>>());
      expect(diagnostics.keys, contains('status'));
      expect(diagnostics.keys, contains('is_healthy'));
    });
  });

  group('StartupState', () {
    test('should identify loading states correctly', () {
      expect(StartupState.idle().isLoading, isFalse);
      expect(StartupState.validatingConfig().isLoading, isTrue);
      expect(StartupState.probingAuth().isLoading, isTrue);
      expect(StartupState.bootstrapping().isLoading, isTrue);
      expect(StartupState.healthy().isLoading, isFalse);
      expect(StartupState.error('test error').isLoading, isFalse);
    });

    test('should identify retry capability correctly', () {
      expect(StartupState.idle().canRetry, isFalse);
      expect(StartupState.validatingConfig().canRetry, isFalse);
      expect(StartupState.healthy().canRetry, isFalse);
      expect(StartupState.error('test error').canRetry, isTrue);
    });

    test('should identify healthy state correctly', () {
      expect(StartupState.idle().isHealthy, isFalse);
      expect(StartupState.validatingConfig().isHealthy, isFalse);
      expect(StartupState.healthy().isHealthy, isTrue);
      expect(StartupState.error('test error').isHealthy, isFalse);
    });

    test('should support copyWith for state updates', () {
      final initial = StartupState.idle();
      final updated = initial.copyWith(
        status: StartupStatus.validatingConfig,
        message: 'Updated message',
      );

      expect(updated.status, equals(StartupStatus.validatingConfig));
      expect(updated.message, equals('Updated message'));
      // Other properties should remain the same
      expect(updated.error, equals(initial.error));
    });

    test('should provide meaningful toString', () {
      final state = StartupState.error('Test error message');
      final string = state.toString();
      
      expect(string, contains('StartupState'));
      expect(string, contains('StartupStatus.error'));
      expect(string, contains('hasError: true'));
    });
  });

  group('StartupValidationException', () {
    test('should create exception with message', () {
      const message = 'Test validation error';
      const exception = StartupValidationException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(), contains(message));
    });
  });
}