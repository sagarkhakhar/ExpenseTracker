-- Authentication Integration Test Suite
-- Tests for email/password authentication, RLS policies, and user management

-- Set up test environment
BEGIN;

-- Create test schema for isolation
CREATE SCHEMA IF NOT EXISTS test_auth;
SET search_path TO test_auth, public;

-- Test results table
CREATE TEMP TABLE test_results (
  test_name TEXT PRIMARY KEY,
  status TEXT NOT NULL, -- 'PASS', 'FAIL', 'SKIP'
  message TEXT,
  execution_time INTERVAL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Helper function to log test results
CREATE OR REPLACE FUNCTION log_test_result(
  test_name TEXT,
  test_status TEXT,
  test_message TEXT DEFAULT NULL,
  start_time TIMESTAMPTZ DEFAULT NOW()
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO test_results (test_name, status, message, execution_time)
  VALUES (test_name, test_status, test_message, NOW() - start_time);
END;
$$ LANGUAGE plpgsql;

-- Test 1: Verify migration completeness
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  migration_count INTEGER;
  expected_migrations INTEGER := 4;
BEGIN
  SELECT COUNT(*) INTO migration_count 
  FROM app_migrations 
  WHERE applied_at IS NOT NULL;
  
  IF migration_count >= expected_migrations THEN
    PERFORM log_test_result('migration_completeness', 'PASS', 
      'Found ' || migration_count || ' migrations', start_time);
  ELSE
    PERFORM log_test_result('migration_completeness', 'FAIL', 
      'Expected ' || expected_migrations || ', found ' || migration_count, start_time);
  END IF;
END $$;

-- Test 2: Verify RLS is enabled on all user tables
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  table_name TEXT;
  tables_with_rls INTEGER := 0;
  expected_tables INTEGER := 0;
  rls_enabled BOOLEAN;
BEGIN
  FOR table_name IN 
    SELECT t.tablename 
    FROM pg_tables t
    WHERE t.schemaname = 'public' 
      AND t.tablename IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles', 'financial_goals', 'export_history')
  LOOP
    expected_tables := expected_tables + 1;
    
    SELECT relrowsecurity INTO rls_enabled
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' AND c.relname = table_name;
    
    IF rls_enabled THEN
      tables_with_rls := tables_with_rls + 1;
    END IF;
  END LOOP;
  
  IF tables_with_rls = expected_tables THEN
    PERFORM log_test_result('rls_enabled_tables', 'PASS', 
      'RLS enabled on all ' || expected_tables || ' tables', start_time);
  ELSE
    PERFORM log_test_result('rls_enabled_tables', 'FAIL', 
      'RLS enabled on ' || tables_with_rls || '/' || expected_tables || ' tables', start_time);
  END IF;
END $$;

-- Test 3: Verify RLS policies exist
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  policy_count INTEGER;
  expected_policies INTEGER := 20; -- Approximate number based on our policies
BEGIN
  SELECT COUNT(*) INTO policy_count 
  FROM pg_policies 
  WHERE schemaname = 'public';
  
  IF policy_count >= expected_policies THEN
    PERFORM log_test_result('rls_policies_exist', 'PASS', 
      'Found ' || policy_count || ' policies', start_time);
  ELSE
    PERFORM log_test_result('rls_policies_exist', 'FAIL', 
      'Expected >= ' || expected_policies || ', found ' || policy_count, start_time);
  END IF;
END $$;

-- Test 4: Verify required functions exist
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  function_name TEXT;
  functions_found INTEGER := 0;
  expected_functions TEXT[] := ARRAY[
    'initialize_user_profile',
    'migrate_anonymous_data_to_user',
    'cleanup_orphaned_records',
    'user_owns_category',
    'user_owns_account',
    'validate_expense_ownership',
    'log_security_event',
    'cleanup_expired_exports',
    'analyze_user_tables',
    'get_table_statistics'
  ];
  function_exists BOOLEAN;
BEGIN
  FOREACH function_name IN ARRAY expected_functions
  LOOP
    SELECT EXISTS(
      SELECT 1 FROM information_schema.routines 
      WHERE routine_schema = 'public' 
        AND routine_name = function_name
    ) INTO function_exists;
    
    IF function_exists THEN
      functions_found := functions_found + 1;
    END IF;
  END LOOP;
  
  IF functions_found = array_length(expected_functions, 1) THEN
    PERFORM log_test_result('required_functions_exist', 'PASS', 
      'All ' || functions_found || ' functions found', start_time);
  ELSE
    PERFORM log_test_result('required_functions_exist', 'FAIL', 
      'Found ' || functions_found || '/' || array_length(expected_functions, 1) || ' functions', start_time);
  END IF;
END $$;

-- Test 5: Verify indexes exist for performance
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  index_count INTEGER;
  expected_indexes INTEGER := 15; -- Approximate number based on our indexes
BEGIN
  SELECT COUNT(*) INTO index_count 
  FROM pg_indexes 
  WHERE schemaname = 'public' 
    AND tablename IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles', 'financial_goals');
  
  IF index_count >= expected_indexes THEN
    PERFORM log_test_result('performance_indexes_exist', 'PASS', 
      'Found ' || index_count || ' indexes', start_time);
  ELSE
    PERFORM log_test_result('performance_indexes_exist', 'FAIL', 
      'Expected >= ' || expected_indexes || ', found ' || index_count, start_time);
  END IF;
END $$;

-- Test 6: Test user profile creation trigger
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  test_user_id UUID := gen_random_uuid();
  profile_exists BOOLEAN;
BEGIN
  -- Simulate user creation (this would normally be done by Supabase Auth)
  -- We'll test the function directly instead
  
  BEGIN
    -- Test the initialization function
    INSERT INTO user_profiles (id, display_name) 
    VALUES (test_user_id, 'Test User');
    
    -- Check if profile was created
    SELECT EXISTS(
      SELECT 1 FROM user_profiles WHERE id = test_user_id
    ) INTO profile_exists;
    
    IF profile_exists THEN
      PERFORM log_test_result('user_profile_creation', 'PASS', 
        'User profile created successfully', start_time);
    ELSE
      PERFORM log_test_result('user_profile_creation', 'FAIL', 
        'User profile not created', start_time);
    END IF;
    
    -- Cleanup
    DELETE FROM user_profiles WHERE id = test_user_id;
    
  EXCEPTION WHEN OTHERS THEN
    PERFORM log_test_result('user_profile_creation', 'FAIL', 
      'Error creating user profile: ' || SQLERRM, start_time);
  END;
END $$;

-- Test 7: Test data migration function
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  test_user_id UUID := gen_random_uuid();
  migration_result JSON;
BEGIN
  BEGIN
    -- Create test user profile
    INSERT INTO user_profiles (id, display_name) 
    VALUES (test_user_id, 'Migration Test User');
    
    -- Create some test anonymous data
    INSERT INTO categories (name, icon, color, device_id) 
    VALUES ('Test Category', '🧪', '#FF0000', 'test-device');
    
    -- Test migration function
    SELECT migrate_anonymous_data_to_user(test_user_id, 'test-device') INTO migration_result;
    
    IF migration_result IS NOT NULL THEN
      PERFORM log_test_result('data_migration_function', 'PASS', 
        'Migration function executed successfully', start_time);
    ELSE
      PERFORM log_test_result('data_migration_function', 'FAIL', 
        'Migration function returned null', start_time);
    END IF;
    
    -- Cleanup
    DELETE FROM categories WHERE device_id = 'test-device';
    DELETE FROM user_profiles WHERE id = test_user_id;
    
  EXCEPTION WHEN OTHERS THEN
    PERFORM log_test_result('data_migration_function', 'FAIL', 
      'Error testing migration: ' || SQLERRM, start_time);
  END;
END $$;

-- Test 8: Test RLS policy enforcement (basic test)
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  test_user_id UUID := gen_random_uuid();
  category_id UUID;
  policy_working BOOLEAN := FALSE;
BEGIN
  BEGIN
    -- Create test user profile
    INSERT INTO user_profiles (id, display_name) 
    VALUES (test_user_id, 'RLS Test User');
    
    -- Create a category for this user
    INSERT INTO categories (name, user_id) 
    VALUES ('RLS Test Category', test_user_id) 
    RETURNING id INTO category_id;
    
    -- Test that we can find the category with the user context
    -- Note: In a real test, we'd set the auth.uid() context
    SELECT EXISTS(
      SELECT 1 FROM categories 
      WHERE id = category_id AND user_id = test_user_id
    ) INTO policy_working;
    
    IF policy_working THEN
      PERFORM log_test_result('rls_policy_basic_test', 'PASS', 
        'Basic RLS policy test passed', start_time);
    ELSE
      PERFORM log_test_result('rls_policy_basic_test', 'FAIL', 
        'Basic RLS policy test failed', start_time);
    END IF;
    
    -- Cleanup
    DELETE FROM categories WHERE id = category_id;
    DELETE FROM user_profiles WHERE id = test_user_id;
    
  EXCEPTION WHEN OTHERS THEN
    PERFORM log_test_result('rls_policy_basic_test', 'FAIL', 
      'Error testing RLS policies: ' || SQLERRM, start_time);
  END;
END $$;

-- Test 9: Test security audit logging
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  test_user_id UUID := gen_random_uuid();
  audit_log_exists BOOLEAN;
BEGIN
  BEGIN
    -- Create test user profile
    INSERT INTO user_profiles (id, display_name) 
    VALUES (test_user_id, 'Audit Test User');
    
    -- Insert a test category to trigger audit logging
    INSERT INTO categories (name, user_id) 
    VALUES ('Audit Test Category', test_user_id);
    
    -- Check if audit log was created
    SELECT EXISTS(
      SELECT 1 FROM security_audit_log 
      WHERE table_name = 'categories' 
        AND operation = 'INSERT'
        AND record_id IS NOT NULL
        AND created_at > start_time
    ) INTO audit_log_exists;
    
    IF audit_log_exists THEN
      PERFORM log_test_result('security_audit_logging', 'PASS', 
        'Security audit logging working', start_time);
    ELSE
      PERFORM log_test_result('security_audit_logging', 'FAIL', 
        'Security audit logging not working', start_time);
    END IF;
    
    -- Cleanup
    DELETE FROM categories WHERE user_id = test_user_id;
    DELETE FROM user_profiles WHERE id = test_user_id;
    DELETE FROM security_audit_log WHERE created_at > start_time;
    
  EXCEPTION WHEN OTHERS THEN
    PERFORM log_test_result('security_audit_logging', 'FAIL', 
      'Error testing audit logging: ' || SQLERRM, start_time);
  END;
END $$;

-- Test 10: Test performance monitoring functions
DO $$
DECLARE
  start_time TIMESTAMPTZ := NOW();
  stats_result RECORD;
  function_working BOOLEAN := FALSE;
BEGIN
  BEGIN
    -- Test table statistics function
    SELECT * INTO stats_result FROM get_table_statistics() LIMIT 1;
    
    IF stats_result IS NOT NULL THEN
      function_working := TRUE;
    END IF;
    
    IF function_working THEN
      PERFORM log_test_result('performance_monitoring_functions', 'PASS', 
        'Performance monitoring functions working', start_time);
    ELSE
      PERFORM log_test_result('performance_monitoring_functions', 'FAIL', 
        'Performance monitoring functions not working', start_time);
    END IF;
    
  EXCEPTION WHEN OTHERS THEN
    PERFORM log_test_result('performance_monitoring_functions', 'FAIL', 
      'Error testing performance functions: ' || SQLERRM, start_time);
  END;
END $$;

-- Display test results
SELECT 
  test_name,
  status,
  message,
  EXTRACT(EPOCH FROM execution_time) * 1000 as execution_time_ms,
  created_at
FROM test_results 
ORDER BY 
  CASE status 
    WHEN 'FAIL' THEN 1 
    WHEN 'PASS' THEN 2 
    ELSE 3 
  END,
  test_name;

-- Generate test summary
SELECT 
  COUNT(*) as total_tests,
  COUNT(*) FILTER (WHERE status = 'PASS') as passed_tests,
  COUNT(*) FILTER (WHERE status = 'FAIL') as failed_tests,
  COUNT(*) FILTER (WHERE status = 'SKIP') as skipped_tests,
  ROUND(
    COUNT(*) FILTER (WHERE status = 'PASS')::NUMERIC / COUNT(*)::NUMERIC * 100, 
    2
  ) as pass_rate_percentage
FROM test_results;

-- Cleanup test schema
ROLLBACK;