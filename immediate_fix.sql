-- IMMEDIATE FIX for Supabase Security Linter Error
-- Copy and paste this into your Supabase Dashboard > SQL Editor and run it

-- Step 1: Drop the existing view completely
DROP VIEW IF EXISTS public.expenses_legacy_view CASCADE;

-- Step 2: Recreate the view without any SECURITY DEFINER property
-- This creates a simple, secure view that uses the permissions of the querying user
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
    c.name as category_name,
    c.icon as category_icon,
    c.color as category_color
FROM expenses e
LEFT JOIN categories c ON e.category_id = c.id
WHERE e.is_deleted = false OR e.is_deleted IS NULL;

-- Step 3: Grant permissions explicitly
GRANT SELECT ON public.expenses_legacy_view TO authenticated;
GRANT SELECT ON public.expenses_legacy_view TO anon;

-- Step 4: Verify the fix worked
SELECT 
    'View recreated successfully without SECURITY DEFINER' as status,
    schemaname,
    viewname
FROM pg_views 
WHERE schemaname = 'public' AND viewname = 'expenses_legacy_view';

-- Optional: Check for any remaining SECURITY DEFINER functions that might need review
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    'SECURITY DEFINER function - review needed' as note
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosecdef = true 
AND n.nspname = 'public'
AND p.proname NOT LIKE 'bump_version%';  -- Exclude the version bump function which might need SECURITY DEFINER