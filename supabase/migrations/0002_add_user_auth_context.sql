-- Migration V2: Add user authentication context to all tables
-- This migration adds user_id columns and proper constraints for authenticated users

-- Add user_id columns to all user-specific tables
ALTER TABLE categories 
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE accounts 
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE expenses 
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE budgets 
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add user profiles table for extended user information
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  currency TEXT DEFAULT 'USD',
  date_format TEXT DEFAULT 'MM/dd/yyyy',
  first_day_of_week INTEGER DEFAULT 0, -- 0 = Sunday, 1 = Monday
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  version INTEGER DEFAULT 1,
  is_deleted BOOLEAN DEFAULT FALSE,
  device_id TEXT,
  last_editor TEXT
);

-- Add RLS to user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create performance indexes on user_id columns
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles(updated_at);

-- Add composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user_category ON expenses(user_id, category_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user_category ON budgets(user_id, category_id);

-- Version bump trigger for user_profiles
DROP TRIGGER IF EXISTS user_profiles_version_trigger ON user_profiles;
CREATE TRIGGER user_profiles_version_trigger
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION bump_version();

-- Create shared categories table for default/system categories
CREATE TABLE IF NOT EXISTS shared_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT DEFAULT '#2196F3',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  version INTEGER DEFAULT 1,
  is_deleted BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0
);

-- Enable RLS on shared categories (readable by all authenticated users)
ALTER TABLE shared_categories ENABLE ROW LEVEL SECURITY;

-- Migrate existing categories to shared categories (preserving current defaults)
INSERT INTO shared_categories (id, name, icon, color, sort_order)
SELECT id, name, icon, color, 
  ROW_NUMBER() OVER (ORDER BY created_at) as sort_order
FROM categories 
WHERE user_id IS NULL
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  icon = EXCLUDED.icon,
  color = EXCLUDED.color,
  sort_order = EXCLUDED.sort_order;

-- Create financial goals table for user goal tracking
CREATE TABLE IF NOT EXISTS financial_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  target_amount DECIMAL(12,2) NOT NULL,
  current_amount DECIMAL(12,2) DEFAULT 0,
  target_date DATE,
  category_id UUID REFERENCES categories(id),
  is_achieved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  version INTEGER DEFAULT 1,
  is_deleted BOOLEAN DEFAULT FALSE,
  device_id TEXT,
  last_editor TEXT
);

-- Enable RLS and add indexes for financial goals
ALTER TABLE financial_goals ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_financial_goals_user_id ON financial_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_goals_target_date ON financial_goals(target_date);

-- Version bump trigger for financial goals
DROP TRIGGER IF EXISTS financial_goals_version_trigger ON financial_goals;
CREATE TRIGGER financial_goals_version_trigger
  BEFORE UPDATE ON financial_goals
  FOR EACH ROW EXECUTE FUNCTION bump_version();

-- Create export history table for tracking user exports
CREATE TABLE IF NOT EXISTS export_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  export_type TEXT NOT NULL, -- 'csv', 'json', 'pdf'
  date_range_start DATE,
  date_range_end DATE,
  categories TEXT[], -- JSON array of category IDs included
  file_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ, -- When the export file expires
  is_deleted BOOLEAN DEFAULT FALSE
);

-- Enable RLS and add indexes for export history
ALTER TABLE export_history ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_export_history_user_id ON export_history(user_id);
CREATE INDEX IF NOT EXISTS idx_export_history_created_at ON export_history(created_at DESC);

-- User initialization function (called when new user signs up)
CREATE OR REPLACE FUNCTION initialize_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Create user profile
  INSERT INTO user_profiles (id, display_name, created_at)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)), NOW());
  
  -- Create default personal categories for the user
  INSERT INTO categories (name, icon, color, user_id, device_id, last_editor)
  SELECT 
    sc.name,
    sc.icon,
    sc.color,
    NEW.id,
    'system',
    'system'
  FROM shared_categories sc
  WHERE NOT sc.is_deleted
  ORDER BY sc.sort_order;
  
  -- Create default cash account for the user
  INSERT INTO accounts (name, type, balance, user_id, device_id, last_editor)
  VALUES ('Cash', 'cash', 0.00, NEW.id, 'system', 'system');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for user initialization
DROP TRIGGER IF EXISTS initialize_user_trigger ON auth.users;
CREATE TRIGGER initialize_user_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION initialize_user_profile();

