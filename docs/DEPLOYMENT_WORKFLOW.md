# Local to Remote Supabase Deployment Workflow

This guide covers the complete workflow for developing locally with Supabase and deploying to production.

## Overview

**The Development Flow:**
1. **Local Development** → Develop on local Supabase Docker instance
2. **Schema Sync** → Push database changes to remote Supabase
3. **App Deployment** → Deploy Flutter app pointing to remote Supabase
4. **Data Migration** (optional) → Migrate existing data if needed

---

## Part 1: Running Flutter App on Different Environments

### 🏠 **Local Development (Default)**

```bash
# Starts with local Docker Supabase automatically
flutter run
```

**Configuration**: Uses defaults in `lib/main.dart`:
- URL: `http://127.0.0.1:54321`
- Anon Key: Local development key

### 🌐 **Remote/Production Supabase**

#### Method 1: Environment Variables (Recommended)

1. **Create production config file:**
```bash
# Create .env.production
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key-from-supabase-dashboard
```

2. **Run with production config:**
```bash
# Load .env.production and run
flutter run --dart-define-from-file=.env.production
```

#### Method 2: Command Line Arguments

```bash
# Run with remote Supabase
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

#### Method 3: Build-time Configuration

```bash
# Build APK for production
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Build for different environments
flutter build apk --release --dart-define-from-file=.env.production
flutter build apk --debug --dart-define-from-file=.env.staging
```

---

## Part 2: Syncing Local Supabase to Remote

### 🔄 **Yes, it's possible!** Here's how:

### A. **Database Schema Sync (Migrations)**

#### **Setup Remote Project:**
```bash
# 1. Login to Supabase
supabase login

# 2. Create new remote project
supabase projects create "ExpenseTracker Production"

# 3. Link your local project to remote
supabase link --project-ref your-project-id

# 4. Verify link
supabase projects list
```

#### **Deploy Schema:**
```bash
# Preview changes (dry run)
supabase db diff --linked

# Deploy migrations to remote
supabase db push --linked

# Or use our script (recommended)
./scripts/deploy_schema_updates.sh
```

### B. **Edge Functions Sync**

```bash
# Deploy all functions
supabase functions deploy --linked

# Deploy specific function
supabase functions deploy function-name --linked
```

### C. **Configuration Sync**

```bash
# Deploy auth settings, storage buckets, etc.
supabase gen types typescript --linked > lib/supabase_types.dart
```

### D. **Data Migration (Optional)**

If you have test data locally that you want to migrate:

```bash
# 1. Export local data
supabase db dump --data-only > local_data.sql

# 2. Import to remote (be careful!)
supabase db reset --linked --restore=local_data.sql
```

⚠️ **Warning**: Data migration can overwrite production data. Always backup first!

---

## Part 3: Complete Development Workflow

### **Phase 1: Local Development**

1. **Start local environment:**
```bash
./scripts/supabase-docker.sh start
```

2. **Develop and test locally:**
```bash
flutter run  # Uses local Supabase automatically
```

3. **Create/modify migrations as needed:**
```bash
# Create new migration
supabase migration new add_new_feature

# Edit migration file in supabase/migrations/
# Apply locally
supabase db reset
```

4. **Run tests against local database:**
```bash
flutter test
./scripts/quality_check.sh
```

### **Phase 2: Schema Deployment**

1. **Preview changes:**
```bash
./scripts/deploy_schema_updates.sh --dry-run
```

2. **Deploy to remote:**
```bash
./scripts/deploy_schema_updates.sh
```

3. **Verify remote deployment:**
```bash
# Test remote connection
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co
```

### **Phase 3: App Deployment**

1. **Test against remote:**
```bash
flutter test --dart-define-from-file=.env.production
```

2. **Build for production:**
```bash
flutter build apk --release --dart-define-from-file=.env.production
```

3. **Deploy to app stores or distribution platform**

---

## Part 4: Environment Management

### **Environment Files Structure:**

```
.env.local          # Local Docker Supabase (optional override)
.env.development    # Development remote instance  
.env.staging        # Staging environment
.env.production     # Production environment
```

### **Example .env.production:**
```bash
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-prod-key
FLUTTER_ENV=production
DEBUG_MODE=false
```

### **Load Different Environments:**
```bash
# Local (default)
flutter run

# Development remote
flutter run --dart-define-from-file=.env.development

# Staging
flutter run --dart-define-from-file=.env.staging  

# Production
flutter run --dart-define-from-file=.env.production
```

---

## Part 5: Advanced Workflows

### **Multi-Environment Schema Management**

```bash
# Different remote environments
supabase link --project-ref dev-project-id
supabase db push --linked  # Deploy to dev

supabase link --project-ref staging-project-id  
supabase db push --linked  # Deploy to staging

supabase link --project-ref prod-project-id
supabase db push --linked  # Deploy to production
```

### **Automated CI/CD Pipeline**

```yaml
# .github/workflows/deploy.yml
name: Deploy to Supabase
on: 
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Supabase CLI
        run: |
          curl -fsSL https://cli.supabase.com/install.sh | sh
          supabase login --token ${{ secrets.SUPABASE_ACCESS_TOKEN }}
      - name: Deploy Schema
        run: |
          supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_ID }}
          supabase db push --linked
```

### **Data Synchronization Strategies**

1. **Schema Only (Recommended for Production):**
   - Only sync database structure
   - Keep production data separate

2. **Schema + Seed Data:**
   - Sync structure + initial/reference data
   - Good for staging environments

3. **Full Sync (Development Only):**
   - Sync everything including test data
   - Only for development/testing environments

---

## Part 6: Best Practices

### **🔒 Security**
- Never commit real API keys to git
- Use different keys for each environment
- Rotate keys regularly
- Enable RLS (Row Level Security) in production

### **🚀 Performance**
- Test with realistic data volumes
- Monitor query performance in production
- Use connection pooling for high traffic

### **🧪 Testing**
- Always test migrations on staging first
- Run integration tests against each environment
- Backup before any production deployment

### **📊 Monitoring**
- Monitor database performance
- Set up alerts for errors
- Track migration success/failure

---

## Part 7: Troubleshooting

### **Common Issues:**

1. **Migration Conflicts:**
```bash
# Reset remote to match local exactly
supabase db reset --linked
```

2. **Authentication Issues:**
```bash
# Re-authenticate
supabase logout
supabase login
```

3. **Schema Drift:**
```bash
# Generate migration from difference
supabase db diff --linked --file new_migration.sql
```

4. **Connection Issues:**
```bash
# Test connectivity
curl https://your-project.supabase.co/rest/v1/
```

---

## Commands Summary

### **Local Development:**
```bash
./scripts/supabase-docker.sh start    # Start local
flutter run                           # Run on local
```

### **Remote Deployment:**
```bash
supabase login                        # Authenticate
supabase link --project-ref ID        # Link project
./scripts/deploy_schema_updates.sh    # Deploy schema
```

### **Environment Switching:**
```bash
flutter run --dart-define-from-file=.env.production  # Remote
flutter run --dart-define-from-file=.env.local       # Local override
```

### **Testing:**
```bash
flutter test                                         # Local tests
flutter test --dart-define-from-file=.env.staging    # Remote tests
```

This workflow enables seamless development locally with easy deployment to production! 🚀