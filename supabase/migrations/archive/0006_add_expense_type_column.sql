-- Add type column to expenses table to support income/expense classification
-- This resolves sync issues where the client sends type data but the server schema lacks the column

BEGIN;

-- Add type column to expenses table
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'expense';

-- Add constraint to ensure type is either 'income' or 'expense'
ALTER TABLE expenses 
ADD CONSTRAINT check_expense_type 
CHECK (type IN ('income', 'expense'));

-- Add index for performance when filtering by type
CREATE INDEX IF NOT EXISTS idx_expenses_type ON expenses(type);

-- Update any existing records to have default type 'expense'
-- This ensures backward compatibility with existing data
UPDATE expenses 
SET type = 'expense' 
WHERE type IS NULL;

-- Make type column NOT NULL now that all existing records have values
ALTER TABLE expenses 
ALTER COLUMN type SET NOT NULL;

COMMIT;