-- Migration: Migrate Existing Data to New Schema
-- Purpose: Populate foreign key relationships for existing expense data
-- Date: 2025-09-01
-- Run after: 0005_future_proof_schema.sql

-- 1. MIGRATE CATEGORY DATA
-- Run the migration function to populate category_id based on existing category strings
SELECT migrate_expense_categories();

-- 2. CREATE DEFAULT ACCOUNTS FOR EXISTING USERS
-- Create a default "Cash" account for each user who has expenses but no account
-- Use dynamic SQL to handle different account table schemas
DO $$
DECLARE 
    has_account_type BOOLEAN;
    has_is_default BOOLEAN;
    has_current_balance BOOLEAN;
    has_currency BOOLEAN;
    insert_sql TEXT;
BEGIN
    -- Check which columns exist in accounts table
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'account_type'
    ) INTO has_account_type;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'is_default'
    ) INTO has_is_default;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'current_balance'
    ) INTO has_current_balance;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'currency'
    ) INTO has_currency;
    
    -- Build INSERT statement based on available columns
    insert_sql := 'INSERT INTO accounts (user_id, name';
    
    IF has_account_type THEN
        insert_sql := insert_sql || ', account_type';
    END IF;
    
    IF has_is_default THEN
        insert_sql := insert_sql || ', is_default';
    END IF;
    
    IF has_current_balance THEN
        insert_sql := insert_sql || ', current_balance';
    END IF;
    
    insert_sql := insert_sql || ') SELECT DISTINCT user_id, ''Cash Account''';
    
    IF has_account_type THEN
        insert_sql := insert_sql || ', ''cash''';
    END IF;
    
    IF has_is_default THEN
        insert_sql := insert_sql || ', TRUE';
    END IF;
    
    IF has_current_balance THEN
        insert_sql := insert_sql || ', COALESCE((SELECT SUM(CASE WHEN type = ''income'' THEN amount::decimal WHEN type = ''expense'' THEN -amount::decimal ELSE 0 END) FROM expenses e2 WHERE e2.user_id = e.user_id), 0)';
    END IF;
    
    -- Use more specific existence check based on available constraint columns
    IF has_currency AND has_is_default THEN
        insert_sql := insert_sql || ' FROM expenses e WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE user_id = e.user_id AND currency = ''USD'' AND is_default = TRUE)';
    ELSIF has_is_default THEN
        insert_sql := insert_sql || ' FROM expenses e WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE user_id = e.user_id AND is_default = TRUE)';
    ELSE
        insert_sql := insert_sql || ' FROM expenses e WHERE e.user_id NOT IN (SELECT user_id FROM accounts WHERE user_id IS NOT NULL)';
    END IF;
    
    -- Execute the dynamic INSERT
    EXECUTE insert_sql;
    
    RAISE NOTICE 'Created default accounts with available columns: account_type=%, is_default=%, current_balance=%', has_account_type, has_is_default, has_current_balance;
END $$;

-- 3. UPDATE EXPENSES TO USE DEFAULT ACCOUNT
-- Populate account_id with user's default account (handle missing is_default column)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'is_default'
    ) THEN
        -- Use is_default column if it exists
        UPDATE expenses 
        SET account_id = (
            SELECT a.id 
            FROM accounts a 
            WHERE a.user_id = expenses.user_id 
            AND a.is_default = TRUE 
            LIMIT 1
        )
        WHERE account_id IS NULL;
    ELSE
        -- Fallback to first account for each user if no is_default column
        UPDATE expenses 
        SET account_id = (
            SELECT a.id 
            FROM accounts a 
            WHERE a.user_id = expenses.user_id 
            ORDER BY a.id 
            LIMIT 1
        )
        WHERE account_id IS NULL;
    END IF;
    
    RAISE NOTICE 'Updated expenses with account_id references';
END $$;

-- 4. CREATE DEFAULT DEVICE FOR EXISTING DATA
-- Since we don't have actual device info, create a placeholder device for audit trail
-- Use NOT EXISTS to avoid ON CONFLICT with deferrable constraints
INSERT INTO devices (user_id, device_identifier, device_name, platform)
SELECT DISTINCT 
    user_id,
    'legacy-import-' || user_id as device_identifier,
    'Legacy Import' as device_name,
    'unknown' as platform
