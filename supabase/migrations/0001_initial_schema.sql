-- Migration V1: Initial schema for offline-first expense tracker
-- This migration creates the base tables with sync support

-- Create app_migrations table to track migration state
CREATE TABLE IF NOT EXISTS app_migrations (
  id SERIAL PRIMARY KEY,
  version INTEGER NOT NULL UNIQUE,
  name TEXT NOT NULL,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  checksum TEXT
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT DEFAULT '#2196F3',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  version INTEGER DEFAULT 1,
  is_deleted BOOLEAN DEFAULT FALSE,
  device_id TEXT,
  last_editor TEXT
);

-- Accounts table  
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'cash',
  balance DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  version INTEGER DEFAULT 1,
  is_deleted BOOLEAN DEFAULT FALSE,
  device_id TEXT,
  last_editor TEXT
);

-- Expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  category_id UUID REFERENCES categories(id),
  account_id UUID REFERENCES accounts(id),
  date DATE NOT NULL,
  description TEXT,
  receipt_photo_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  version INTEGER DEFAULT 1,
  is_deleted BOOLEAN DEFAULT FALSE,
  device_id TEXT,
  last_editor TEXT
);

-- Budgets table
CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  category_id UUID REFERENCES categories(id),
  period TEXT NOT NULL DEFAULT 'monthly',
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  version INTEGER DEFAULT 1,
  is_deleted BOOLEAN DEFAULT FALSE,
  device_id TEXT,
  last_editor TEXT
);

-- Create indexes for performance and sync
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_updated_at ON expenses(updated_at);
CREATE INDEX IF NOT EXISTS idx_categories_updated_at ON categories(updated_at);
CREATE INDEX IF NOT EXISTS idx_accounts_updated_at ON accounts(updated_at);
CREATE INDEX IF NOT EXISTS idx_budgets_updated_at ON budgets(updated_at);

-- Sync-related indexes
CREATE INDEX IF NOT EXISTS idx_expenses_version ON expenses(version);
CREATE INDEX IF NOT EXISTS idx_categories_version ON categories(version);
CREATE INDEX IF NOT EXISTS idx_accounts_version ON accounts(version);
CREATE INDEX IF NOT EXISTS idx_budgets_version ON budgets(version);

-- Version bump trigger function
CREATE OR REPLACE FUNCTION bump_version()
RETURNS TRIGGER AS $$
BEGIN
  NEW.version = OLD.version + 1;
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create version bump triggers for all tables
DROP TRIGGER IF EXISTS categories_version_trigger ON categories;
CREATE TRIGGER categories_version_trigger
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION bump_version();

DROP TRIGGER IF EXISTS accounts_version_trigger ON accounts;
CREATE TRIGGER accounts_version_trigger
  BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION bump_version();

DROP TRIGGER IF EXISTS expenses_version_trigger ON expenses;
CREATE TRIGGER expenses_version_trigger
  BEFORE UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION bump_version();

DROP TRIGGER IF EXISTS budgets_version_trigger ON budgets;
CREATE TRIGGER budgets_version_trigger
  BEFORE UPDATE ON budgets
  FOR EACH ROW EXECUTE FUNCTION bump_version();

-- Enable Row Level Security
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies (allow all for now - will be restricted per user in future)
-- These policies will be updated when authentication is implemented

DROP POLICY IF EXISTS "Allow all access to categories" ON categories;
CREATE POLICY "Allow all access to categories" ON categories FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access to accounts" ON accounts;
CREATE POLICY "Allow all access to accounts" ON accounts FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access to expenses" ON expenses;
CREATE POLICY "Allow all access to expenses" ON expenses FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access to budgets" ON budgets;
CREATE POLICY "Allow all access to budgets" ON budgets FOR ALL USING (true);

-- Helper functions for sync operations

-- Function to check if table exists (used by Edge Functions)
CREATE OR REPLACE FUNCTION check_table_exists(table_name text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = $1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to execute SQL (used by Edge Functions for migrations)
CREATE OR REPLACE FUNCTION exec_sql(sql text)
RETURNS void AS $$
BEGIN
  EXECUTE sql;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- First check if display_name column exists and add it if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' 
        AND column_name = 'display_name'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE categories ADD COLUMN display_name TEXT;
    END IF;
END $$;

-- Insert default categories with display_name handling
DO $$
BEGIN
    -- Check if display_name column exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categories' 
        AND column_name = 'display_name'
        AND table_schema = 'public'
    ) THEN
        -- Insert with display_name
        INSERT INTO categories (name, display_name, icon, color) VALUES 
          ('Food & Dining', 'Food & Dining', '🍽️', '#FF6B6B'),
          ('Transportation', 'Transportation', '🚗', '#4ECDC4'),
          ('Shopping', 'Shopping', '🛍️', '#45B7D1'),
          ('Entertainment', 'Entertainment', '🎬', '#96CEB4'),
          ('Bills & Utilities', 'Bills & Utilities', '⚡', '#FFEAA7'),
          ('Health & Medical', 'Health & Medical', '🏥', '#DDA0DD'),
          ('Travel', 'Travel', '✈️', '#98D8C8'),
          ('Education', 'Education', '📚', '#F7DC6F'),
          ('Other', 'Other', '📦', '#BDC3C7')
        ON CONFLICT DO NOTHING;
    ELSE
        -- Insert without display_name
        INSERT INTO categories (name, icon, color) VALUES 
          ('Food & Dining', '🍽️', '#FF6B6B'),
          ('Transportation', '🚗', '#4ECDC4'),
          ('Shopping', '🛍️', '#45B7D1'),
          ('Entertainment', '🎬', '#96CEB4'),
          ('Bills & Utilities', '⚡', '#FFEAA7'),
          ('Health & Medical', '🏥', '#DDA0DD'),
          ('Travel', '✈️', '#98D8C8'),
          ('Education', '📚', '#F7DC6F'),
          ('Other', '📦', '#BDC3C7')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Insert default account
INSERT INTO accounts (name, type, balance) VALUES 
  ('Cash', 'cash', 0.00),
  ('Bank Account', 'bank', 0.00)
ON CONFLICT DO NOTHING;

-- Record this migration
INSERT INTO app_migrations (version, name, checksum) VALUES 
  (1, 'Initial offline-first sync tables', 'v1-initial-schema')
ON CONFLICT (version) DO NOTHING;