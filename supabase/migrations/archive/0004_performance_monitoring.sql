-- Migration V4: Database performance optimization and monitoring
-- This migration adds performance monitoring, indexes, and maintenance procedures

-- Enable query performance tracking
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Create performance monitoring tables
CREATE TABLE IF NOT EXISTS query_performance_log (
  id SERIAL PRIMARY KEY,
  query_hash TEXT NOT NULL,
  query_text TEXT,
  user_id UUID,
  execution_time_ms FLOAT,
  rows_returned INTEGER,
  rows_affected INTEGER,
  table_accessed TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  query_plan JSONB
);

CREATE INDEX IF NOT EXISTS idx_query_performance_log_created_at ON query_performance_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_query_performance_log_user_id ON query_performance_log(user_id);
CREATE INDEX IF NOT EXISTS idx_query_performance_log_execution_time ON query_performance_log(execution_time_ms DESC);

-- Create connection pool monitoring table
CREATE TABLE IF NOT EXISTS connection_pool_stats (
  id SERIAL PRIMARY KEY,
  active_connections INTEGER,
  idle_connections INTEGER,
  total_connections INTEGER,
  max_connections INTEGER,
  connections_per_user JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_connection_pool_stats_created_at ON connection_pool_stats(created_at DESC);

-- Performance monitoring views
CREATE OR REPLACE VIEW slow_queries AS
SELECT 
  query_hash,
  query_text,
  COUNT(*) as execution_count,
  AVG(execution_time_ms) as avg_execution_time,
  MAX(execution_time_ms) as max_execution_time,
  SUM(rows_returned) as total_rows_returned,
  MAX(created_at) as last_execution
FROM query_performance_log 
WHERE execution_time_ms > 1000 -- Queries taking more than 1 second
GROUP BY query_hash, query_text
ORDER BY avg_execution_time DESC;

CREATE OR REPLACE VIEW user_query_stats AS
SELECT 
  user_id,
  COUNT(*) as total_queries,
  AVG(execution_time_ms) as avg_execution_time,
  SUM(rows_returned) as total_rows_returned,
  DATE_TRUNC('hour', created_at) as hour
FROM query_performance_log 
WHERE user_id IS NOT NULL
GROUP BY user_id, DATE_TRUNC('hour', created_at)
ORDER BY hour DESC, total_queries DESC;

-- Enhanced indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_expenses_user_date_amount 
ON expenses(user_id, date DESC, amount DESC) 
WHERE NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_expenses_user_category_date 
ON expenses(user_id, category_id, date DESC) 
WHERE NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_budgets_user_period 
ON budgets(user_id, period, start_date, end_date) 
WHERE NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_categories_user_name 
ON categories(user_id, name) 
WHERE NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_financial_goals_user_target_date 
ON financial_goals(user_id, target_date, is_achieved) 
WHERE NOT is_deleted;

-- Partial indexes for soft-deleted records
CREATE INDEX IF NOT EXISTS idx_expenses_deleted 
ON expenses(user_id, updated_at) 
WHERE is_deleted = true;

CREATE INDEX IF NOT EXISTS idx_categories_deleted 
ON categories(user_id, updated_at) 
WHERE is_deleted = true;

-- Composite indexes for sync operations
CREATE INDEX IF NOT EXISTS idx_expenses_sync 
ON expenses(user_id, updated_at, version) 
WHERE NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_categories_sync 
ON categories(user_id, updated_at, version) 
WHERE NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_accounts_sync 
ON accounts(user_id, updated_at, version) 
WHERE NOT is_deleted;

CREATE INDEX IF NOT EXISTS idx_budgets_sync 
ON budgets(user_id, updated_at, version) 
WHERE NOT is_deleted;

-- Function to collect query performance metrics
CREATE OR REPLACE FUNCTION log_query_performance()
RETURNS TRIGGER AS $$
DECLARE
  start_time TIMESTAMPTZ;
  execution_time FLOAT;
  query_info RECORD;
BEGIN
  -- This is a placeholder for query performance logging
  -- In a real implementation, you would capture query execution metrics
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to monitor connection pool
CREATE OR REPLACE FUNCTION monitor_connection_pool()
RETURNS VOID AS $$
DECLARE
  conn_stats RECORD;
BEGIN
  -- Get connection statistics
  SELECT 
    COUNT(*) FILTER (WHERE state = 'active') as active,
    COUNT(*) FILTER (WHERE state = 'idle') as idle,
    COUNT(*) as total,
    (SELECT setting::INTEGER FROM pg_settings WHERE name = 'max_connections') as max_conn
  INTO conn_stats
  FROM pg_stat_activity;
  
  -- Insert into monitoring table
  INSERT INTO connection_pool_stats (
    active_connections,
    idle_connections,
    total_connections,
    max_connections,
    connections_per_user
  ) VALUES (
    conn_stats.active,
    conn_stats.idle,
    conn_stats.total,
    conn_stats.max_conn,
    (
      SELECT json_object_agg(usename, conn_count)
      FROM (
        SELECT usename, COUNT(*) as conn_count
        FROM pg_stat_activity
        WHERE usename IS NOT NULL
        GROUP BY usename
      ) user_conns
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Table maintenance functions
CREATE OR REPLACE FUNCTION analyze_user_tables()
RETURNS TEXT AS $$
DECLARE
  table_name TEXT;
  result_text TEXT := '';
BEGIN
  -- Analyze all user tables for query optimization
  FOR table_name IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles', 'financial_goals')
  LOOP
    EXECUTE 'ANALYZE ' || table_name;
    result_text := result_text || 'Analyzed ' || table_name || E'\n';
  END LOOP;
  
  RETURN result_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vacuum maintenance function
CREATE OR REPLACE FUNCTION vacuum_user_tables()
RETURNS TEXT AS $$
DECLARE
  table_name TEXT;
  result_text TEXT := '';
BEGIN
  FOR table_name IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles', 'financial_goals')
  LOOP
    EXECUTE 'VACUUM ANALYZE ' || table_name;
    result_text := result_text || 'Vacuumed ' || table_name || E'\n';
  END LOOP;
  
  RETURN result_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get table statistics
CREATE OR REPLACE FUNCTION get_table_statistics()
RETURNS TABLE (
  table_name TEXT,
  total_rows BIGINT,
  total_size TEXT,
  index_size TEXT,
  last_vacuum TIMESTAMPTZ,
  last_analyze TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    schemaname || '.' || relname as table_name,
    n_tup_ins + n_tup_upd - n_tup_del as total_rows,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) as total_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||relname)) as index_size,
    last_vacuum,
    last_analyze
  FROM pg_stat_user_tables 
  WHERE schemaname = 'public'
    AND relname IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles', 'financial_goals')
  ORDER BY pg_total_relation_size(schemaname||'.'||relname) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to identify missing indexes
CREATE OR REPLACE FUNCTION suggest_missing_indexes()
RETURNS TABLE (
  table_name TEXT,
  columns_used TEXT,
  scan_count BIGINT,
  suggestion TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    schemaname || '.' || relname as table_name,
    'N/A' as columns_used,
    seq_scan as scan_count,
    CASE 
      WHEN seq_scan > idx_scan * 2 AND n_tup_ins + n_tup_upd + n_tup_del > 1000 
      THEN 'Consider adding indexes - high sequential scan ratio'
      WHEN seq_tup_read / NULLIF(seq_scan, 0) > 10000
      THEN 'Consider partitioning - large sequential reads'
      ELSE 'Table appears optimized'
    END as suggestion
  FROM pg_stat_user_tables 
  WHERE schemaname = 'public'
    AND relname IN ('categories', 'accounts', 'expenses', 'budgets', 'user_profiles', 'financial_goals')
  ORDER BY seq_scan DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create alerting function for performance issues
CREATE OR REPLACE FUNCTION check_performance_alerts()
RETURNS TABLE (
  alert_type TEXT,
  alert_message TEXT,
  severity TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  WITH alerts AS (
    -- Check for slow queries
    SELECT 
      'SLOW_QUERY' as alert_type,
      'Query taking ' || ROUND(avg_execution_time::NUMERIC, 2) || 'ms on average' as alert_message,
      CASE 
        WHEN avg_execution_time > 5000 THEN 'CRITICAL'
        WHEN avg_execution_time > 2000 THEN 'WARNING'
        ELSE 'INFO'
      END as severity,
      NOW() as created_at
    FROM slow_queries
    WHERE avg_execution_time > 1000
    
    UNION ALL
    
    -- Check connection pool usage
    SELECT 
      'HIGH_CONNECTIONS' as alert_type,
      'Active connections: ' || active_connections || '/' || max_connections as alert_message,
      CASE 
        WHEN active_connections::FLOAT / max_connections > 0.8 THEN 'CRITICAL'
        WHEN active_connections::FLOAT / max_connections > 0.6 THEN 'WARNING'
        ELSE 'INFO'
      END as severity,
      created_at
    FROM connection_pool_stats 
    WHERE created_at > NOW() - INTERVAL '1 hour'
    ORDER BY created_at DESC 
    LIMIT 1
    
    UNION ALL
    
    -- Check for tables needing maintenance
    SELECT 
      'TABLE_MAINTENANCE' as alert_type,
      'Table ' || schemaname || '.' || relname || ' needs vacuum (dead tuples: ' || n_dead_tup || ')' as alert_message,
      CASE 
        WHEN n_dead_tup > 10000 THEN 'WARNING'
        ELSE 'INFO'
      END as severity,
      NOW() as created_at
    FROM pg_stat_user_tables 
    WHERE n_dead_tup > 1000 
      AND schemaname = 'public'
  )
  SELECT * FROM alerts
  ORDER BY 
    CASE severity 
      WHEN 'CRITICAL' THEN 1 
      WHEN 'WARNING' THEN 2 
      ELSE 3 
    END,
    created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Automated maintenance scheduling (requires pg_cron extension)
-- Note: This would typically be set up at the database level by administrators
-- CREATE EXTENSION IF NOT EXISTS pg_cron;
-- SELECT cron.schedule('analyze-tables', '0 2 * * *', 'SELECT analyze_user_tables();');
-- SELECT cron.schedule('connection-monitor', '*/5 * * * *', 'SELECT monitor_connection_pool();');

-- Create maintenance log table
CREATE TABLE IF NOT EXISTS maintenance_log (
  id SERIAL PRIMARY KEY,
  operation TEXT NOT NULL,
  status TEXT NOT NULL, -- 'SUCCESS', 'ERROR', 'PARTIAL'
  details TEXT,
  execution_time_ms FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_maintenance_log_created_at ON maintenance_log(created_at DESC);

-- Function to log maintenance operations
CREATE OR REPLACE FUNCTION log_maintenance_operation(
  operation_name TEXT,
  operation_status TEXT,
  operation_details TEXT DEFAULT NULL,
  execution_time FLOAT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO maintenance_log (operation, status, details, execution_time_ms)
  VALUES (operation_name, operation_status, operation_details, execution_time);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on performance monitoring tables
ALTER TABLE query_performance_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE connection_pool_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_log ENABLE ROW LEVEL SECURITY;

-- RLS policies for monitoring tables (service role access)
CREATE POLICY "Service role can access query performance log" ON query_performance_log
  FOR ALL TO service_role USING (true);

CREATE POLICY "Service role can access connection pool stats" ON connection_pool_stats
  FOR ALL TO service_role USING (true);

CREATE POLICY "Service role can access maintenance log" ON maintenance_log
  FOR ALL TO service_role USING (true);

-- Create database health dashboard view
CREATE OR REPLACE VIEW database_health_dashboard AS
WITH 
  table_stats AS (
    SELECT * FROM get_table_statistics()
  ),
  recent_alerts AS (
    SELECT * FROM check_performance_alerts()
    WHERE created_at > NOW() - INTERVAL '24 hours'
  ),
  connection_health AS (
    SELECT 
      active_connections,
      total_connections,
      max_connections,
      ROUND((active_connections::FLOAT / max_connections * 100)::NUMERIC, 2) as connection_usage_percent
    FROM connection_pool_stats 
    ORDER BY created_at DESC 
    LIMIT 1
  )
SELECT 
  'Database Health Dashboard' as dashboard_name,
  NOW() as generated_at,
  (SELECT json_agg(to_json(t)) FROM table_stats t) as table_statistics,
  (SELECT json_agg(to_json(a)) FROM recent_alerts a) as recent_alerts,
  (SELECT to_json(c) FROM connection_health c) as connection_status;

-- Record this migration
INSERT INTO app_migrations (version, name, checksum) VALUES 
  (4, 'Performance monitoring and database optimization', 'v4-performance-monitoring')
ON CONFLICT (version) DO NOTHING;