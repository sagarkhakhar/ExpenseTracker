import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment_config.dart';

/// Diagnostic utility to check Supabase configuration and connectivity
class SupabaseDiagnostic {
  static void printConfigInfo(EnvironmentConfig config) {
    debugPrint('🔧 Supabase Configuration Diagnostic:');
    debugPrint('   URL: ${config.supabaseUrl.replaceFirst(RegExp(r'https?://'), '***://')}');
    debugPrint('   Anon Key: ${config.supabaseAnonKey.substring(0, 10)}...');
    debugPrint('   Production: ${config.isProduction}');
    debugPrint('   URL Valid: ${config.supabaseUrl.startsWith('https://')}');
    debugPrint('   Key Valid: ${config.supabaseAnonKey.startsWith('eyJ')}');
  }
  
  static Future<bool> testConnection() async {
    try {
      debugPrint('🌐 Testing Supabase connection...');
      
      final client = Supabase.instance.client;
      debugPrint('   Client initialized: ${client != null}');
      debugPrint('   Auth Status: ${client.auth.currentUser?.id ?? 'Anonymous'}');
      
      // Simple connectivity test
      final response = await client
          .from('expenses')
          .select('count')
          .limit(1);
          
      debugPrint('✅ Supabase connection successful');
      debugPrint('   Response type: ${response.runtimeType}');
      return true;
    } catch (e) {
      debugPrint('❌ Supabase connection failed: $e');
      return false;
    }
  }
  
  static Future<void> testExpenseTableAccess() async {
    try {
      debugPrint('🏗️  Testing expenses table access...');
      
      final client = Supabase.instance.client;
      
      // Test table structure
      final response = await client
          .from('expenses')
          .select()
          .limit(1);
          
      debugPrint('✅ Expenses table accessible');
      debugPrint('   Records found: ${(response as List).length}');
      
      if (response.isNotEmpty) {
        debugPrint('   Sample record keys: ${response.first.keys.join(', ')}');
      }
    } catch (e) {
      debugPrint('❌ Expenses table access failed: $e');
      debugPrint('   This could indicate:');
      debugPrint('   - Table does not exist');
      debugPrint('   - Missing permissions');
      debugPrint('   - Invalid configuration');
    }
  }
}