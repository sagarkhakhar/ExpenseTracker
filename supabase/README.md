# Supabase Setup for Offline-First Expense Tracker

This directory contains the Supabase configuration for the offline-first expense tracker.

## Structure

- `functions/bootstrap/index.ts` - Edge Function for auto-provisioning database schema
- `migrations/0001_initial_schema.sql` - Initial database migration
- `config.toml` - Local development configuration

## Setup Instructions

### 1. Install Supabase CLI

```bash
npm install -g @supabase/cli
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Initialize Local Development

From the project root directory:

```bash
supabase init
```

### 4. Start Local Development Server

```bash
supabase start
```

This will start:
- PostgreSQL database on port 54322
- Supabase API on port 54321
- Supabase Studio on port 54323

### 5. Apply Initial Migration

```bash
supabase db reset
```

### 6. Deploy Edge Function (Optional for local dev)

```bash
supabase functions deploy bootstrap
```

## Environment Variables

### For Local Development

The Supabase CLI will automatically provide:
- `DATABASE_URL` - Local API URL (http://localhost:54321)
- `SUPABASE_ANON_KEY` - Anonymous key for client access
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for admin operations

### For Production

Set these in your Supabase project dashboard:
- `DATABASE_URL` - Your project URL
- `SUPABASE_ANON_KEY` - Project anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Project service role key (for Edge Functions only)

## Edge Function: Bootstrap

The bootstrap function performs the following operations:

1. **Validation Mode** (`validate_only: true`)
   - Checks if migration is needed
   - Validates existing schema
   - Returns status without making changes

2. **Bootstrap Mode** (`validate_only: false`)
   - Creates `app_migrations` table for tracking
   - Applies Migration V1 if not already applied
   - Creates tables: `categories`, `accounts`, `expenses`, `budgets`
   - Sets up indexes for performance
   - Creates version bump triggers
   - Enables Row Level Security (RLS)
   - Creates basic RLS policies

### Usage from Flutter App

The Flutter app calls this function during startup:

```dart
final response = await Supabase.instance.client.functions.invoke(
  'bootstrap',
  body: {'validate_only': false},
);
```

### Response Format

```json
{
  "ok": true,
  "details": {
    "tables": ["categories", "accounts", "expenses", "budgets"],
    "rls": ["RLS enabled on all tables"],
    "triggers": ["Version bump triggers created"],
    "migrations": ["Migration V1 applied"],
    "errors": [],
    "warnings": []
  }
}
```

## Database Schema

### Sync Fields

All tables include these fields for offline-first sync:

- `id` - UUID primary key
- `created_at` - Timestamp when record was created
- `updated_at` - Timestamp when record was last updated (auto-updated)
- `version` - Integer version number (auto-incremented on updates)
- `is_deleted` - Soft delete flag for tombstone records
- `device_id` - ID of device that created/last modified the record
- `last_editor` - User/device identifier for conflict resolution

### Tables

1. **categories** - Expense categories with icons and colors
2. **accounts** - User accounts (cash, bank, etc.)
3. **expenses** - Individual expense records
4. **budgets** - Budget definitions and limits

## Offline-First Strategy

1. **Local First** - All writes go to Hive first
2. **Background Sync** - Periodic sync when online
3. **Conflict Resolution** - Last Write Wins (LWW) based on `version` and `updated_at`
4. **Tombstones** - Soft deletes with `is_deleted` flag
5. **Delta Sync** - Only sync records modified since last sync cursor

## Security

- Client uses only `SUPABASE_ANON_KEY`
- Server operations use `SUPABASE_SERVICE_ROLE_KEY` in Edge Functions
- RLS policies will be user-scoped when authentication is added
- All privileged operations go through Edge Functions

## Development Workflow

1. Make schema changes in migration files
2. Test locally with `supabase start`
3. Update Edge Function if needed
4. Deploy to staging/production
5. Test with Flutter app

## Troubleshooting

### Function Not Found
Ensure the Edge Function is deployed:
```bash
supabase functions list
supabase functions deploy bootstrap
```

### Migration Issues
Reset local database:
```bash
supabase db reset
```

### Permission Errors
Check that service role key is set in Edge Function environment.