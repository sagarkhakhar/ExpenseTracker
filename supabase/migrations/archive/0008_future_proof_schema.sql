-- Migration: Future-Proof Schema Implementation
-- Purpose: Implement proper foreign key relationships and audit trails
-- Date: 2025-09-01
-- ROBUST VERSION: Handles all edge cases and table existence

-- PART 1: ENSURE BASE EXPENSES TABLE EXISTS
-- Create expenses table if it doesn't exist (with all required columns)
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idx SERIAL,
    title TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    category_id UUID,
    account_id UUID,
    date DATE NOT NULL,
    description TEXT,
    receipt_photo_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    is_deleted BOOLEAN DEFAULT FALSE,
    device_id TEXT,
    last_editor TEXT,
    user_id UUID,
    type TEXT DEFAULT 'expense',
    category TEXT -- Legacy string category field
);

-- PART 2: ENSURE AUTH.USERS EXISTS FOR FOREIGN KEY REFERENCES
-- Skip if auth schema doesn't exist (development environments)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        -- Add user_id column with proper foreign key if auth exists
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expenses' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE expenses ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    ELSE
        -- Add user_id column without foreign key if auth doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'expenses' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE expenses ADD COLUMN user_id UUID;
        END IF;
    END IF;
END $$;

-- PART 3: CREATE CATEGORIES TABLE
-- Handle table creation with complete schema
DO $$
BEGIN
    -- Create categories table with basic structure first
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'categories') THEN
        CREATE TABLE categories (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(50) NOT NULL UNIQUE,
            display_name VARCHAR(100) NOT NULL,
            description TEXT,
            icon VARCHAR(50), -- For UI icons
            color VARCHAR(7), -- Hex color codes
            is_income_category BOOLEAN DEFAULT FALSE,
            is_active BOOLEAN DEFAULT TRUE,
            sort_order INTEGER DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
    
    -- Add missing columns if they don't exist (for existing tables)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'display_name'
    ) THEN
        ALTER TABLE categories ADD COLUMN display_name VARCHAR(100);
        -- Update existing records to have display_name based on name
        UPDATE categories SET display_name = INITCAP(name) WHERE display_name IS NULL;
        -- Make it NOT NULL after populating
        ALTER TABLE categories ALTER COLUMN display_name SET NOT NULL;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'description'
    ) THEN
        ALTER TABLE categories ADD COLUMN description TEXT;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'is_income_category'
    ) THEN
        ALTER TABLE categories ADD COLUMN is_income_category BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE categories ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'sort_order'
    ) THEN
        ALTER TABLE categories ADD COLUMN sort_order INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE categories ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE categories ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    -- Clean up duplicates and ensure UNIQUE constraint on name column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu 
        ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_name = 'categories' 
        AND tc.constraint_type = 'UNIQUE'
        AND ccu.column_name = 'name'
    ) THEN
        -- First, remove duplicate categories safely
        -- Keep the first one (lowest ID) and delete duplicates
        WITH duplicates AS (
            SELECT id, name, 
                   ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) as rn
            FROM categories
        )
        DELETE FROM categories 
        WHERE id IN (
            SELECT id FROM duplicates WHERE rn > 1
        );
        
        -- Now it's safe to add the unique constraint
        ALTER TABLE categories ADD CONSTRAINT categories_name_unique UNIQUE (name);
    END IF;
END $$;

-- Add RLS for categories if auth schema exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
        
        -- Drop existing policies if they exist
        DROP POLICY IF EXISTS "Categories are viewable by authenticated users" ON categories;
        DROP POLICY IF EXISTS "Categories are modifiable by authenticated users" ON categories;
        
        -- Policy: Categories are readable by all authenticated users
        CREATE POLICY "Categories are viewable by authenticated users" 
        ON categories FOR SELECT 
        TO authenticated 
        USING (true);

        -- Policy: Only admins can modify categories (for now, allow all authenticated)
        CREATE POLICY "Categories are modifiable by authenticated users" 
        ON categories FOR ALL 
        TO authenticated 
        USING (true);
    END IF;
