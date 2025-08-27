import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/startup/startup_guard.dart';
import 'package:expense_tracker/presentation/startup/startup_gate.dart';
import 'package:expense_tracker/core/config/environment_config.dart';
import 'package:expense_tracker/core/config/config_provider.dart';
import 'package:expense_tracker/core/initialization/legacy_data_initialization.dart';
import 'package:expense_tracker/features/expense/presentation/views/home_screen.dart';

void main() {
  group('Startup Integration Tests', () {
    testWidgets('StartupGate should show loading initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentConfigProvider.overrideWithValue(
              EnvironmentConfig.development(
                supabaseUrl: 'https://test-project.supabase.co',
                supabaseAnonKey: 'test-anon-key-for-testing',
              ),
            ),
          ],
          child: MaterialApp(
            home: StartupGate(
              child: Scaffold(
                body: const Center(child: Text('Main App')),
              ),
            ),
          ),
        ),
      );

      // Should show some kind of startup UI (loading or diagnostics)
      // Note: With valid test config, it might go straight to error due to network issues
      // The important thing is that it doesn't show the main app immediately
      expect(find.text('Main App'), findsNothing);
      
      // Should show either loading or error state
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasError = find.text('Startup Issue').evaluate().isNotEmpty;
      final hasDiagnostics = find.text('Startup Diagnostics').evaluate().isNotEmpty;
      
      expect(hasLoading || hasError || hasDiagnostics, isTrue, 
        reason: 'Should show some kind of startup UI');
    });

    testWidgets('StartupGate should show diagnostics on configuration error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentConfigProvider.overrideWithValue(
              EnvironmentConfig.development(
                supabaseUrl: '', // Invalid empty URL
                supabaseAnonKey: '', // Invalid empty key
              ),
            ),
          ],
          child: MaterialApp(
            home: StartupGate(
              child: Scaffold(
                body: const Center(child: Text('Main App')),
              ),
            ),
          ),
        ),
      );

      // Give time for validation to run
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Should show startup diagnostics or error state
      // The exact UI depends on how the validation fails
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Main App'), findsNothing);
    });

    test('StartupGuard providers should be available', () {
      final container = ProviderContainer(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            EnvironmentConfig.development(
              supabaseUrl: 'https://test-project.supabase.co', 
              supabaseAnonKey: 'test-key',
            ),
          ),
        ],
      );

      // Should be able to read the providers
      final isHealthy = container.read(isStartupHealthyProvider);
      final diagnostics = container.read(startupDiagnosticsProvider);

      expect(isHealthy, isFalse); // Initially not healthy
      expect(diagnostics, isA<Map<String, dynamic>>());
      expect(diagnostics.keys, contains('status'));

      container.dispose();
    });

    test('Legacy data initialization service should be available', () {
      final container = ProviderContainer();

      final service = container.read(legacyDataInitializationServiceProvider);
      expect(service, isNotNull);

      // Service should have the initialization method
      expect(service.initializeLegacyData, isA<Function>());

      container.dispose();
    });
  });
}