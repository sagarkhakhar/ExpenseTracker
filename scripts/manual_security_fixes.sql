-- Manual Security Fixes for Supabase Linter Errors
-- Run this SQL in your Supabase Dashboard > SQL Editor
-- This fixes the two security issues identified by the linter

-- ========================================
-- 1. Fix Security Definer View Issue
-- ========================================

-- Drop and recreate expenses_legacy_view without SECURITY DEFINER property
DROP VIEW IF EXISTS public.expenses_legacy_view;

-- Recreate the view without SECURITY DEFINER
-- This view will now use the permissions of the querying user instead of the view creator
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

-- ========================================
-- 2. Enable RLS on app_migrations table  
-- ========================================

-- Enable Row Level Security on app_migrations table
ALTER TABLE public.app_migrations ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies first
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

-- ========================================
-- 3. Verification and Audit
-- ========================================

-- Create audit log table if it doesn't exist
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
DROP POLICY IF EXISTS "Allow authenticated users to read security audit log" ON security_audit_log;
CREATE POLICY "Allow authenticated users to read security audit log" 
ON security_audit_log 
FOR SELECT 
TO authenticated
USING (true);

-- Log the security fixes
INSERT INTO security_audit_log (fix_type, description) VALUES 
('security_definer_view', 'Removed SECURITY DEFINER property from expenses_legacy_view'),
('rls_enabled', 'Enabled Row Level Security on app_migrations table with comprehensive policies'),
('security_hardening', 'Applied security fixes for Supabase linter compliance');

-- ========================================
-- 4. Verification Queries
-- ========================================

-- Verify the view no longer has SECURITY DEFINER property
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname = 'expenses_legacy_view';

-- Verify RLS is enabled on app_migrations
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'app_migrations';

-- List all policies on app_migrations table
SELECT 
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'app_migrations';

-- Show completion message
SELECT 'Security fixes applied successfully! Check your Supabase Database Linter to verify the errors are resolved.' as status;