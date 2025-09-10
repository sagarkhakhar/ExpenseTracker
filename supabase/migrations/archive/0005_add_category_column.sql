-- Add category column to expenses table for backward compatibility
-- This allows the client to sync both category (string) and category_id (UUID)

BEGIN;

-- Add category column as TEXT to support string categories
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS category TEXT;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);

-- Add constraint to ensure either category or category_id is provided
ALTER TABLE expenses 
ADD CONSTRAINT check_category_or_category_id 
CHECK (category IS NOT NULL OR category_id IS NOT NULL);

COMMIT;