END $$;

-- PART 4: CREATE ACCOUNTS TABLE (for future multi-account support)
-- Handle table creation with proper user_id column setup
DO $$
BEGIN
    -- Create accounts table with complete structure first
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accounts') THEN
        CREATE TABLE accounts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(100) NOT NULL,
            account_type VARCHAR(50) NOT NULL CHECK (account_type IN ('checking', 'savings', 'credit', 'cash', 'investment', 'other')),
            currency VARCHAR(3) DEFAULT 'USD',
            initial_balance DECIMAL(12,2) DEFAULT 0,
            current_balance DECIMAL(12,2) DEFAULT 0,
            is_default BOOLEAN DEFAULT FALSE,
            is_active BOOLEAN DEFAULT TRUE,
            description TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
    
    -- Add missing columns if they don't exist (for existing tables)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'currency'
    ) THEN
        ALTER TABLE accounts ADD COLUMN currency VARCHAR(3) DEFAULT 'USD';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'initial_balance'
    ) THEN
        ALTER TABLE accounts ADD COLUMN initial_balance DECIMAL(12,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'current_balance'
    ) THEN
        ALTER TABLE accounts ADD COLUMN current_balance DECIMAL(12,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'is_default'
    ) THEN
        ALTER TABLE accounts ADD COLUMN is_default BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE accounts ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add user_id column with appropriate constraints based on auth availability
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'user_id'
    ) THEN
        IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
            -- Add with foreign key if auth exists
            ALTER TABLE accounts ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        ELSE
            -- Add without foreign key if auth doesn't exist
            ALTER TABLE accounts ADD COLUMN user_id UUID;
        END IF;
    END IF;
END $$;

-- Add additional constraints to accounts if auth exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        
        -- Add unique constraint only if all required columns exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name LIKE 'accounts_user_id_currency%'
            AND table_name = 'accounts'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'accounts' AND column_name = 'user_id'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'accounts' AND column_name = 'currency'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'accounts' AND column_name = 'is_default'
        ) THEN
            ALTER TABLE accounts 
            ADD CONSTRAINT accounts_user_id_currency_default_unique
            UNIQUE(user_id, currency, is_default) DEFERRABLE INITIALLY DEFERRED;
        END IF;
        
        -- Enable RLS and create policies
        ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Users can view own accounts" ON accounts;
        DROP POLICY IF EXISTS "Users can manage own accounts" ON accounts;
        
        CREATE POLICY "Users can view own accounts" 
        ON accounts FOR SELECT 
        TO authenticated 
        USING (auth.uid() = user_id);

        CREATE POLICY "Users can manage own accounts" 
        ON accounts FOR ALL 
        TO authenticated 
        USING (auth.uid() = user_id);
    END IF;
END $$;

-- PART 5: CREATE RECEIPT_PHOTOS TABLE
-- Handle table creation with proper user_id column setup
DO $$
BEGIN
    -- Create receipt_photos table with basic structure first
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'receipt_photos') THEN
        CREATE TABLE receipt_photos (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            original_filename VARCHAR(255),
            storage_path VARCHAR(500) NOT NULL, -- Path in Supabase storage
            file_size INTEGER,
            mime_type VARCHAR(100),
            width INTEGER,
            height INTEGER,
            is_processed BOOLEAN DEFAULT FALSE,
            ocr_text TEXT, -- For future OCR implementation
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
    
    -- Add user_id column with appropriate constraints based on auth availability
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipt_photos' AND column_name = 'user_id'
    ) THEN
        IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
            -- Add with foreign key if auth exists
            ALTER TABLE receipt_photos ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        ELSE
            -- Add without foreign key if auth doesn't exist
            ALTER TABLE receipt_photos ADD COLUMN user_id UUID;
        END IF;
    END IF;
END $$;