-- Data migration function to handle existing anonymous data
CREATE OR REPLACE FUNCTION migrate_anonymous_data_to_user(target_user_id UUID, device_identifier TEXT DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
  migrated_records JSON;
  category_count INTEGER;
  account_count INTEGER;
  expense_count INTEGER;
  budget_count INTEGER;
BEGIN
  -- Start transaction for data migration
  
  -- Migrate categories (only if device_id matches or if no device filter)
  UPDATE categories 
  SET user_id = target_user_id,
      last_editor = 'migration',
      updated_at = NOW()
  WHERE user_id IS NULL 
    AND (device_identifier IS NULL OR device_id = device_identifier)
    AND NOT EXISTS (
      SELECT 1 FROM categories c2 
      WHERE c2.user_id = target_user_id 
        AND c2.name = categories.name
    );
  GET DIAGNOSTICS category_count = ROW_COUNT;
  
  -- Migrate accounts
  UPDATE accounts 
  SET user_id = target_user_id,
      last_editor = 'migration',
      updated_at = NOW()
  WHERE user_id IS NULL 
    AND (device_identifier IS NULL OR device_id = device_identifier);
  GET DIAGNOSTICS account_count = ROW_COUNT;
  
  -- Migrate expenses
  UPDATE expenses 
  SET user_id = target_user_id,
      last_editor = 'migration',
      updated_at = NOW()
  WHERE user_id IS NULL 
    AND (device_identifier IS NULL OR device_id = device_identifier);
  GET DIAGNOSTICS expense_count = ROW_COUNT;
  
  -- Migrate budgets
  UPDATE budgets 
  SET user_id = target_user_id,
      last_editor = 'migration',
      updated_at = NOW()
  WHERE user_id IS NULL 
    AND (device_identifier IS NULL OR device_id = device_identifier);
  GET DIAGNOSTICS budget_count = ROW_COUNT;
  
  -- Return migration summary
  migrated_records := json_build_object(
    'user_id', target_user_id,
    'device_id', device_identifier,
    'migrated_categories', category_count,
    'migrated_accounts', account_count,
    'migrated_expenses', expense_count,
    'migrated_budgets', budget_count,
    'migration_completed_at', NOW()
  );
  
  RETURN migrated_records;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup function to remove orphaned records
CREATE OR REPLACE FUNCTION cleanup_orphaned_records()
RETURNS JSON AS $$
DECLARE
  cleanup_summary JSON;
  deleted_categories INTEGER;
  deleted_accounts INTEGER;
  deleted_expenses INTEGER;
  deleted_budgets INTEGER;
BEGIN
  -- Mark orphaned records as deleted (soft delete)
  
  UPDATE categories 
  SET is_deleted = TRUE, updated_at = NOW()
  WHERE user_id IS NULL AND created_at < NOW() - INTERVAL '30 days';
  GET DIAGNOSTICS deleted_categories = ROW_COUNT;
  
  UPDATE accounts 
  SET is_deleted = TRUE, updated_at = NOW()
  WHERE user_id IS NULL AND created_at < NOW() - INTERVAL '30 days';
  GET DIAGNOSTICS deleted_accounts = ROW_COUNT;
  
  UPDATE expenses 
  SET is_deleted = TRUE, updated_at = NOW()
  WHERE user_id IS NULL AND created_at < NOW() - INTERVAL '30 days';
  GET DIAGNOSTICS deleted_expenses = ROW_COUNT;
  
  UPDATE budgets 
  SET is_deleted = TRUE, updated_at = NOW()
  WHERE user_id IS NULL AND created_at < NOW() - INTERVAL '30 days';
  GET DIAGNOSTICS deleted_budgets = ROW_COUNT;
  
  cleanup_summary := json_build_object(
    'cleaned_categories', deleted_categories,
    'cleaned_accounts', deleted_accounts,
    'cleaned_expenses', deleted_expenses,
    'cleaned_budgets', deleted_budgets,
    'cleanup_completed_at', NOW()
  );
  
  RETURN cleanup_summary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add constraints to ensure data integrity
-- Note: Subquery check constraints not supported in PostgreSQL
-- Data integrity will be enforced through RLS policies instead

-- Update existing null user_id records to maintain referential integrity
-- This is a temporary measure until full migration is complete
UPDATE categories SET device_id = 'legacy' WHERE user_id IS NULL AND device_id IS NULL;
UPDATE accounts SET device_id = 'legacy' WHERE user_id IS NULL AND device_id IS NULL;
UPDATE expenses SET device_id = 'legacy' WHERE user_id IS NULL AND device_id IS NULL;
UPDATE budgets SET device_id = 'legacy' WHERE user_id IS NULL AND device_id IS NULL;

-- Record this migration
INSERT INTO app_migrations (version, name, checksum) VALUES 
  (2, 'Add user authentication context and user profiles', 'v2-user-auth-context')
ON CONFLICT (version) DO NOTHING;