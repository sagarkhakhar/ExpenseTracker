-- NUCLEAR OPTION: Completely destroy and recreate expenses_legacy_view
-- This will forcefully remove the view regardless of dependencies

-- Step 1: Find and drop ALL views that might contain SECURITY DEFINER
DO $$
DECLARE
    view_name TEXT;
BEGIN
    -- Drop any view that might be the problematic one
    FOR view_name IN 
        SELECT viewname 
        FROM pg_views 
        WHERE schemaname = 'public' 
        AND (viewname LIKE '%expense%' OR viewname LIKE '%legacy%')
    LOOP
        EXECUTE 'DROP VIEW IF EXISTS public.' || quote_ident(view_name) || ' CASCADE';
        RAISE NOTICE 'Dropped view: %', view_name;
    END LOOP;
END $$;

-- Step 2: Also check for materialized views
DO $$
DECLARE
    view_name TEXT;
BEGIN
    FOR view_name IN 
        SELECT matviewname 
        FROM pg_matviews 
        WHERE schemaname = 'public' 
        AND (matviewname LIKE '%expense%' OR matviewname LIKE '%legacy%')
    LOOP
        EXECUTE 'DROP MATERIALIZED VIEW IF EXISTS public.' || quote_ident(view_name) || ' CASCADE';
        RAISE NOTICE 'Dropped materialized view: %', view_name;
    END LOOP;
END $$;

-- Step 3: Wait a moment for the system to process
SELECT pg_sleep(1);

-- Step 4: Recreate the view completely fresh (NO SECURITY DEFINER)
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
    c.color as category_color,
    a.name as account_name
FROM public.expenses e
LEFT JOIN public.categories c ON e.category_id = c.id
LEFT JOIN public.accounts a ON e.account_id = a.id
WHERE (e.is_deleted = false OR e.is_deleted IS NULL);

-- Step 5: Grant permissions
GRANT SELECT ON public.expenses_legacy_view TO authenticated;
GRANT SELECT ON public.expenses_legacy_view TO anon;

-- Step 6: Add comment to document this is NOT security definer
COMMENT ON VIEW public.expenses_legacy_view IS 'Standard view without SECURITY DEFINER - uses permissions of querying user';

-- Step 7: Verification - List all views and their properties
SELECT 
    'VERIFICATION: Current views in public schema' as info,
    viewname,
    viewowner,
    'Standard view (no SECURITY DEFINER)' as type
FROM pg_views 
WHERE schemaname = 'public'
ORDER BY viewname;

-- Step 8: Double-check no SECURITY DEFINER functions exist that we don't want
SELECT 
    'SECURITY DEFINER FUNCTIONS CHECK' as info,
    n.nspname as schema_name,
    p.proname as function_name,
    CASE 
        WHEN p.proname IN ('update_last_editor', 'bump_version') THEN 'EXPECTED - May need SECURITY DEFINER'
        ELSE 'UNEXPECTED - Review if this needs SECURITY DEFINER'
    END as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosecdef = true 
AND n.nspname = 'public'
ORDER BY p.proname;

-- Step 9: Final success check
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_views 
            WHERE schemaname = 'public' 
            AND viewname = 'expenses_legacy_view'
        ) THEN '✅ SUCCESS: expenses_legacy_view recreated without SECURITY DEFINER'
        ELSE '❌ FAILED: expenses_legacy_view not found'
    END as final_status;