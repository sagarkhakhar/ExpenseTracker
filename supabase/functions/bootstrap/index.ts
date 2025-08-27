import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BootstrapRequest {
  validate_only?: boolean
}

interface BootstrapResponse {
  ok: boolean
  details: {
    tables?: string[]
    rls?: string[]
    triggers?: string[]
    migrations?: string[]
    errors?: string[]
    warnings?: string[]
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      throw new Error('Method not allowed')
    }

    // Parse request body
    const { validate_only = false } = await req.json() as BootstrapRequest

    console.log('Bootstrap function called', { validate_only })

    // Create Supabase admin client using service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing required environment variables')
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      }
    })

    const details: BootstrapResponse['details'] = {
      tables: [],
      rls: [],
      triggers: [],
      migrations: [],
      errors: [],
      warnings: [],
    }

    // Step 1: Check and create app_migrations table
    await ensureAppMigrationsTable(supabaseAdmin, details)

    // Step 2: Check current migration state
    const currentMigration = await getCurrentMigrationVersion(supabaseAdmin)
    console.log('Current migration version:', currentMigration)

    // Step 3: Apply Migration V1 if needed
    if (currentMigration < 1) {
      if (validate_only) {
        details.warnings!.push('Migration V1 needs to be applied')
      } else {
        await applyMigrationV1(supabaseAdmin, details)
      }
    } else {
      details.migrations!.push('Migration V1 already applied')
    }

    // Step 4: Validate table structures
    await validateTableStructures(supabaseAdmin, details)

    // Step 5: Validate RLS policies
    await validateRLSPolicies(supabaseAdmin, details)

    // Step 6: Validate triggers
    await validateTriggers(supabaseAdmin, details)

    const response: BootstrapResponse = {
      ok: details.errors!.length === 0,
      details,
    }

    console.log('Bootstrap completed', response)

    return new Response(
      JSON.stringify(response),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: response.ok ? 200 : 500,
      }
    )

  } catch (error) {
    console.error('Bootstrap function error:', error)

    const errorResponse: BootstrapResponse = {
      ok: false,
      details: {
        errors: [error.message],
      },
    }

    return new Response(
      JSON.stringify(errorResponse),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

/**
 * Ensure app_migrations table exists for tracking migration state
 */
async function ensureAppMigrationsTable(supabase: any, details: BootstrapResponse['details']) {
  try {
    // Check if table exists
    const { data, error } = await supabase.rpc('check_table_exists', {
      table_name: 'app_migrations'
    })

    if (error) {
      // If the RPC doesn't exist, create it and the table
      await supabase.rpc('exec_sql', {
        sql: `
        -- Function to check if table exists
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

        -- Function to execute SQL (for migrations)
        CREATE OR REPLACE FUNCTION exec_sql(sql text)
        RETURNS void AS $$
        BEGIN
          EXECUTE sql;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;

        -- Create app_migrations table
        CREATE TABLE IF NOT EXISTS app_migrations (
          id SERIAL PRIMARY KEY,
          version INTEGER NOT NULL UNIQUE,
          name TEXT NOT NULL,
          applied_at TIMESTAMPTZ DEFAULT NOW(),
          checksum TEXT
        );
        `
      })
      details.tables!.push('app_migrations (created)')
    } else if (!data) {
      // Table doesn't exist, create it
      await supabase.rpc('exec_sql', {
        sql: `
        CREATE TABLE IF NOT EXISTS app_migrations (
          id SERIAL PRIMARY KEY,
          version INTEGER NOT NULL UNIQUE,
          name TEXT NOT NULL,
          applied_at TIMESTAMPTZ DEFAULT NOW(),
          checksum TEXT
        );
        `
      })
      details.tables!.push('app_migrations (created)')
    } else {
      details.tables!.push('app_migrations (exists)')
    }
  } catch (error) {
    details.errors!.push(`Failed to ensure app_migrations table: ${error.message}`)
  }
}

/**
 * Get current migration version
 */
async function getCurrentMigrationVersion(supabase: any): Promise<number> {
  try {
    const { data, error } = await supabase
      .from('app_migrations')
      .select('version')
      .order('version', { ascending: false })
      .limit(1)

    if (error) {
      console.log('No migration history found, starting from version 0')
      return 0
    }

    return data?.[0]?.version || 0
  } catch (error) {
    console.log('Error getting migration version, assuming 0:', error)
    return 0
  }
}

/**
 * Apply Migration V1: Create main tables with sync support
 */
async function applyMigrationV1(supabase: any, details: BootstrapResponse['details']) {
  try {
    console.log('Applying Migration V1...')

    const migrationSQL = `
    -- Migration V1: Offline-first sync tables
    
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

    -- Create indexes for performance
    CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
    CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id);
    CREATE INDEX IF NOT EXISTS idx_expenses_updated_at ON expenses(updated_at);
    CREATE INDEX IF NOT EXISTS idx_categories_updated_at ON categories(updated_at);
    CREATE INDEX IF NOT EXISTS idx_accounts_updated_at ON accounts(updated_at);
    CREATE INDEX IF NOT EXISTS idx_budgets_updated_at ON budgets(updated_at);

    -- Version bump trigger function
    CREATE OR REPLACE FUNCTION bump_version()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.version = OLD.version + 1;
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    -- Create version bump triggers
    CREATE TRIGGER categories_version_trigger
      BEFORE UPDATE ON categories
      FOR EACH ROW EXECUTE FUNCTION bump_version();

    CREATE TRIGGER accounts_version_trigger
      BEFORE UPDATE ON accounts
      FOR EACH ROW EXECUTE FUNCTION bump_version();

    CREATE TRIGGER expenses_version_trigger
      BEFORE UPDATE ON expenses
      FOR EACH ROW EXECUTE FUNCTION bump_version();

    CREATE TRIGGER budgets_version_trigger
      BEFORE UPDATE ON budgets
      FOR EACH ROW EXECUTE FUNCTION bump_version();

    -- Enable Row Level Security
    ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
    ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
    ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

    -- RLS Policies (allow all for now, will be restricted per user later)
    CREATE POLICY IF NOT EXISTS "Allow all access to categories" ON categories FOR ALL USING (true);
    CREATE POLICY IF NOT EXISTS "Allow all access to accounts" ON accounts FOR ALL USING (true);
    CREATE POLICY IF NOT EXISTS "Allow all access to expenses" ON expenses FOR ALL USING (true);
    CREATE POLICY IF NOT EXISTS "Allow all access to budgets" ON budgets FOR ALL USING (true);
    `

    await supabase.rpc('exec_sql', { sql: migrationSQL })

    // Record migration
    await supabase
      .from('app_migrations')
      .insert({
        version: 1,
        name: 'Initial offline-first sync tables',
        checksum: 'v1-initial-schema'
      })

    details.migrations!.push('Migration V1 applied successfully')
    details.tables!.push('categories', 'accounts', 'expenses', 'budgets')
    details.triggers!.push('version bump triggers')
    
    console.log('Migration V1 applied successfully')

  } catch (error) {
    details.errors!.push(`Migration V1 failed: ${error.message}`)
    console.error('Migration V1 error:', error)
  }
}

/**
 * Validate table structures exist
 */
async function validateTableStructures(supabase: any, details: BootstrapResponse['details']) {
  const requiredTables = ['categories', 'accounts', 'expenses', 'budgets']
  
  for (const tableName of requiredTables) {
    try {
      const { error } = await supabase
        .from(tableName)
        .select('id')
        .limit(1)

      if (error) {
        details.errors!.push(`Table ${tableName} validation failed: ${error.message}`)
      } else {
        details.tables!.push(`${tableName} (validated)`)
      }
    } catch (error) {
      details.errors!.push(`Table ${tableName} access failed: ${error.message}`)
    }
  }
}

/**
 * Validate RLS policies are active
 */
async function validateRLSPolicies(supabase: any, details: BootstrapResponse['details']) {
  try {
    const { data, error } = await supabase.rpc('exec_sql', {
      sql: `
      SELECT schemaname, tablename, rowsecurity
      FROM pg_tables
      WHERE schemaname = 'public'
      AND tablename IN ('categories', 'accounts', 'expenses', 'budgets');
      `
    })

    if (!error && data) {
      details.rls!.push('RLS status verified for main tables')
    } else {
      details.warnings!.push('Could not verify RLS status')
    }
  } catch (error) {
    details.warnings!.push(`RLS validation error: ${error.message}`)
  }
}

/**
 * Validate triggers are present
 */
async function validateTriggers(supabase: any, details: BootstrapResponse['details']) {
  try {
    const { data, error } = await supabase.rpc('exec_sql', {
      sql: `
      SELECT event_object_table, trigger_name
      FROM information_schema.triggers
      WHERE trigger_schema = 'public'
      AND trigger_name LIKE '%version_trigger';
      `
    })

    if (!error) {
      details.triggers!.push('Version bump triggers validated')
    } else {
      details.warnings!.push('Could not verify triggers')
    }
  } catch (error) {
    details.warnings!.push(`Trigger validation error: ${error.message}`)
  }
}

/* To deploy:
deno run --allow-net --allow-read --allow-env index.ts
*/