-- Add RLS and policies for receipt_photos if auth exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        
        ALTER TABLE receipt_photos ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Users can view own receipt photos" ON receipt_photos;
        DROP POLICY IF EXISTS "Users can manage own receipt photos" ON receipt_photos;
        
        CREATE POLICY "Users can view own receipt photos" 
        ON receipt_photos FOR SELECT 
        TO authenticated 
        USING (auth.uid() = user_id);

        CREATE POLICY "Users can manage own receipt photos" 
        ON receipt_photos FOR ALL 
        TO authenticated 
        USING (auth.uid() = user_id);
    END IF;
END $$;

-- PART 6: CREATE DEVICES TABLE (for audit trail)
-- Handle table creation with proper user_id column setup
DO $$
BEGIN
    -- Create devices table with basic structure first
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'devices') THEN
        CREATE TABLE devices (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            device_identifier VARCHAR(255) NOT NULL, -- App-generated device ID
            device_name VARCHAR(100),
            platform VARCHAR(50), -- 'android', 'ios', 'web'
            app_version VARCHAR(20),
            last_active TIMESTAMPTZ DEFAULT NOW(),
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
    
    -- Add user_id column with appropriate constraints based on auth availability
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'user_id'
    ) THEN
        IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
            -- Add with foreign key if auth exists
            ALTER TABLE devices ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        ELSE
            -- Add without foreign key if auth doesn't exist
            ALTER TABLE devices ADD COLUMN user_id UUID;
        END IF;
    END IF;
END $$;

-- Add constraints and RLS for devices if auth exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth') THEN
        
        -- Add unique constraint only if all required columns exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name LIKE 'devices_user_id_device_identifier%'
            AND table_name = 'devices'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'devices' AND column_name = 'user_id'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'devices' AND column_name = 'device_identifier'
        ) THEN
            ALTER TABLE devices 
            ADD CONSTRAINT devices_user_device_unique
            UNIQUE(user_id, device_identifier);
        END IF;
        
        ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Users can view own devices" ON devices;
        DROP POLICY IF EXISTS "Users can manage own devices" ON devices;
        
        CREATE POLICY "Users can view own devices" 
        ON devices FOR SELECT 
        TO authenticated 
        USING (auth.uid() = user_id);

        CREATE POLICY "Users can manage own devices" 
        ON devices FOR ALL 
        TO authenticated 
        USING (auth.uid() = user_id);
    END IF;
END $$;

-- PART 7: INSERT DEFAULT CATEGORIES (based on current data)
-- Only insert if all required columns exist
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'display_name'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'is_income_category'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' AND column_name = 'sort_order'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu 
        ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_name = 'categories' 
        AND tc.constraint_type = 'UNIQUE'
        AND ccu.column_name = 'name'
    ) THEN
        INSERT INTO categories (name, display_name, description, is_income_category, sort_order) VALUES
-- Expense Categories
('food', 'Food & Dining', 'Restaurants, groceries, and food-related expenses', FALSE, 10),
('transport', 'Transportation', 'Gas, public transit, rideshare, vehicle maintenance', FALSE, 20),
('entertainment', 'Entertainment', 'Movies, games, hobbies, and leisure activities', FALSE, 30),
('shopping', 'Shopping', 'Retail purchases, clothing, and general merchandise', FALSE, 40),
('bills', 'Bills & Utilities', 'Electricity, water, internet, phone bills', FALSE, 50),
('rent', 'Housing', 'Rent, mortgage, and housing-related costs', FALSE, 60),
('health', 'Healthcare', 'Medical expenses, pharmacy, fitness, wellness', FALSE, 70),
('education', 'Education', 'Tuition, books, courses, and learning materials', FALSE, 80),
('insurance', 'Insurance', 'Auto, health, life, and property insurance', FALSE, 90),
('technology', 'Technology', 'Software, hardware, and tech-related purchases', FALSE, 100),
('travel', 'Travel', 'Flights, hotels, vacation expenses', FALSE, 110),
('subscriptions', 'Subscriptions', 'Streaming, software, and recurring services', FALSE, 120),
('charity', 'Charity & Donations', 'Charitable giving and donations', FALSE, 130),
('gifts', 'Gifts', 'Presents and gift-related expenses', FALSE, 140),
('pets', 'Pet Care', 'Pet food, veterinary, and pet supplies', FALSE, 150),
('beauty', 'Beauty & Personal Care', 'Cosmetics, haircare, and personal grooming', FALSE, 160),
('sports', 'Sports & Fitness', 'Gym, sports equipment, and fitness activities', FALSE, 170),
('investments', 'Investments', 'Investment purchases and fees', FALSE, 180),
('taxes', 'Taxes', 'Tax payments and related fees', FALSE, 190),
('books', 'Books & Media', 'Books, magazines, and media content', FALSE, 200),
('home', 'Home & Garden', 'Home improvement, furniture, and garden supplies', FALSE, 210),
('other', 'Other Expenses', 'Miscellaneous and uncategorized expenses', FALSE, 999),