FROM expenses 
WHERE NOT EXISTS (
    SELECT 1 FROM devices d 
    WHERE d.user_id = expenses.user_id 
    AND d.device_identifier = 'legacy-import-' || expenses.user_id
);

-- 5. UPDATE EXPENSES TO USE DEFAULT DEVICE
-- Populate device_id with user's legacy device (only if device_id column exists and is UUID type)
DO $$
BEGIN
    -- Check if device_id column exists and what type it is
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'device_id'
        AND data_type = 'uuid'
    ) THEN
        -- device_id is UUID type, can reference devices.id
        UPDATE expenses 
        SET device_id = (
            SELECT d.id::text 
            FROM devices d 
            WHERE d.user_id = expenses.user_id 
            AND d.device_identifier LIKE 'legacy-import-%'
            LIMIT 1
        )::uuid
        WHERE device_id IS NULL;
        
        RAISE NOTICE 'Updated expenses with UUID device_id references';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'device_id'
        AND data_type = 'text'
    ) THEN
        -- device_id is TEXT type, use device_identifier
        UPDATE expenses 
        SET device_id = (
            SELECT d.device_identifier 
            FROM devices d 
            WHERE d.user_id = expenses.user_id 
            AND d.device_identifier LIKE 'legacy-import-%'
            LIMIT 1
        )
        WHERE device_id IS NULL;
        
        RAISE NOTICE 'Updated expenses with TEXT device_id references';
    ELSE
        RAISE NOTICE 'Skipping device_id update - column not found or unsupported type';
    END IF;
END $$;

-- 6. VERIFY DATA INTEGRITY
-- Check that all expenses now have proper foreign key references

DO $$
DECLARE
    null_category_count INTEGER;
    null_account_count INTEGER;
    null_device_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_category_count FROM expenses WHERE category_id IS NULL;
    SELECT COUNT(*) INTO null_account_count FROM expenses WHERE account_id IS NULL;
    SELECT COUNT(*) INTO null_device_count FROM expenses WHERE device_id IS NULL;
    
    RAISE NOTICE 'Data migration verification:';
    RAISE NOTICE 'Expenses with NULL category_id: %', null_category_count;
    RAISE NOTICE 'Expenses with NULL account_id: %', null_account_count;
    RAISE NOTICE 'Expenses with NULL device_id: %', null_device_count;
    
    IF null_category_count > 0 OR null_account_count > 0 OR null_device_count > 0 THEN
        RAISE WARNING 'Some NULL values still exist. Manual intervention may be required.';
    ELSE
        RAISE NOTICE 'Data migration completed successfully - all foreign keys populated!';
    END IF;
END $$;

-- 7. UPDATE STATISTICS
-- Refresh PostgreSQL statistics for query optimization
ANALYZE expenses;
ANALYZE categories;
ANALYZE accounts;
ANALYZE devices;

-- 8. OPTIONAL: Add constraints after data migration (uncomment if desired)
-- These constraints ensure data integrity going forward
-- 
-- ALTER TABLE expenses ADD CONSTRAINT fk_expenses_category 
--   FOREIGN KEY (category_id) REFERENCES categories(id);
-- 
-- ALTER TABLE expenses ADD CONSTRAINT fk_expenses_account 
--   FOREIGN KEY (account_id) REFERENCES accounts(id);
-- 
-- ALTER TABLE expenses ADD CONSTRAINT fk_expenses_device 
--   FOREIGN KEY (device_id) REFERENCES devices(id);

-- 9. CREATE VIEW FOR BACKWARD COMPATIBILITY
-- This view maintains the old structure for any existing queries
-- Handle type mismatches and missing columns dynamically
DO $$
DECLARE
    view_sql TEXT;
    has_idx BOOLEAN;
    has_category_id BOOLEAN;
    has_account_id BOOLEAN;
    has_receipt_photo_id BOOLEAN;
    has_device_id BOOLEAN;
    has_version BOOLEAN;
    has_is_deleted BOOLEAN;
    has_last_editor BOOLEAN;
    has_type BOOLEAN;
    has_category_text BOOLEAN;
