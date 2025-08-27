import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/config/environment_config.dart';
import 'package:expense_tracker/core/config/config_validator.dart';

void main() {
  group('ConfigValidator', () {
    group('validateConfig', () {
      test('should pass validation with valid configuration', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QtcHJvamVjdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxMjA0ODAwLCJleHAiOjE5NTY3ODA4MDB9.test-key-signature',
        );

        final result = ConfigValidator.validateConfig(config);

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should fail validation with empty URL', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: '',
          supabaseAnonKey: 'valid-key-' + 'a' * 100,
        );

        final result = ConfigValidator.validateConfig(config);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Supabase URL is required'));
      });

      test('should fail validation with invalid URL format', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: 'invalid-url',
          supabaseAnonKey: 'valid-key-' + 'a' * 100,
        );

        final result = ConfigValidator.validateConfig(config);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('URL must use http or https scheme'));
      });

      test('should fail validation with empty anonymous key', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: '',
        );

        final result = ConfigValidator.validateConfig(config);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Supabase anonymous key is required'));
      });

      test('should fail validation with short anonymous key', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'short-key',
        );

        final result = ConfigValidator.validateConfig(config);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Anonymous key appears to be too short'));
      });

      test('should warn about inefficient batch size', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'valid-key-' + 'a' * 100,
        ).copyWith(syncBatchSize: 2000);

        final result = ConfigValidator.validateConfig(config);

        expect(result.hasWarnings, isTrue);
        expect(result.warnings, 
               contains(contains('Sync batch size 2000 may be inefficient')));
      });
    });

    group('isConfigQuickValid', () {
      test('should return true for basic valid config', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: 'any-non-empty-key',
        );

        final result = ConfigValidator.isConfigQuickValid(config);

        expect(result, isTrue);
      });

      test('should return false for empty URL', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: '',
          supabaseAnonKey: 'any-non-empty-key',
        );

        final result = ConfigValidator.isConfigQuickValid(config);

        expect(result, isFalse);
      });

      test('should return false for empty key', () {
        final config = EnvironmentConfig.development(
          supabaseUrl: 'https://test-project.supabase.co',
          supabaseAnonKey: '',
        );

        final result = ConfigValidator.isConfigQuickValid(config);

        expect(result, isFalse);
      });
    });
  });

  group('EnvironmentConfig', () {
    test('should create development config with expected defaults', () {
      const url = 'https://test-project.supabase.co';
      const key = 'test-anon-key';

      final config = EnvironmentConfig.development(
        supabaseUrl: url,
        supabaseAnonKey: key,
      );

      expect(config.supabaseUrl, equals(url));
      expect(config.supabaseAnonKey, equals(key));
      expect(config.isProduction, isFalse);
      expect(config.syncBatchSize, equals(50));
      expect(config.syncTimeoutMs, equals(15000));
    });

    test('should create production config with expected defaults', () {
      const url = 'https://test-project.supabase.co';
      const key = 'test-anon-key';

      final config = EnvironmentConfig.production(
        supabaseUrl: url,
        supabaseAnonKey: key,
      );

      expect(config.supabaseUrl, equals(url));
      expect(config.supabaseAnonKey, equals(key));
      expect(config.isProduction, isTrue);
      expect(config.syncBatchSize, equals(200));
      expect(config.syncTimeoutMs, equals(60000));
    });

    test('should support copyWith for partial updates', () {
      final original = EnvironmentConfig.development(
        supabaseUrl: 'https://test-project.supabase.co',
        supabaseAnonKey: 'test-key',
      );

      final updated = original.copyWith(syncBatchSize: 75);

      expect(updated.supabaseUrl, equals(original.supabaseUrl));
      expect(updated.supabaseAnonKey, equals(original.supabaseAnonKey));
      expect(updated.syncBatchSize, equals(75));
      expect(updated.isProduction, equals(original.isProduction));
    });
  });
}