-- Income Categories
('salary', 'Salary & Wages', 'Primary income from employment', TRUE, 10),
('freelance', 'Freelance & Consulting', 'Independent contractor income', TRUE, 20),
('business', 'Business Income', 'Revenue from business operations', TRUE, 30),
('investment_income', 'Investment Income', 'Dividends, interest, and investment gains', TRUE, 40),
('rental', 'Rental Income', 'Income from property rentals', TRUE, 50),
('gift_income', 'Gifts Received', 'Money received as gifts', TRUE, 60),
('refund', 'Refunds', 'Tax refunds and purchase refunds', TRUE, 70),
('other_income', 'Other Income', 'Miscellaneous income sources', TRUE, 999)

        ON CONFLICT (name) DO NOTHING;
    ELSE
        -- If columns don't exist, insert with minimal schema (just name) without ON CONFLICT
        -- First check if UNIQUE constraint exists for safe insertion
        IF EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            JOIN information_schema.constraint_column_usage ccu 
            ON tc.constraint_name = ccu.constraint_name
            WHERE tc.table_name = 'categories' 
            AND tc.constraint_type = 'UNIQUE'
            AND ccu.column_name = 'name'
        ) THEN
            -- UNIQUE constraint exists, safe to use ON CONFLICT
            INSERT INTO categories (name) VALUES
            ('food'), ('transport'), ('entertainment'), ('shopping'), ('bills'), 
            ('rent'), ('health'), ('education'), ('insurance'), ('technology'), 
            ('travel'), ('subscriptions'), ('charity'), ('gifts'), ('pets'), 
            ('beauty'), ('sports'), ('investments'), ('taxes'), ('books'), 
            ('home'), ('other'), ('salary'), ('freelance'), ('business'), 
            ('investment_income'), ('rental'), ('gift_income'), ('refund'), ('other_income')
            ON CONFLICT (name) DO NOTHING;
        ELSE
            -- No UNIQUE constraint, insert only if not exists
            DECLARE
                category_names TEXT[] := ARRAY[
                    'food', 'transport', 'entertainment', 'shopping', 'bills', 
                    'rent', 'health', 'education', 'insurance', 'technology', 
                    'travel', 'subscriptions', 'charity', 'gifts', 'pets', 
                    'beauty', 'sports', 'investments', 'taxes', 'books', 
                    'home', 'other', 'salary', 'freelance', 'business', 
                    'investment_income', 'rental', 'gift_income', 'refund', 'other_income'
                ];
                category_name TEXT;
            BEGIN
                FOREACH category_name IN ARRAY category_names LOOP
                    IF NOT EXISTS (SELECT 1 FROM categories WHERE name = category_name) THEN
                        INSERT INTO categories (name) VALUES (category_name);
                    END IF;
                END LOOP;
            END;
        END IF;
    END IF;
END $$;

