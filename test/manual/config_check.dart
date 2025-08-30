import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/config/config_provider.dart';

/// Manual test to check current configuration
void main() {
  test('Check current Supabase configuration', () {
    final container = ProviderContainer();
    
    try {
      final config = container.read(environmentConfigProvider);
      final isValid = container.read(configValidityProvider);
      
      print('🔧 Current Configuration:');
      print('   URL: ${config.supabaseUrl}');
      print('   Key: ${config.supabaseAnonKey.substring(0, 10)}...');
      print('   Valid: $isValid');
      print('   Production: ${config.isProduction}');
      
      if (!isValid) {
        print('');
        print('❌ Configuration Issues:');
        if (config.supabaseUrl.startsWith('MISSING_')) {
          print('   - SUPABASE_URL environment variable not set');
        }
        if (config.supabaseAnonKey.startsWith('MISSING_')) {
          print('   - SUPABASE_ANON_KEY environment variable not set');
        }
        print('');
        print('💡 Solution:');
        print('   Set environment variables when running:');
        print('   flutter run --dart-define=SUPABASE_URL=your_supabase_url');
        print('   flutter run --dart-define=SUPABASE_ANON_KEY=your_anon_key');
      }
      
    } finally {
      container.dispose();
    }
  });
}