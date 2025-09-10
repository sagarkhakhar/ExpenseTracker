# Remote Supabase Setup Guide (Production/Hosted)

## Overview

This comprehensive guide provides step-by-step instructions for setting up a remote Supabase instance for production deployment of the ExpenseTracker Flutter application. This setup is essential for releasing your app to users and enables cloud-based data storage, authentication, and real-time features.

## Prerequisites

### Account Requirements
- **Supabase Account**: Free account at https://supabase.com
- **GitHub Account**: For repository hosting (recommended)
- **Domain/App Store Account**: For production deployment (optional)

### Technical Prerequisites
- Completed local development setup (see [DOCKER_SUPABASE_SETUP.md](./DOCKER_SUPABASE_SETUP.md))
- Working Flutter app with local Supabase integration
- Supabase CLI installed and configured
- Basic understanding of environment variables and deployment

## Step 1: Create Remote Supabase Project

### 1.1 Sign Up for Supabase

Visit https://supabase.com and create an account:
- **Option 1**: Sign up with email
- **Option 2**: Sign in with GitHub (recommended for easier integration)

### 1.2 Create New Project

1. **In Supabase Dashboard**:
   - Click "New Project"
   - Choose organization (personal or team)
   - Enter project details:
     - **Name**: ExpenseTracker (or your preferred name)
     - **Database Password**: Generate a strong password (save this!)
     - **Region**: Choose closest to your users
     - **Pricing Plan**: Start with Free tier (upgrade later if needed)

2. **Wait for Project Initialization** (~2-3 minutes):
   - Database setup
   - API endpoint configuration
   - Authentication service setup
   - Storage bucket creation

### 1.3 Get Project Credentials

Once created, note these important values from your project settings:

```bash
# From Project Settings > API
Project URL: https://your-project-id.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Service Role Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# From Project Settings > General  
Project Reference ID: your-project-id
Database Password: [password you set]
```

**⚠️ IMPORTANT**: Store these credentials securely. Never commit them to version control!

## Step 2: Link Local Project to Remote

### 2.1 Authenticate with Supabase CLI

```bash
# Login to your Supabase account
supabase login

# This will open browser for authentication
# Follow the prompts to complete login
```

### 2.2 Link Your Project

```bash
# Navigate to your project directory
cd /path/to/ExpenseTracker

# Link to your remote project
supabase link --project-ref your-project-id

# You'll be prompted for your database password
# Enter the password you created in Step 1.2
```

### 2.3 Verify Connection

```bash
# Check project status
supabase status

# Should show both local and remote configurations
# Remote should show your production URL
```

## Step 3: Deploy Database Schema

### 3.1 Review Local Schema

Before deploying, ensure your local schema is stable:

```bash
# Check current migrations
ls supabase/migrations/

# Test locally first
supabase db reset
flutter test
```

### 3.2 Deploy Schema to Remote

```bash
# Option 1: Use our automated deployment script
./scripts/deploy_schema_updates.sh

# Option 2: Manual deployment
supabase db push --linked

# Option 3: Deploy specific migrations only
supabase db push --linked --version=0002
```

**What this deploys:**
- All database tables (expenses, categories, accounts, budgets)
- Row Level Security (RLS) policies
- User authentication functions
- Storage buckets and policies
- Database indexes for performance

### 3.3 Verify Deployment

```bash
# Check remote database status
supabase db status --linked

# View deployed schema in Supabase Dashboard:
# https://your-project-id.supabase.co/project/your-project-id/editor
```

## Step 4: Configure Authentication

### 4.1 Set Authentication Providers

In your Supabase Dashboard, go to **Authentication > Providers**:

1. **Email Authentication** (Enabled by default):
   - ✅ Enable email confirmations
   - ✅ Enable password recovery
   - Set custom email templates if desired

2. **Additional Providers** (Optional):
   - Google OAuth
   - Apple Sign In
   - GitHub OAuth
   - Configure redirect URLs for each

### 4.2 Configure Auth Settings

In **Authentication > Settings**:

```bash
# Site URL (your app's URL)
Site URL: io.expensetracker://auth/callback

# Additional Redirect URLs
Redirect URLs:
- io.expensetracker://auth/callback
- https://your-app-domain.com/auth/callback
- http://localhost:3000  # For web testing
```

### 4.3 Set Up Email Templates

In **Authentication > Email Templates**:

1. **Confirmation Email**:
   - Customize subject and content
   - Add your app branding
   - Test email delivery

2. **Password Recovery**:
   - Customize reset email template
   - Ensure secure reset flow

## Step 5: Configure Storage

### 5.1 Create Storage Buckets

Execute in Supabase SQL Editor:

```sql
-- Create bucket for receipt photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts', 
  false,
  52428800,  -- 50MB limit
  '{"image/jpeg", "image/png", "image/webp", "application/pdf"}'
);
```

### 5.2 Set Up Storage Policies

