-- Test script for authentication flows
-- Run these queries to test email verification and password reset functionality

-- Test 1: Check email configuration
SELECT 
  'Email verification enabled' as test,
  CASE WHEN current_setting('app.settings.auth_email_enable_confirmations', true) = 'true' 
       THEN 'PASS' 
       ELSE 'FAIL' 
  END as status;

-- Test 2: Check RLS policies are enabled
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE WHEN rowsecurity THEN 'PASS' ELSE 'FAIL' END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles');

-- Test 3: Check user profiles table structure
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Test 4: Check if shared categories exist
SELECT 
  'Shared categories' as test,
  count(*) as count,
  CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM shared_categories 
WHERE NOT is_deleted;

-- Test 5: Check RLS policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles')
ORDER BY tablename, policyname;

-- Test 6: Check migration status
SELECT 
  version,
  name,
  applied_at,
  CASE WHEN applied_at IS NOT NULL THEN 'PASS' ELSE 'FAIL' END as status
FROM app_migrations 
ORDER BY version;

-- Test 7: Check functions exist
SELECT 
  routine_name,
  routine_type,
  CASE WHEN routine_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END as status
FROM information_schema.routines 
WHERE routine_schema = 'public'
  AND routine_name IN (
    'initialize_user_profile',
    'migrate_anonymous_data_to_user',
    'cleanup_orphaned_records',
    'user_owns_category',
    'user_owns_account',
    'validate_expense_ownership'
  )
ORDER BY routine_name;

-- Test 8: Check triggers exist
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  CASE WHEN trigger_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END as status
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
  AND event_object_table IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles')
ORDER BY event_object_table, trigger_name;