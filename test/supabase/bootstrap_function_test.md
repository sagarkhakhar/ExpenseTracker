# Bootstrap Edge Function Test Plan

## Manual Testing

### Prerequisites
1. Supabase CLI installed: `npm install -g @supabase/cli`
2. Local Supabase running: `supabase start`
3. Bootstrap function deployed: `supabase functions deploy bootstrap`

### Test Cases

#### Test 1: Validation Mode
```bash
curl -X POST http://localhost:54321/functions/v1/bootstrap \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [SUPABASE_ANON_KEY]" \
  -d '{"validate_only": true}'
```

**Expected Response:**
- `ok: true` if schema is current
- `warnings: ["Migration V1 needs to be applied"]` if migration needed
- `details` object with current state

#### Test 2: Bootstrap Mode (Fresh Database)
```bash
curl -X POST http://localhost:54321/functions/v1/bootstrap \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [SUPABASE_ANON_KEY]" \
  -d '{"validate_only": false}'
```

**Expected Response:**
```json
{
  "ok": true,
  "details": {
    "tables": ["app_migrations (created)", "categories", "accounts", "expenses", "budgets"],
    "migrations": ["Migration V1 applied successfully"],
    "triggers": ["version bump triggers"],
    "rls": ["RLS status verified for main tables"],
    "errors": [],
    "warnings": []
  }
}
```

#### Test 3: Idempotency (Run Bootstrap Twice)
Run the bootstrap command again with same parameters.

**Expected Response:**
- `ok: true`
- `migrations: ["Migration V1 already applied"]`
- No errors about duplicate tables/triggers

#### Test 4: Database Validation
After successful bootstrap, verify tables exist:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('categories', 'accounts', 'expenses', 'budgets');

-- Check RLS enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('categories', 'accounts', 'expenses', 'budgets');

-- Check triggers exist
SELECT event_object_table, trigger_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name LIKE '%version_trigger';

-- Check migration recorded
SELECT * FROM app_migrations WHERE version = 1;
```

#### Test 5: Version Bump Trigger
```sql
-- Insert test category
INSERT INTO categories (name) VALUES ('Test Category');

-- Get initial version
SELECT id, name, version, updated_at FROM categories WHERE name = 'Test Category';

-- Update and check version incremented
UPDATE categories SET name = 'Updated Test Category' WHERE name = 'Test Category';

-- Verify version bumped and updated_at changed
SELECT id, name, version, updated_at FROM categories WHERE name = 'Updated Test Category';
```

**Expected:** Version should increment from 1 to 2, updated_at should be newer.

### Error Scenarios

#### Test 6: Invalid Request Method
```bash
curl -X GET http://localhost:54321/functions/v1/bootstrap
```
**Expected:** Method not allowed error

#### Test 7: Missing Environment Variables
Temporarily unset environment variables and test.
**Expected:** Error about missing required environment variables

#### Test 8: Invalid JSON
```bash
curl -X POST http://localhost:54321/functions/v1/bootstrap \
  -H "Content-Type: application/json" \
  -d '{"invalid_json":'
```
**Expected:** JSON parsing error

## Integration Testing

### Flutter App Integration
1. Configure Flutter app with local Supabase credentials
2. Start app and trigger startup validation
3. Verify StartupGuard reaches healthy state
4. Check diagnostic information shows successful bootstrap

### Expected Diagnostic Output
```dart
{
  'status': 'StartupStatus.healthy',
  'is_healthy': true,
  'config_valid': true,
  'network_connected': true,
  'network_reachable': true,
  'bootstrap_details': {
    'ok': true,
    'details': {
      'tables': [...],
      'migrations': [...]
    }
  }
}
```

## Performance Testing

### Response Times
- Validation mode: < 100ms
- Bootstrap mode (fresh): < 2000ms  
- Bootstrap mode (idempotent): < 500ms

### Concurrent Requests
Test multiple simultaneous bootstrap calls to ensure idempotency under concurrent access.

## Security Testing

### Access Control
- Verify anonymous key can call function
- Verify function uses service role key internally
- Test without apikey header (should fail)

### SQL Injection
Test malformed inputs to ensure Edge Function doesn't allow SQL injection.