```sql
-- Receipt upload policy (users can upload their own receipts)
CREATE POLICY "Users can upload their own receipts" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'receipts' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Receipt access policy (users can access their own receipts)  
CREATE POLICY "Users can view their own receipts" ON storage.objects
FOR SELECT USING (
  bucket_id = 'receipts' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Receipt delete policy
CREATE POLICY "Users can delete their own receipts" ON storage.objects  
FOR DELETE USING (
  bucket_id = 'receipts' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### 5.3 Test Storage Upload

```bash
# Test file upload via CLI
supabase storage cp ./test-image.jpg receipts/test/image.jpg --linked

# Verify in dashboard: Storage > receipts bucket
```

## Step 6: Configure Flutter App for Remote

### 6.1 Create Production Environment File

```bash
# Create production environment configuration
cat > .env.production << EOF
# Remote Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key

# Environment
ENVIRONMENT=production
DEBUG_MODE=false

# Optional: Analytics, Crashlytics, etc.
ENABLE_ANALYTICS=true
EOF
```

### 6.2 Update Flutter Configuration

Ensure your app can read environment variables. Check `lib/main.dart` for:

```dart
// Environment configuration should look like this:
final supabaseUrl = const String.fromEnvironment(
  'SUPABASE_URL', 
  defaultValue: 'http://127.0.0.1:54321' // Local fallback
);

final supabaseAnonKey = const String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'local-development-key'
);
```

### 6.3 Test Remote Connection

```bash
# Run app with production configuration
flutter run --dart-define-from-file=.env.production

# Test core features:
# 1. User registration/login
# 2. Create expense (test data sync)
# 3. Upload receipt photo
# 4. Real-time sync between devices
```

## Step 7: Environment Management

### 7.1 Create Multiple Environment Files

```bash
# Development (remote dev instance)
cat > .env.development << EOF
SUPABASE_URL=https://dev-project-id.supabase.co
SUPABASE_ANON_KEY=dev-anon-key
ENVIRONMENT=development
EOF

# Staging (testing environment)
cat > .env.staging << EOF
SUPABASE_URL=https://staging-project-id.supabase.co
SUPABASE_ANON_KEY=staging-anon-key
ENVIRONMENT=staging
EOF

# Production (live environment)
cat > .env.production << EOF
SUPABASE_URL=https://prod-project-id.supabase.co
SUPABASE_ANON_KEY=prod-anon-key
ENVIRONMENT=production
EOF
```

### 7.2 Build Commands for Each Environment

```bash
# Local development (default - uses Docker Supabase)
flutter run

# Development environment
flutter run --dart-define-from-file=.env.development

# Staging environment
flutter run --dart-define-from-file=.env.staging

# Production environment
flutter run --dart-define-from-file=.env.production

# Production builds
flutter build apk --release --dart-define-from-file=.env.production
flutter build ios --release --dart-define-from-file=.env.production
flutter build web --release --dart-define-from-file=.env.production
```

## Step 8: Set Up Continuous Deployment

### 8.1 GitHub Actions for Schema Deployment

Create `.github/workflows/deploy-schema.yml`:

```yaml
name: Deploy Schema to Supabase

