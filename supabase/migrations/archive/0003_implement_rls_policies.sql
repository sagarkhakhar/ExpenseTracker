-- Migration V3: Implement comprehensive Row Level Security (RLS) policies
-- This migration creates secure RLS policies for user data isolation

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Allow all access to categories" ON categories;
DROP POLICY IF EXISTS "Allow all access to accounts" ON accounts;
DROP POLICY IF EXISTS "Allow all access to expenses" ON expenses;
DROP POLICY IF EXISTS "Allow all access to budgets" ON budgets;

-- ========================================
-- USER PROFILES RLS POLICIES
-- ========================================

-- Users can only access their own profile
CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can insert their own profile (handled by trigger, but allow explicit inserts)
CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Users can delete their own profile
CREATE POLICY "Users can delete their own profile" ON user_profiles
  FOR DELETE
  TO authenticated
  USING (auth.uid() = id);

-- ========================================
-- CATEGORIES RLS POLICIES
-- ========================================

-- Users can view their own categories and shared categories
CREATE POLICY "Users can view their categories and shared categories" ON categories
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR 
    id IN (SELECT id FROM shared_categories WHERE NOT is_deleted)
  );

-- Users can insert their own categories
CREATE POLICY "Users can insert their own categories" ON categories
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own categories
CREATE POLICY "Users can update their own categories" ON categories
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own categories
CREATE POLICY "Users can delete their own categories" ON categories
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ========================================
-- SHARED CATEGORIES RLS POLICIES
-- ========================================

-- All authenticated users can view shared categories
CREATE POLICY "Authenticated users can view shared categories" ON shared_categories
  FOR SELECT
  TO authenticated
  USING (NOT is_deleted);

-- Only service role can modify shared categories (admin functionality)
CREATE POLICY "Service role can manage shared categories" ON shared_categories
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ========================================
-- ACCOUNTS RLS POLICIES
-- ========================================

-- Users can only access their own accounts
CREATE POLICY "Users can view their own accounts" ON accounts
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted);

-- Users can insert their own accounts
CREATE POLICY "Users can insert their own accounts" ON accounts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own accounts
CREATE POLICY "Users can update their own accounts" ON accounts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can soft delete their own accounts
CREATE POLICY "Users can delete their own accounts" ON accounts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted)
  WITH CHECK (auth.uid() = user_id AND is_deleted = TRUE);

-- ========================================
-- EXPENSES RLS POLICIES
-- ========================================

-- Users can view their own expenses
CREATE POLICY "Users can view their own expenses" ON expenses
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted);

-- Users can insert their own expenses
CREATE POLICY "Users can insert their own expenses" ON expenses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND
    -- Ensure the category belongs to the user or is shared
    (category_id IS NULL OR 
     category_id IN (
       SELECT id FROM categories 
       WHERE user_id = auth.uid() OR id IN (SELECT id FROM shared_categories)
     )) AND
    -- Ensure the account belongs to the user
    (account_id IS NULL OR 
     account_id IN (SELECT id FROM accounts WHERE user_id = auth.uid()))
  );

-- Users can update their own expenses
CREATE POLICY "Users can update their own expenses" ON expenses
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    -- Same validation as insert
    (category_id IS NULL OR 
     category_id IN (
       SELECT id FROM categories 
       WHERE user_id = auth.uid() OR id IN (SELECT id FROM shared_categories)
     )) AND
    (account_id IS NULL OR 
     account_id IN (SELECT id FROM accounts WHERE user_id = auth.uid()))
  );

-- Users can soft delete their own expenses
CREATE POLICY "Users can delete their own expenses" ON expenses
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted)
  WITH CHECK (auth.uid() = user_id AND is_deleted = TRUE);

-- ========================================
-- BUDGETS RLS POLICIES
-- ========================================

-- Users can view their own budgets
CREATE POLICY "Users can view their own budgets" ON budgets
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted);

-- Users can insert their own budgets
CREATE POLICY "Users can insert their own budgets" ON budgets
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND
    -- Ensure the category belongs to the user or is shared
    (category_id IS NULL OR 
     category_id IN (
       SELECT id FROM categories 
       WHERE user_id = auth.uid() OR id IN (SELECT id FROM shared_categories)
     ))
  );

-- Users can update their own budgets
CREATE POLICY "Users can update their own budgets" ON budgets
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    (category_id IS NULL OR 
     category_id IN (
       SELECT id FROM categories 
       WHERE user_id = auth.uid() OR id IN (SELECT id FROM shared_categories)
     ))
  );

-- Users can soft delete their own budgets
CREATE POLICY "Users can delete their own budgets" ON budgets
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted)
  WITH CHECK (auth.uid() = user_id AND is_deleted = TRUE);

-- ========================================
-- FINANCIAL GOALS RLS POLICIES
-- ========================================

-- Users can view their own financial goals
CREATE POLICY "Users can view their own financial goals" ON financial_goals
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted);

-- Users can insert their own financial goals
CREATE POLICY "Users can insert their own financial goals" ON financial_goals
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND
    (category_id IS NULL OR 
     category_id IN (
       SELECT id FROM categories 
       WHERE user_id = auth.uid() OR id IN (SELECT id FROM shared_categories)
     ))
  );

