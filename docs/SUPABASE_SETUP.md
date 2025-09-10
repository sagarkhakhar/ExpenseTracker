# 🚀 Supabase Setup Guide

This guide provides simple, step-by-step instructions for setting up Supabase with the Expense Tracker application.

## ✨ Overview

The Expense Tracker now uses a **single, comprehensive migration** that:
- ✅ Works for fresh database setups
- ✅ Works for complete database resets  
- ✅ Resolves all security linter errors
- ✅ Is fully compliant with Supabase security guidelines
- ✅ Eliminates confusion from multiple migration files

## 🛠️ Prerequisites

- Supabase CLI installed (`npm install -g supabase`)
- Supabase project created at [supabase.com](https://supabase.com)
- Flutter development environment set up

## 📋 Setup Instructions

### Option 1: Fresh Database Setup (Recommended)

1. **Clone and Navigate to Project**
   ```bash
   cd ExpenseTracker
   ```

2. **Link to Your Supabase Project**
   ```bash
   supabase link --project-ref YOUR_PROJECT_ID
   ```

3. **Deploy the Complete Schema**
   ```bash
   supabase db push --linked
   ```

4. **Verify Setup**
   - Go to your Supabase Dashboard
   - Check Database > Tables - you should see all tables created
   - Run Database Linter - should show ✅ no errors

### Option 2: Complete Database Reset

If you have an existing database with issues:

1. **Reset Database** (⚠️ This deletes all data)
   ```bash
   supabase db reset --linked
   ```

2. **Push the Clean Schema**
   ```bash
   supabase db push --linked
   ```

### Option 3: Manual SQL Setup

If CLI doesn't work, use the Supabase Dashboard:

1. Go to **Supabase Dashboard → SQL Editor**
2. Copy the contents of `supabase/migrations/0001_complete_schema.sql`
3. Paste and **Execute** the SQL
4. Check the verification results at the bottom

## 🔒 Security Features

The new schema includes:

### ✅ Security Compliance
- **No SECURITY DEFINER views** - All views use standard permissions
- **RLS enabled** on all public tables with proper policies
- **Minimal SECURITY DEFINER functions** - Only where absolutely necessary
- **User data isolation** - Every user sees only their own data
- **Input validation** - CHECK constraints and proper data types

### 🛡️ Row Level Security (RLS) Policies

All user data is automatically isolated:
- **Expenses** - Users can only access their own expenses
- **Categories** - Users can access their own + shared system categories  
- **Accounts** - Users can only access their own accounts
- **Budgets** - Users can only access their own budgets
- **Goals** - Users can only access their own financial goals

### 📊 Default Categories

The schema automatically includes:
- **22 Expense categories** (Food, Transport, Entertainment, etc.)
- **8 Income categories** (Salary, Freelance, Business, etc.)
- **Custom icons and colors** for each category
- **Proper categorization** for income vs expense tracking

## 📱 App Configuration

### Environment Setup

The app supports multiple environments:

**Local Development** (default):
```bash
flutter run  # Uses local Supabase
```

**Production/Remote**:
```bash
flutter run --dart-define-from-file=.env.production
```

### Environment Files

Create these files in your project root:

**.env.local** (for local development):
```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_local_anon_key
```

**.env.production** (for remote):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
```

## 🧪 Testing the Setup

### 1. Database Verification
```bash
# Check if all tables exist
supabase db remote describe --linked

# Verify RLS policies
# Go to Dashboard → Authentication → Policies
```

### 2. App Testing
```bash
# Run the app locally
flutter run

# Run tests
flutter test

# Check for any linting issues
flutter analyze
```

### 3. Security Verification
- Go to **Supabase Dashboard → Database → Linter**  
- Should show ✅ **No security issues**
- All previous errors should be resolved

## 🔧 Troubleshooting

### Common Issues

**1. Migration Fails with "already exists" errors**
```bash
# Solution: Reset and start fresh
supabase db reset --linked
supabase db push --linked
```

**2. Authentication errors**
```bash
# Check your project is linked correctly
supabase projects list
supabase link --project-ref YOUR_PROJECT_ID
```

**3. RLS Policy errors**
- Ensure you're authenticated in your app
- Check that user_id columns are properly set
- Verify RLS policies in Supabase Dashboard

**4. Security linter still showing errors**
- Wait 5-10 minutes for linter to refresh
- Try refreshing the Dashboard page
- Check if the migration completed successfully

### Getting Help

1. **Check the logs**: Look at migration output for any errors
2. **Verify in Dashboard**: Manually check tables and policies exist  
3. **Reset if needed**: Use `supabase db reset --linked` for a fresh start
4. **Run verification**: The migration includes verification queries at the end

## 🎯 What's Changed

### ✅ Improvements
- **Single migration file** instead of 11+ separate migrations
- **All security issues resolved** - fully compliant with Supabase guidelines
- **Better RLS policies** - comprehensive user data isolation
- **Performance optimized** - proper indexes for common queries
- **Default data included** - ready-to-use categories and setup

### 📁 File Organization
- `supabase/migrations/0001_complete_schema.sql` - **THE ONLY MIGRATION**
- `supabase/migrations/archive/` - Old migration files (for reference)
- `docs/SUPABASE_SETUP.md` - This setup guide

### 🗑️ What Was Removed
- 10+ redundant migration files
- Conflicting RLS policies  
- Insecure SECURITY DEFINER views/functions
- Confusing multi-step setup process

## 🎉 Success Indicators

You'll know the setup worked when:
- ✅ Supabase Database Linter shows **no security errors**
- ✅ Flutter app runs without database connection issues  
- ✅ Users can create expenses and they appear in the database
- ✅ All tables and policies exist in Supabase Dashboard
- ✅ Authentication and user data isolation works properly

---

**Need help?** Check the troubleshooting section above or create an issue in the project repository.