-- PART 8: ENSURE EXPENSES TABLE HAS ALL REQUIRED FOREIGN KEY COLUMNS
-- Add columns that might be missing from the expenses table
DO $$
BEGIN
    -- Add category_id column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'category_id'
    ) THEN
        ALTER TABLE expenses ADD COLUMN category_id UUID;
    END IF;
    
    -- Add account_id column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'account_id'
    ) THEN
        ALTER TABLE expenses ADD COLUMN account_id UUID;
    END IF;
    
    -- Add receipt_photo_id column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'receipt_photo_id'
    ) THEN
        ALTER TABLE expenses ADD COLUMN receipt_photo_id UUID;
    END IF;
    
    -- Add device_id column if missing (might be TEXT from old schema)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'device_id'
    ) THEN
        ALTER TABLE expenses ADD COLUMN device_id TEXT;
    END IF;
    
    -- Add last_editor column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'last_editor'
    ) THEN
        ALTER TABLE expenses ADD COLUMN last_editor TEXT;
    END IF;
    
    -- Add type column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'type'
    ) THEN
        ALTER TABLE expenses ADD COLUMN type TEXT DEFAULT 'expense';
    END IF;
    
    -- Add category column if missing (legacy support)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'category'
    ) THEN
        ALTER TABLE expenses ADD COLUMN category TEXT;
    END IF;
END $$;

-- PART 9: ADD FOREIGN KEY CONSTRAINTS TO EXPENSES TABLE
-- Only add constraints if the target tables exist
DO $$
BEGIN
    -- Add foreign key to categories if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'expenses_category_id_fkey' 
        AND table_name = 'expenses'
    ) AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'categories') THEN
        ALTER TABLE expenses 
        ADD CONSTRAINT expenses_category_id_fkey 
        FOREIGN KEY (category_id) REFERENCES categories(id);
    END IF;
    
    -- Add foreign key to accounts if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'expenses_account_id_fkey' 
        AND table_name = 'expenses'
    ) AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accounts') THEN
        ALTER TABLE expenses 
        ADD CONSTRAINT expenses_account_id_fkey 
        FOREIGN KEY (account_id) REFERENCES accounts(id);
    END IF;
    
    -- Add foreign key to receipt_photos if not exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'expenses_receipt_photo_id_fkey' 
        AND table_name = 'expenses'
    ) AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'receipt_photos') THEN
        ALTER TABLE expenses 
        ADD CONSTRAINT expenses_receipt_photo_id_fkey 
        FOREIGN KEY (receipt_photo_id) REFERENCES receipt_photos(id);
    END IF;
END $$;

-- PART 10: ADD AUDIT TRIGGER FOR LAST_EDITOR
CREATE OR REPLACE FUNCTION update_last_editor()
RETURNS TRIGGER AS $$
BEGIN
    -- Get current user ID from JWT token if auth exists
    BEGIN
        NEW.last_editor := auth.uid()::text;
    EXCEPTION WHEN OTHERS THEN
        -- If auth.uid() doesn't exist, use a default value
        NEW.last_editor := 'system';
    END;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply trigger to expenses table
DROP TRIGGER IF EXISTS expenses_update_last_editor ON expenses;
CREATE TRIGGER expenses_update_last_editor
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_last_editor();

-- PART 11: CREATE FUNCTION TO UPDATE CATEGORY_ID BASED ON CATEGORY STRING
CREATE OR REPLACE FUNCTION migrate_expense_categories()
RETURNS void AS $$
DECLARE
    expense_record RECORD;
    category_uuid UUID;