-- Users can update their own financial goals
CREATE POLICY "Users can update their own financial goals" ON financial_goals
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    (category_id IS NULL OR 
     category_id IN (
       SELECT id FROM categories 
       WHERE user_id = auth.uid() OR id IN (SELECT id FROM shared_categories)
     ))
  );

-- Users can soft delete their own financial goals
CREATE POLICY "Users can delete their own financial goals" ON financial_goals
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted)
  WITH CHECK (auth.uid() = user_id AND is_deleted = TRUE);

-- ========================================
-- EXPORT HISTORY RLS POLICIES
-- ========================================

-- Users can view their own export history
CREATE POLICY "Users can view their own export history" ON export_history
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id AND NOT is_deleted);

-- Users can insert their own export records
CREATE POLICY "Users can insert their own export history" ON export_history
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own export records (for cleanup/expiry)
CREATE POLICY "Users can update their own export history" ON export_history
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own export records
CREATE POLICY "Users can delete their own export history" ON export_history
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ========================================
-- SECURITY FUNCTIONS
-- ========================================

-- Function to check if a user owns a category
CREATE OR REPLACE FUNCTION user_owns_category(category_uuid UUID, user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM categories 
    WHERE id = category_uuid 
      AND (user_id = user_uuid OR id IN (SELECT id FROM shared_categories))
      AND NOT is_deleted
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user owns an account
CREATE OR REPLACE FUNCTION user_owns_account(account_uuid UUID, user_uuid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM accounts 
    WHERE id = account_uuid 
      AND user_id = user_uuid 
      AND NOT is_deleted
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate expense ownership and relationships
CREATE OR REPLACE FUNCTION validate_expense_ownership(
  expense_user_id UUID,
  expense_category_id UUID DEFAULT NULL,
  expense_account_id UUID DEFAULT NULL,
  user_uuid UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check user ownership
  IF expense_user_id != user_uuid THEN
    RETURN FALSE;
  END IF;
  
  -- Check category ownership if provided
  IF expense_category_id IS NOT NULL AND NOT user_owns_category(expense_category_id, user_uuid) THEN
    RETURN FALSE;
  END IF;
  
  -- Check account ownership if provided
  IF expense_account_id IS NOT NULL AND NOT user_owns_account(expense_account_id, user_uuid) THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- SECURITY MONITORING AND LOGGING
-- ========================================

-- Create security audit log table
CREATE TABLE IF NOT EXISTS security_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE, SELECT
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  policy_violated TEXT -- If a policy was violated
);

-- Enable RLS on audit log (users can only see their own audit entries)
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own audit log" ON security_audit_log
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Service role can view all audit logs for monitoring
CREATE POLICY "Service role can view all audit logs" ON security_audit_log
  FOR SELECT
  TO service_role
  USING (true);

-- Create indexes for audit log performance
CREATE INDEX IF NOT EXISTS idx_security_audit_log_user_id ON security_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_log_created_at ON security_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_audit_log_table_operation ON security_audit_log(table_name, operation);

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event()
RETURNS TRIGGER AS $$
DECLARE
  operation_type TEXT;
BEGIN
  -- Determine operation type
  IF TG_OP = 'INSERT' THEN
    operation_type := 'INSERT';
  ELSIF TG_OP = 'UPDATE' THEN
    operation_type := 'UPDATE';
  ELSIF TG_OP = 'DELETE' THEN
    operation_type := 'DELETE';
  END IF;
  
  -- Log the event
  INSERT INTO security_audit_log (
    user_id,
    table_name,
    operation,
    record_id,
    old_values,
    new_values,
    created_at
  ) VALUES (
    auth.uid(),
    TG_TABLE_NAME,
    operation_type,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) ELSE NULL END,
    NOW()
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add security audit triggers to sensitive tables
CREATE TRIGGER security_audit_trigger_categories
  AFTER INSERT OR UPDATE OR DELETE ON categories
  FOR EACH ROW EXECUTE FUNCTION log_security_event();

CREATE TRIGGER security_audit_trigger_accounts
  AFTER INSERT OR UPDATE OR DELETE ON accounts
  FOR EACH ROW EXECUTE FUNCTION log_security_event();

CREATE TRIGGER security_audit_trigger_expenses
  AFTER INSERT OR UPDATE OR DELETE ON expenses
  FOR EACH ROW EXECUTE FUNCTION log_security_event();

CREATE TRIGGER security_audit_trigger_budgets
  AFTER INSERT OR UPDATE OR DELETE ON budgets
  FOR EACH ROW EXECUTE FUNCTION log_security_event();

CREATE TRIGGER security_audit_trigger_financial_goals
  AFTER INSERT OR UPDATE OR DELETE ON financial_goals
  FOR EACH ROW EXECUTE FUNCTION log_security_event();

-- ========================================
-- DATA CLEANUP AND MAINTENANCE
-- ========================================

-- Function to clean up expired exports
CREATE OR REPLACE FUNCTION cleanup_expired_exports()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  UPDATE export_history 
  SET is_deleted = TRUE 
  WHERE expires_at < NOW() AND NOT is_deleted;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to permanently delete old audit logs (keep 1 year)
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM security_audit_log 
  WHERE created_at < NOW() - INTERVAL '1 year';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record this migration
INSERT INTO app_migrations (version, name, checksum) VALUES 
  (3, 'Implement comprehensive RLS policies and security audit', 'v3-rls-policies')
ON CONFLICT (version) DO NOTHING;