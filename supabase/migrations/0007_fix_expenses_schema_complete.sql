-- Comprehensive fix for expenses table schema to match client expectations
-- Adds missing user_id column and ensures compatibility with sync data

BEGIN;

-- Add user_id column for RLS and user isolation
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS user_id UUID;

-- Add foreign key constraint to auth.users (if auth schema exists)
-- This will fail gracefully if auth.users doesn't exist yet
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
    ALTER TABLE expenses 
    ADD CONSTRAINT fk_expenses_user_id 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
EXCEPTION WHEN others THEN
  -- Ignore if constraint already exists or auth.users doesn't exist
  NULL;
END $$;

-- Create index for user_id (performance for RLS queries)
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);

-- Update RLS policies to use user_id instead of allowing all
DROP POLICY IF EXISTS "Allow all access to expenses" ON expenses;

-- Create user-specific RLS policies
CREATE POLICY "Users can view their own expenses" ON expenses
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own expenses" ON expenses
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own expenses" ON expenses
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own expenses" ON expenses
  FOR DELETE USING (user_id = auth.uid());

-- Ensure the type column exists (in case previous migration wasn't applied)
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'expense';

-- Add constraint for type if it doesn't exist
DO $$
BEGIN
  ALTER TABLE expenses 
  ADD CONSTRAINT check_expense_type 
  CHECK (type IN ('income', 'expense'));
EXCEPTION WHEN duplicate_object THEN
  -- Constraint already exists, ignore
  NULL;
END $$;

-- Add type index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_expenses_type ON expenses(type);

-- Make type NOT NULL with default
UPDATE expenses SET type = 'expense' WHERE type IS NULL;
ALTER TABLE expenses ALTER COLUMN type SET NOT NULL;

COMMIT;