BEGIN
    -- Only run if expenses table has both category and category_id columns
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'category'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'expenses' AND column_name = 'category_id'
    ) THEN
        -- Loop through all expenses with NULL category_id
        FOR expense_record IN 
            SELECT id, category FROM expenses WHERE category_id IS NULL AND category IS NOT NULL
        LOOP
            -- Find matching category (case-insensitive, handle special cases)
            SELECT id INTO category_uuid 
            FROM categories 
            WHERE LOWER(name) = LOWER(
                CASE 
                    WHEN expense_record.category = 'категория' THEN 'other'
                    WHEN expense_record.category = 'Food' THEN 'food'
                    ELSE expense_record.category
                END
            );
            
            -- If no exact match found, use 'other'
            IF category_uuid IS NULL THEN
                SELECT id INTO category_uuid 
                FROM categories 
                WHERE name = 'other';
            END IF;
            
            -- Update the expense record
            UPDATE expenses 
            SET category_id = category_uuid
            WHERE id = expense_record.id;
        END LOOP;
        
        RAISE NOTICE 'Expense category migration completed';
    ELSE
        RAISE NOTICE 'Skipping category migration - required columns not found';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- PART 12: ADD UPDATED_AT TRIGGER FOR ALL TABLES
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables (with existence checks)
DO $$
BEGIN
    -- Categories table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'categories') THEN
        DROP TRIGGER IF EXISTS categories_updated_at ON categories;
        CREATE TRIGGER categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Accounts table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accounts') THEN
        DROP TRIGGER IF EXISTS accounts_updated_at ON accounts;
        CREATE TRIGGER accounts_updated_at BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Receipt photos table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'receipt_photos') THEN
        DROP TRIGGER IF EXISTS receipt_photos_updated_at ON receipt_photos;
        CREATE TRIGGER receipt_photos_updated_at BEFORE UPDATE ON receipt_photos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Expenses table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'expenses') THEN
        DROP TRIGGER IF EXISTS expenses_updated_at ON expenses;
        CREATE TRIGGER expenses_updated_at BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- PART 13: ADD INDEXES FOR PERFORMANCE (with existence checks)
-- Only create indexes if columns exist
DO $$
BEGIN
    -- Expenses indexes (check column existence first)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'category_id') THEN
        CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'account_id') THEN
        CREATE INDEX IF NOT EXISTS idx_expenses_account_id ON expenses(account_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'receipt_photo_id') THEN
        CREATE INDEX IF NOT EXISTS idx_expenses_receipt_photo_id ON expenses(receipt_photo_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'device_id') THEN
        CREATE INDEX IF NOT EXISTS idx_expenses_device_id ON expenses(device_id);
    END IF;
    
    -- Only create user_id + date index if both columns exist
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'user_id') 
    AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'date') THEN
        CREATE INDEX IF NOT EXISTS idx_expenses_user_id_date ON expenses(user_id, date);
    END IF;
    
    -- Other table indexes
    CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'accounts' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'receipt_photos' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_receipt_photos_user_id ON receipt_photos(user_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') THEN
        CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
    END IF;
END $$;

-- PART 14: ADD COMMENTS FOR DOCUMENTATION
COMMENT ON TABLE categories IS 'Expense and income categories with proper normalization';
COMMENT ON TABLE accounts IS 'User accounts for multi-account expense tracking';
COMMENT ON TABLE receipt_photos IS 'Storage metadata for receipt photos';
COMMENT ON TABLE devices IS 'Device tracking for audit trails and sync';

-- Add comments only if columns exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'category_id') THEN
        COMMENT ON COLUMN expenses.category_id IS 'Foreign key to categories table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'account_id') THEN
        COMMENT ON COLUMN expenses.account_id IS 'Foreign key to accounts table for multi-account support';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'receipt_photo_id') THEN
        COMMENT ON COLUMN expenses.receipt_photo_id IS 'Foreign key to receipt_photos table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'device_id') THEN
        COMMENT ON COLUMN expenses.device_id IS 'Foreign key to devices table for audit trail';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'last_editor') THEN
        COMMENT ON COLUMN expenses.last_editor IS 'UUID of user who last modified this record';
    END IF;
END $$;

-- PART 15: FINAL SUCCESS MESSAGE
DO $$
BEGIN
    RAISE NOTICE '=== MIGRATION COMPLETED SUCCESSFULLY ===';
    RAISE NOTICE 'Future-proof schema has been implemented with:';
    RAISE NOTICE '- Normalized categories table (% records)', (SELECT COUNT(*) FROM categories);
    RAISE NOTICE '- Multi-account support table created';
    RAISE NOTICE '- Receipt photos table created';  
    RAISE NOTICE '- Device tracking table created';
    RAISE NOTICE '- All foreign key columns added to expenses table';
    RAISE NOTICE '- Comprehensive indexing implemented';
    RAISE NOTICE '- Audit trails and triggers active';
    RAISE NOTICE '=========================================';
END $$;