on:
  push:
    branches: [main]
    paths: ['supabase/migrations/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Supabase CLI
      uses: supabase/setup-cli@v1
      with:
        version: latest
        
    - name: Deploy to Supabase
      run: supabase db push --linked
      env:
        SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
        SUPABASE_PROJECT_ID: ${{ secrets.SUPABASE_PROJECT_ID }}
```

### 8.2 Set Up GitHub Secrets

In your GitHub repository settings, add these secrets:

```bash
SUPABASE_ACCESS_TOKEN=your-access-token
SUPABASE_PROJECT_ID=your-project-id
SUPABASE_DB_PASSWORD=your-database-password
```

## Step 9: Data Migration (Optional)

If you have existing local data to migrate:

### 9.1 Export Local Data

```bash
# Export from local Supabase
supabase db dump --data-only > local_data.sql
```

### 9.2 Import to Remote

```bash
# Import to remote (after schema deployment)
psql "postgresql://postgres:[password]@db.[project-id].supabase.co:5432/postgres" < local_data.sql
```

### 9.3 Verify Migration

```bash
# Check data counts match
supabase db shell --linked
SELECT COUNT(*) FROM expenses;
SELECT COUNT(*) FROM categories;  
\q
```

## Step 10: Monitoring and Maintenance

### 10.1 Set Up Monitoring

**In Supabase Dashboard:**

1. **Database Health**:
   - Monitor query performance in "Logs" tab
   - Set up alerts for slow queries
   - Track storage usage

2. **Authentication Metrics**:
   - Monitor user sign-ups/logins
   - Track authentication errors
   - Review security incidents

3. **API Usage**:
   - Monitor API request rates
   - Track quota usage
   - Set up billing alerts

### 10.2 Regular Maintenance Tasks

```bash
# Weekly tasks:

# 1. Backup database
supabase db dump --linked --data-only > backup-$(date +%Y%m%d).sql

# 2. Check for schema drift  
supabase db diff --linked --schema public

# 3. Monitor performance
supabase logs --linked --level error

# 4. Update dependencies
flutter pub upgrade
supabase migration repair
```

### 10.3 Scaling Considerations

**When to Upgrade Plans:**
- Database storage > 500MB (Free tier limit)
- Monthly active users > 50,000
- API requests > 2M/month
- Need for advanced features (Point-in-Time Recovery, etc.)

**Performance Optimization:**
```sql
-- Add database indexes for frequently queried fields
CREATE INDEX idx_expenses_user_date ON expenses(user_id, date DESC);
CREATE INDEX idx_expenses_category ON expenses(category_id);
CREATE INDEX idx_expenses_search ON expenses USING GIN (to_tsvector('english', title || ' ' || description));
```

## Troubleshooting Remote Setup

### Common Issues and Solutions

#### 1. Migration Deployment Failures

```bash
# Check for schema conflicts
supabase db diff --linked

# Reset remote to match local (CAREFUL: data loss)
supabase db reset --linked

# Deploy specific migration
supabase db push --linked --version=0003
```

#### 2. Authentication Issues

```bash
# Verify redirect URLs in Supabase Dashboard
# Check Authentication > URL Configuration

# Test auth flow
curl -X POST 'https://your-project-id.supabase.co/auth/v1/signup' \
  -H 'Content-Type: application/json' \
  -H 'apikey: your-anon-key' \
  -d '{"email": "test@example.com", "password": "password123"}'
```

#### 3. Storage Upload Failures

```sql
-- Check storage policies
SELECT * FROM pg_policies WHERE schemaname = 'storage';

-- Verify bucket configuration
SELECT * FROM storage.buckets WHERE name = 'receipts';
```

#### 4. Real-time Sync Issues

```bash
# Check RLS policies
SELECT schemaname, tablename, policyname, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public';

# Test real-time connection
curl -H "Authorization: Bearer your-anon-key" \
     "https://your-project-id.supabase.co/realtime/v1/websocket"
```

## Security Best Practices

### 1. Environment Variable Management
- Never commit `.env.*` files to version control
- Use CI/CD secrets for deployment
- Rotate API keys regularly
- Use separate keys for different environments

### 2. Database Security
- Enable Row Level Security on all tables
- Regularly audit RLS policies
- Monitor for unusual query patterns
- Keep database updated

### 3. API Security
- Rate limiting enabled by default
- Monitor API usage patterns
- Set up alerts for unusual activity
- Use service role key sparingly

## Cost Management

### Free Tier Limits (as of 2024)
- **Database**: 500MB storage
- **Auth**: 50,000 monthly active users  
- **Storage**: 1GB
- **Edge Functions**: 500K function invocations
- **Realtime**: 200 concurrent connections

### Optimization Tips
```sql
-- Monitor database size
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Clean up old data periodically
DELETE FROM expenses WHERE created_at < NOW() - INTERVAL '2 years';
```

## What the App Does Automatically (Remote Setup)

### Auto-Configuration Features

When you run the Flutter app with remote Supabase:

1. **Connection Management**:
   - Automatically connects to remote URL from environment
   - Handles SSL/TLS encryption for secure communication
   - Manages connection pooling and retries

2. **Authentication Integration**:
   - JWT token management with automatic refresh
   - Secure storage of authentication credentials
   - Real-time auth state synchronization

3. **Data Synchronization**:
   - Bidirectional sync between local Hive and remote Supabase
   - Conflict resolution using Last-Write-Wins strategy
   - Offline queue management for reliable data transfer

4. **Real-time Updates**:
   - WebSocket connections for live data updates
   - Push notifications for data changes (when implemented)
   - Multi-device synchronization

### Manual Configuration Required

Users still need to:

1. **Initial Authentication**: Register/login through the app
2. **Profile Setup**: Complete user profile information
3. **Data Migration**: Move existing local data (if desired)
4. **Push Notifications**: Configure device tokens (if implementing)
5. **Premium Features**: Subscribe to paid plans if needed

## Next Steps After Remote Setup

1. **App Store Preparation**:
   - Update app metadata with cloud features
   - Test on physical devices with production backend
   - Prepare app store screenshots and descriptions

2. **User Acceptance Testing**:
   - Beta test with remote backend
   - Verify performance under load
   - Test offline-to-online sync scenarios

3. **Production Launch**:
   - Deploy to app stores with production configuration
   - Monitor initial user adoption
   - Set up crash reporting and analytics

4. **Post-Launch**:
   - Regular database maintenance
   - Feature flag management
   - A/B testing setup
   - Performance optimization

## Resources and Documentation

- **Supabase Documentation**: https://supabase.com/docs
- **Flutter Supabase Package**: https://pub.dev/packages/supabase_flutter
- **Production Checklist**: https://supabase.com/docs/guides/platform/going-into-prod
- **Monitoring Guide**: https://supabase.com/docs/guides/platform/logs
- **Backup and Recovery**: https://supabase.com/docs/guides/platform/backups

---

**Need Help?**
- Supabase Community Discord: https://discord.supabase.com
- GitHub Issues: https://github.com/supabase/supabase/issues
- Support Portal: https://supabase.com/support (Pro plans)

**Security Issues?**
- Report security vulnerabilities: security@supabase.com
- Review security best practices regularly
- Subscribe to Supabase security updates