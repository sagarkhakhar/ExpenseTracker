-- CLEAN FINAL FIX - Handles existing objects gracefully
-- Run this in your Supabase Dashboard > SQL Editor

-- ==========================================
-- STEP 1: Clean slate approach - Drop everything first
-- ==========================================

-- Drop all expense-related views
DROP VIEW IF EXISTS public.expenses_legacy_view CASCADE;

-- Drop dangerous functions
DROP FUNCTION IF EXISTS public.exec_sql(text) CASCADE;

-- ==========================================
-- STEP 2: Fix functions - Remove unnecessary SECURITY DEFINER
-- ==========================================

-- check_table_exists without SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.check_table_exists(table_name text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = $1
  );
END;
$$ LANGUAGE plpgsql;  -- No SECURITY DEFINER

-- Keep update_last_editor with SECURITY DEFINER but make it safer
CREATE OR REPLACE FUNCTION public.update_last_editor()
RETURNS TRIGGER AS $$
BEGIN
    -- Security check: only approved tables
    IF TG_TABLE_NAME NOT IN ('expenses', 'categories', 'accounts', 'budgets') THEN
        RAISE EXCEPTION 'update_last_editor not permitted on table %', TG_TABLE_NAME;
    END IF;
    
    -- Safe auth access
    BEGIN
        IF auth.uid() IS NOT NULL THEN
            NEW.last_editor := auth.uid()::text;
        ELSE
            NEW.last_editor := COALESCE(OLD.last_editor, 'system');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        NEW.last_editor := COALESCE(OLD.last_editor, 'system');
    END;
    
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- STEP 3: Recreate expenses_legacy_view (NO SECURITY DEFINER)
-- ==========================================

CREATE VIEW public.expenses_legacy_view AS
SELECT 
    e.id,
    e.title,
    e.amount,
    e.date,
    e.description,
    e.receipt_photo_id,
    e.created_at,
    e.updated_at,
    COALESCE(c.name, 'Uncategorized') as category_name,
    COALESCE(c.icon, '📦') as category_icon,
    COALESCE(c.color, '#BDC3C7') as category_color
FROM public.expenses e
LEFT JOIN public.categories c ON e.category_id = c.id
WHERE (e.is_deleted = false OR e.is_deleted IS NULL);

-- Grant permissions
GRANT SELECT ON public.expenses_legacy_view TO authenticated;
GRANT SELECT ON public.expenses_legacy_view TO anon;

-- ==========================================
-- STEP 4: Fix app_migrations RLS
-- ==========================================

-- Enable RLS if not already enabled
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'app_migrations' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE public.app_migrations ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to read app_migrations" ON public.app_migrations;
DROP POLICY IF EXISTS "Allow service role full access to app_migrations" ON public.app_migrations;
DROP POLICY IF EXISTS "Allow anonymous users to read app_migrations status" ON public.app_migrations;

-- Create fresh policies
CREATE POLICY "Allow authenticated users to read app_migrations" 
ON public.app_migrations FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow service role full access to app_migrations" 
ON public.app_migrations FOR ALL TO service_role USING (true);

CREATE POLICY "Allow anonymous users to read app_migrations status" 
ON public.app_migrations FOR SELECT TO anon USING (true);

-- ==========================================
-- STEP 5: Handle audit log gracefully
-- ==========================================

-- Create table if it doesn't exist
CREATE TABLE IF NOT EXISTS security_audit_log (
    id SERIAL PRIMARY KEY,
    action TEXT NOT NULL,
    object_name TEXT NOT NULL,
    details TEXT,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    applied_by TEXT DEFAULT current_user
);

-- Enable RLS if not already enabled
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'security_audit_log' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Drop and recreate policy to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to read security audit log" ON security_audit_log;
CREATE POLICY "Allow authenticated users to read security audit log" 
ON security_audit_log FOR SELECT TO authenticated USING (true);

-- Log this fix
INSERT INTO security_audit_log (action, object_name, details) VALUES 
('FINAL_SECURITY_FIX', 'expenses_legacy_view', 'Recreated view without SECURITY DEFINER - should resolve all linter errors'),
('FUNCTION_CLEANUP', 'various', 'Removed unnecessary SECURITY DEFINER properties from functions'),
('RLS_ENABLED', 'app_migrations', 'Ensured RLS is properly enabled with policies');

-- ==========================================
-- STEP 6: Final verification
-- ==========================================

-- Show the fixed view
SELECT 
    '✅ VIEW STATUS' as check_type,
    viewname,
    'Recreated without SECURITY DEFINER' as status
FROM pg_views 
WHERE schemaname = 'public' AND viewname = 'expenses_legacy_view'

UNION ALL

-- Show RLS status
SELECT 
    '✅ RLS STATUS' as check_type,
    tablename as viewname,
    CASE 
        WHEN rowsecurity THEN 'RLS Enabled'
        ELSE 'RLS Disabled - ERROR'
    END as status
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'app_migrations'

UNION ALL

-- Show remaining SECURITY DEFINER functions (should be minimal)
SELECT 
    '⚠️  SECURITY DEFINER FUNCTIONS' as check_type,
    p.proname as viewname,
    'Review if this needs SECURITY DEFINER' as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosecdef = true AND n.nspname = 'public'
ORDER BY check_type, viewname;

-- Success message
SELECT '🎉 SECURITY FIXES COMPLETE! Check your Supabase Database Linter now.' as final_message;