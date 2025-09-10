-- Migration: Security Fixes Only
-- This migration addresses the specific security issues identified by Supabase linter
-- without running all previous migrations

-- 1. Fix Security Definer View Issue
-- Drop and recreate expenses_legacy_view without SECURITY DEFINER property

DO $$
BEGIN
    -- Check if the view exists and drop it
    IF EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name = 'expenses_legacy_view' 
        AND table_schema = 'public'
    ) THEN
        DROP VIEW public.expenses_legacy_view;
    END IF;
    
    -- Recreate the view without SECURITY DEFINER
    -- Note: This view will use the permissions of the querying user instead of the view creator
    CREATE OR REPLACE VIEW public.expenses_legacy_view AS
    SELECT 
        e.id,
        e.title,
        e.amount,
        e.date,
        e.description,
        e.receipt_photo_id,
        e.created_at,
        e.updated_at,
        c.name as category_name,
        c.icon as category_icon,
        c.color as category_color
    FROM expenses e
    LEFT JOIN categories c ON e.category_id = c.id
    WHERE e.is_deleted = false;
    
    -- Grant appropriate permissions to the view
    GRANT SELECT ON public.expenses_legacy_view TO authenticated;
    GRANT SELECT ON public.expenses_legacy_view TO anon;
    
END $$;

-- 2. Enable RLS on app_migrations table
-- This addresses the "RLS Disabled in Public" error

DO $$
BEGIN
    -- Enable RLS if not already enabled
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'app_migrations' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE public.app_migrations ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "Allow authenticated users to read app_migrations" ON public.app_migrations;
    DROP POLICY IF EXISTS "Allow service role full access to app_migrations" ON public.app_migrations;
    DROP POLICY IF EXISTS "Allow anonymous users to read app_migrations status" ON public.app_migrations;
    
    -- Create comprehensive RLS policies for app_migrations
    
    -- Policy 1: Authenticated users can view migration history (read-only)
    CREATE POLICY "Allow authenticated users to read app_migrations" 
    ON public.app_migrations 
    FOR SELECT 
    TO authenticated
    USING (true);
    
    -- Policy 2: Service role can manage migrations (for automated scripts and admin operations)
    CREATE POLICY "Allow service role full access to app_migrations" 
    ON public.app_migrations 
    FOR ALL 
    TO service_role
    USING (true);
    
    -- Policy 3: Anonymous users can view migration status (for health checks)
    CREATE POLICY "Allow anonymous users to read app_migrations status" 
    ON public.app_migrations 
    FOR SELECT 
    TO anon
    USING (true);
    
END $$;

-- 3. Additional Security Hardening
-- Review and fix any other SECURITY DEFINER functions that might be problematic

DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Find all SECURITY DEFINER functions and log them for review
    FOR func_record IN 
        SELECT 
            n.nspname as schema_name,
            p.proname as function_name,
            pg_get_function_identity_arguments(p.oid) as arguments
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.prosecdef = true -- SECURITY DEFINER functions
        AND n.nspname = 'public'
    LOOP
        -- Log the function for manual review (these might be intentional)
        RAISE NOTICE 'SECURITY DEFINER function found: %.%(%)', 
            func_record.schema_name, 
            func_record.function_name, 
            func_record.arguments;
    END LOOP;
END $$;

-- 4. Verify RLS is enabled on all sensitive tables
-- Ensure all tables that should have RLS actually have it enabled

DO $$
DECLARE
    table_record RECORD;
BEGIN
    -- Check all public tables for RLS status
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN ('expenses', 'categories', 'accounts', 'budgets', 'app_migrations')
    LOOP
        -- Verify RLS is enabled
        IF NOT EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = table_record.tablename
            AND rowsecurity = true
        ) THEN
            RAISE WARNING 'RLS is not enabled on table: %', table_record.tablename;
            -- Enable RLS on the table
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
        END IF;
    END LOOP;
END $$;

-- 5. Create audit log for this security fix
CREATE TABLE IF NOT EXISTS security_audit_log (
    id SERIAL PRIMARY KEY,
    fix_type TEXT NOT NULL,
    description TEXT NOT NULL,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    applied_by TEXT DEFAULT current_user
);

-- Enable RLS on audit log
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read audit log
CREATE POLICY "Allow authenticated users to read security audit log" 
ON security_audit_log 
FOR SELECT 
TO authenticated
USING (true);

-- Log this security fix
INSERT INTO security_audit_log (fix_type, description) VALUES 
('security_definer_view', 'Removed SECURITY DEFINER property from expenses_legacy_view'),
('rls_enabled', 'Enabled Row Level Security on app_migrations table with comprehensive policies'),
('security_hardening', 'Applied additional security measures and verification checks');

-- Record this migration
INSERT INTO app_migrations (version, name, checksum) VALUES 
(11, 'Security fixes for linter issues', 'v11-security-fixes-only')
ON CONFLICT (version) DO NOTHING;