BEGIN
    -- Check which columns exist in expenses table
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'idx') INTO has_idx;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'category_id') INTO has_category_id;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'account_id') INTO has_account_id;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'receipt_photo_id') INTO has_receipt_photo_id;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'device_id') INTO has_device_id;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'version') INTO has_version;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'is_deleted') INTO has_is_deleted;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'last_editor') INTO has_last_editor;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'type') INTO has_type;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'category') INTO has_category_text;
    
    -- Build dynamic VIEW SQL
    view_sql := 'CREATE OR REPLACE VIEW expenses_legacy_view AS SELECT ';
    
    -- Add columns that exist
    IF has_idx THEN
        view_sql := view_sql || 'e.idx, ';
    END IF;
    
    view_sql := view_sql || 'e.id, e.title, e.amount, ';
    
    IF has_category_id THEN
        view_sql := view_sql || 'e.category_id, ';
    END IF;
    
    -- Add category name from join or direct column
    IF has_category_id THEN
        view_sql := view_sql || 'COALESCE(c.name, ';
        IF has_category_text THEN
            view_sql := view_sql || 'e.category';
        ELSE
            view_sql := view_sql || 'NULL';
        END IF;
        view_sql := view_sql || ') as category, ';
    ELSIF has_category_text THEN
        view_sql := view_sql || 'e.category, ';
    ELSE
        view_sql := view_sql || 'NULL as category, ';
    END IF;
    
    IF has_account_id THEN
        view_sql := view_sql || 'e.account_id, a.name as account_name, ';
    ELSE
        view_sql := view_sql || 'NULL as account_id, NULL as account_name, ';
    END IF;
    
    view_sql := view_sql || 'e.date, e.description, ';
    
    IF has_receipt_photo_id THEN
        view_sql := view_sql || 'e.receipt_photo_id, rp.storage_path as receipt_photo_path, ';
    ELSE
        view_sql := view_sql || 'NULL as receipt_photo_id, NULL as receipt_photo_path, ';
    END IF;
    
    view_sql := view_sql || 'e.created_at, e.updated_at, ';
    
    IF has_version THEN
        view_sql := view_sql || 'e.version, ';
    ELSE
        view_sql := view_sql || 'NULL as version, ';
    END IF;
    
    IF has_is_deleted THEN
        view_sql := view_sql || 'e.is_deleted, ';
    ELSE
        view_sql := view_sql || 'FALSE as is_deleted, ';
    END IF;
    
    IF has_device_id THEN
        view_sql := view_sql || 'e.device_id, COALESCE(d1.device_name, d2.device_name) as device_name, ';
    ELSE
        view_sql := view_sql || 'NULL as device_id, NULL as device_name, ';
    END IF;
    
    IF has_last_editor THEN
        view_sql := view_sql || 'e.last_editor, ';
    ELSE
        view_sql := view_sql || 'NULL as last_editor, ';
    END IF;
    
    IF has_type THEN
        view_sql := view_sql || 'e.type, ';
    ELSE
        view_sql := view_sql || '''expense'' as type, ';
    END IF;
    
    view_sql := view_sql || 'e.user_id FROM expenses e ';
    
    -- Add JOINs based on available foreign keys
    IF has_category_id THEN
        view_sql := view_sql || 'LEFT JOIN categories c ON e.category_id = c.id ';
    END IF;
    
    IF has_account_id THEN
        view_sql := view_sql || 'LEFT JOIN accounts a ON e.account_id = a.id ';
    END IF;
    
    IF has_receipt_photo_id THEN
        view_sql := view_sql || 'LEFT JOIN receipt_photos rp ON e.receipt_photo_id = rp.id ';
    END IF;
    
    -- Add device joins if device_id column exists
    IF has_device_id THEN
        view_sql := view_sql || 'LEFT JOIN devices d1 ON (CASE WHEN e.device_id ~ ''^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'' THEN e.device_id::uuid = d1.id ELSE FALSE END) ';
        view_sql := view_sql || 'LEFT JOIN devices d2 ON e.device_id = d2.device_identifier ';
    END IF;
    
    -- Execute the dynamic VIEW creation
    EXECUTE view_sql;
    
    RAISE NOTICE 'Created expenses_legacy_view with available columns: idx=%, category_id=%, account_id=%, device_id=%', has_idx, has_category_id, has_account_id, has_device_id;
END $$;

-- Grant access to the view
GRANT SELECT ON expenses_legacy_view TO authenticated;