# Manual Migration Instructions

## Issue
The auto-provisioning system is detecting that tables don't exist because the Edge Function cannot execute arbitrary SQL due to missing RPC functions in Supabase.

## Solution: Manual Database Setup

### Step 1: Access Supabase SQL Editor
1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/ebitypkiwmttgcxwnyfq
2. Navigate to **SQL Editor** in the left sidebar
3. Click **"New Query"**

### Step 2: Run the Initial Schema Migration
Copy and paste the entire contents of `supabase/migrations/0001_initial_schema.sql` into the SQL editor and execute it.

The migration file contains:
- ✅ All required tables (categories, accounts, expenses, budgets, app_migrations)
- ✅ Sync-related fields (version, is_deleted, device_id, last_editor)
- ✅ Indexes for performance
- ✅ Row Level Security (RLS) policies
- ✅ Version bump triggers
- ✅ Helper functions for the app
- ✅ Default data (categories and accounts)

### Step 3: Verify Tables Were Created
After running the migration, go to **Table Editor** and confirm you see:
- `app_migrations` 
- `categories` (with default data)
- `accounts` (with default data)
- `expenses` 
- `budgets`

### Step 4: Test the App
Run your Flutter app with the Supabase credentials:
```bash
flutter run --dart-define=DATABASE_URL=https://ebitypkiwmttgcxwnyfq.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key_here -d chrome
```

The app should now:
- ✅ Connect to Supabase successfully
- ✅ Complete bootstrap without errors
- ✅ Load data from the database
- ✅ Support offline-first sync operations

## Why This Happened
- Supabase doesn't provide built-in RPC functions for executing arbitrary SQL
- Edge Functions need specific database functions to create tables programmatically
- The simpler approach is to run migrations manually through the dashboard

## Future Improvements
- Add authentication to restrict RLS policies to individual users
- Set up proper CI/CD for automated migrations
- Create a web-based migration runner for non-technical users