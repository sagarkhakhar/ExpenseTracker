# Local Supabase Setup Guide (Docker-Based)

## Overview

This comprehensive guide provides step-by-step instructions for setting up Supabase locally using Docker for the ExpenseTracker Flutter application. Perfect for new users starting from scratch, this setup enables full-featured development without relying on remote services.

## Prerequisites

### System Requirements
- **Operating System**: macOS, Linux, or Windows with WSL2
- **RAM**: Minimum 4GB, recommended 8GB+
- **Storage**: At least 2GB free space for Docker containers
- **Docker Desktop**: Version 4.0+
- **Flutter**: Version 3.0+
- **Dart**: Version 3.0+

### Required Software Installation

#### 1. Install Docker Desktop

**macOS:**
```bash
# Using Homebrew (recommended)
brew install --cask docker

# OR download from https://www.docker.com/products/docker-desktop/
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install docker.io docker-compose
sudo usermod -aG docker $USER
# Log out and log back in for group changes to take effect
```

**Windows:**
- Download Docker Desktop from https://www.docker.com/products/docker-desktop/
- Enable WSL2 integration during installation
- Ensure WSL2 is set as default

#### 2. Install Supabase CLI

**macOS:**
```bash
brew install supabase/tap/supabase
```

**Linux:**
```bash
# Using npm (requires Node.js)
npm install -g @supabase/cli

# OR using direct download
curl -sSL https://api.github.com/repos/supabase/cli/releases/latest \
  | jq -r '.assets[].browser_download_url' \
  | grep 'linux-amd64' \
  | head -1 \
  | xargs curl -sSL -o supabase.tar.gz
tar -xzf supabase.tar.gz
sudo mv supabase /usr/local/bin/
```

**Windows (WSL2):**
```bash
# Same as Linux instructions above, or use npm
npm install -g @supabase/cli
```

#### 3. Install Flutter (if not already installed)

**macOS:**
```bash
# Using Homebrew
brew install --cask flutter

# OR download from https://flutter.dev/docs/get-started/install
```

**Linux/Windows:**
- Follow instructions at https://flutter.dev/docs/get-started/install
- Ensure Flutter is in your PATH

#### 4. Verify All Installations

```bash
# Check Docker (should show version info)
docker --version
docker-compose --version

# Check Supabase CLI  
supabase --version

# Check Flutter (should show no issues)
flutter doctor

# Check if Docker is running
docker info
```

## Project Setup

### 1. Clone the ExpenseTracker Project

```bash
# Clone the repository (replace with actual repo URL)
git clone https://github.com/your-username/ExpenseTracker.git
cd ExpenseTracker

# OR if you already have the project
cd path/to/ExpenseTracker
```

### 2. Install Flutter Dependencies

```bash
# Download all Flutter dependencies
flutter pub get

# Verify everything is working
flutter doctor
```

### 3. Set Up Local Supabase

#### Option A: Automated Setup (Recommended for Beginners)

```bash
# Make the script executable (first time only)
chmod +x ./scripts/supabase-docker.sh

# Run complete automated setup
./scripts/supabase-docker.sh setup
```

**What this automation does:**
- ✅ Checks all prerequisites (Docker, CLI, etc.)
- ✅ Initializes Supabase project configuration
- ✅ Pulls and starts all Docker containers
- ✅ Applies database schema migrations
- ✅ Sets up authentication system
- ✅ Configures file storage for receipts
- ✅ Tests all connections
- ✅ Shows you connection details

#### Option B: Step-by-Step Manual Setup

**Step 1: Initialize Supabase (if not already done)**
```bash
# Only run this if supabase/ folder doesn't exist
supabase init

# This creates the supabase/ folder structure with:
# - config.toml (configuration file)
# - migrations/ (database schema files) 
# - functions/ (edge functions)
```

**Step 2: Start Docker Services**
```bash
# Start all Supabase services using Docker
supabase start

# This command will:
# - Pull required Docker images (first time ~500MB download)
# - Start PostgreSQL database
# - Start PostgREST API server
# - Start GoTrue authentication service
# - Start Realtime WebSocket service
# - Start file storage service
# - Start Supabase Studio (web interface)
# - Start email testing service (Inbucket)
```

**Step 3: Apply Database Schema**
```bash
# Apply the stable database migrations
supabase db reset --version=0002 --no-seed

# This applies these migration files:
# - 0001_initial_schema.sql (core tables: expenses, categories, accounts, budgets)
# - 0002_add_user_auth_context.sql (user authentication and RLS policies)
```

### 4. Verify Setup is Working

**Check All Services Are Running:**
```bash
# Option 1: Using our management script
./scripts/supabase-docker.sh status

# Option 2: Using Supabase CLI directly
supabase status
```

**Expected Output:**
```
supabase local development setup is running.

         API URL: http://127.0.0.1:54321
          DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
      Studio URL: http://127.0.0.1:54323
    Inbucket URL: http://127.0.0.1:54324
        anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Test Database Connection:**
```bash
# Connect directly to the database
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres

# Once connected, check that tables exist
\dt

# You should see tables like: expenses, categories, accounts, budgets
# Exit with: \q
```

**Test Web Interface:**
- Open http://127.0.0.1:54323 in your browser
- This is Supabase Studio - your database management interface
- You should see tables, authentication, and storage tabs

### 5. Configure and Run Flutter App

**Set Environment Variables (Optional):**

The app is pre-configured to use local Supabase, but you can create a `.env` file for custom settings:

```bash
# Create .env file in project root
cat > .env << EOF
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
EOF
```

**Run the Flutter App:**

```bash
# Run app with default local configuration  
flutter run

# Run with specific device
flutter run -d chrome    # Web browser
flutter run -d android   # Android emulator
flutter run -d ios       # iOS simulator (macOS only)

# Run in debug mode with verbose output
flutter run --debug -v
```

**Test Core Features:**
1. Launch the app - you should see the expense tracker home screen
2. Create a test expense - verify it saves
3. Add a category - test customization
4. Try uploading a receipt photo
5. Test the sync by checking Supabase Studio (http://127.0.0.1:54323)

## Quick Start Commands

For daily development, these are the essential commands:

```bash
# Start your development session
./scripts/supabase-docker.sh start

# Check everything is running
./scripts/supabase-docker.sh status

# Run the Flutter app
flutter run

# When you're done, stop services (optional - they can run in background)
./scripts/supabase-docker.sh stop
```

## Available Services

When Supabase is running with Docker, the following services are available:

| Service | URL | Purpose |
|---------|-----|---------|
| REST API | http://127.0.0.1:54321 | Main API endpoint |
| GraphQL | http://127.0.0.1:54321/graphql/v1 | GraphQL interface |
| Database | postgresql://postgres:postgres@127.0.0.1:54322/postgres | PostgreSQL direct access |
| Studio | http://127.0.0.1:54323 | Database management UI |
| Storage | http://127.0.0.1:54321/storage/v1 | File storage API |
| Inbucket | http://127.0.0.1:54324 | Email testing |
| Realtime | ws://127.0.0.1:54321/realtime/v1/websocket | WebSocket connections |

## Management Script

The `./scripts/supabase-docker.sh` script provides easy management:

```bash
# Start all services
./scripts/supabase-docker.sh start

# Stop all services  
./scripts/supabase-docker.sh stop

# Restart services
./scripts/supabase-docker.sh restart

# Check status
./scripts/supabase-docker.sh status

# Show connection info
./scripts/supabase-docker.sh info

# View Docker containers
./scripts/supabase-docker.sh containers

# Test connection
./scripts/supabase-docker.sh test

# Reset database to stable state
./scripts/supabase-docker.sh reset

# Full setup from scratch
./scripts/supabase-docker.sh setup

# Show help
./scripts/supabase-docker.sh help
```

## Flutter App Configuration

The Flutter app is already configured to use the local Docker Supabase instance by default:

### Environment Variables (Optional)

Create a `.env` file in the project root if you want to override defaults:

```bash
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

### Default Configuration

The app uses these defaults (defined in `lib/main.dart`):
- **URL**: `http://127.0.0.1:54321` 
- **Anon Key**: Standard local development key
- **Auth Flow**: PKCE for secure authentication

## Understanding the Database Schema

### Core Tables Created Automatically

When you run the setup, these database tables are created:

1. **categories** - Expense categories (Food, Transport, etc.)
   - Supports icons, colors, and custom user categories
   - Includes sync metadata for offline-first operation

2. **accounts** - Financial accounts (Cash, Bank, Credit Card)
   - Tracks account balances and types
   - Multiple account support for comprehensive tracking

3. **expenses** - Main expense records
   - Links to categories and accounts
   - Supports receipt photos and detailed descriptions
   - Date/amount tracking with validation

4. **budgets** - Budget planning and tracking
   - Category-based budget allocation
   - Progress monitoring and alerts
   - Historical budget performance

5. **receipt_photos** - Photo storage metadata
   - Links receipt images to expenses  
   - File size and format tracking
   - Storage path management

6. **sync_metadata** - Sync state tracking
   - Manages offline/online data synchronization
   - Conflict resolution support
   - Last sync timestamps

### Authentication & Security Features

- **Row Level Security (RLS)**: Each user only sees their own data
- **User Authentication**: Email/password and anonymous auth supported
- **JWT Tokens**: Secure API access with automatic token refresh
- **Real-time Updates**: Live data synchronization across devices

### Database Schema File Locations

The schema is defined in migration files:

```bash
# View the core schema
cat supabase/migrations/0001_initial_schema.sql

# View authentication setup  
cat supabase/migrations/0002_add_user_auth_context.sql

# Check all available migrations
ls supabase/migrations/
```

### Seed Data and Dummy Content

The setup includes minimal seed data to get you started:

- **Default Categories**: Basic expense categories like Food, Transport, Entertainment
- **Sample Account**: A default "Cash" account to begin tracking
- **Test User Setup**: Anonymous authentication for immediate testing

**To add your own dummy data:**

1. **Via Supabase Studio** (Recommended for beginners):
   - Open http://127.0.0.1:54323
   - Navigate to "Table Editor"
   - Click on any table and "Insert row"
   - Add test data through the web interface

2. **Via SQL** (For advanced users):
   ```bash
   # Connect to database
   psql postgresql://postgres:postgres@127.0.0.1:54322/postgres
   
   # Insert sample data
   INSERT INTO categories (name, icon, color) VALUES 
     ('Food & Dining', '🍽️', '#FF6B6B'),
     ('Transportation', '🚗', '#4ECDC4'),
     ('Shopping', '🛍️', '#45B7D1');
   ```

3. **Via Flutter App**: Simply use the app interface to create test data - this is the most realistic way to test your setup.

## Docker Containers

Supabase CLI creates these Docker containers:

```bash
# View all Supabase containers
docker ps --filter label=com.supabase.cli.project=ExpenseTracker

# Or use our script
./scripts/supabase-docker.sh containers
```

Containers include:
- `supabase_db_ExpenseTracker` - PostgreSQL database
- `supabase_kong_ExpenseTracker` - API gateway
- `supabase_auth_ExpenseTracker` - Authentication service
- `supabase_realtime_ExpenseTracker` - Real-time subscriptions
- `supabase_rest_ExpenseTracker` - PostgREST API
- `supabase_storage_ExpenseTracker` - File storage
- And others...

## Troubleshooting

### Supabase Won't Start
```bash
# Check Docker is running
docker info

# Check for port conflicts
lsof -i :54321

# Clean restart
supabase stop
supabase start
```

### Database Issues
```bash
# Reset to stable state
./scripts/supabase-docker.sh reset

# Or full reset
supabase db reset --version=0002
```

### Flutter Connection Issues
1. Verify Supabase is running: `./scripts/supabase-docker.sh status`
2. Check the logs: `supabase logs`
3. Ensure no firewall blocking local ports
4. Verify `lib/main.dart` has correct URL configuration

### Performance Issues
```bash
# Check container resources
docker stats

# View container logs
docker logs supabase_db_ExpenseTracker

# Monitor query performance in Studio
open http://127.0.0.1:54323
```

## Development Workflow

1. **Start Development Session**:
   ```bash
   ./scripts/supabase-docker.sh start
   ```

2. **Run Flutter App**:
   ```bash
   flutter run
   ```

3. **Make Database Changes**:
   - Create new migration files in `supabase/migrations/`
   - Apply with `supabase db reset`

4. **End Session**:
   ```bash
   ./scripts/supabase-docker.sh stop
   ```

## Production Considerations

- This setup is for **local development only**
- For production, use hosted Supabase or deploy to your infrastructure
- Update environment variables for different environments
- Enable additional security features for production use

## What the App Does Automatically

### On First Launch
The ExpenseTracker app handles many setup tasks automatically when you run it for the first time:

1. **Database Connection**: 
   - Automatically detects and connects to local Supabase (http://127.0.0.1:54321)
   - Falls back to offline-only mode if Supabase isn't available
   - No manual configuration required

2. **Local Storage Initialization**:
   - Creates Hive database files for offline operation
   - Sets up encrypted local storage (if enabled)
   - Initializes sync metadata tracking

3. **Authentication Setup**:
   - Configures anonymous authentication for immediate testing
   - Sets up email/password authentication flows
   - Manages JWT token refresh automatically

4. **Default Data Creation**:
   - Creates basic expense categories if none exist
   - Sets up a default "Cash" account for immediate use
   - Initializes user preferences and settings

5. **Sync Orchestration**:
   - Automatically syncs local data to Supabase when online
   - Handles conflict resolution (Last-Write-Wins strategy)
   - Manages offline queue for mutations

### Ongoing Automatic Features

- **Real-time Sync**: Changes sync automatically in background
- **Photo Storage**: Receipt photos are automatically uploaded to Supabase Storage
- **Error Recovery**: Automatic retry of failed operations
- **Cache Management**: Intelligent caching of frequently accessed data
- **Security**: Automatic token refresh and secure API calls

### Manual Steps Required

While most setup is automatic, users need to:

1. **Create User Account**: Register through the app's authentication UI
2. **Customize Categories**: Add or modify expense categories to suit your needs
3. **Set Budget Goals**: Configure budgets and spending targets
4. **Upload Receipts**: Take/select photos when creating expenses
5. **Configure Notifications**: Set up budget alerts and reminders (if needed)

### Code Integration Points

Key files that handle the automatic setup:

```bash
# Core initialization
lib/main.dart                          # App startup and Supabase client setup
lib/core/config/supabase_config.dart   # Connection configuration

# Data layer automation  
lib/core/data/datasources/supabase_remote_data_source.dart  # API integration
lib/core/data/datasources/hive_local_data_source.dart       # Local storage
lib/core/data/services/sync_orchestrator_impl.dart         # Sync automation

# Authentication automation
lib/features/auth/data/services/supabase_auth_service.dart  # Auth flows
lib/features/auth/presentation/providers/auth_provider.dart # State management

# Storage automation
lib/core/services/photo_storage_service.dart               # Receipt uploads
lib/core/services/offline_storage_service.dart             # Local caching
```

### Debugging Automatic Features

If something isn't working automatically:

1. **Check Logs**:
   ```bash
   # Flutter app logs
   flutter logs
   
   # Supabase service logs
   supabase logs
   ```

2. **Verify Services**:
   ```bash
   # Check all services are running
   ./scripts/supabase-docker.sh status
   
   # Test connectivity
   curl http://127.0.0.1:54321/rest/v1/
   ```

3. **Reset and Retry**:
   ```bash
   # Reset local database
   ./scripts/supabase-docker.sh reset
   
   # Clear Flutter app data
   flutter clean && flutter pub get
   ```

## Production Deployment

Once your local development is working perfectly, you can deploy to remote Supabase:

### **Setup Remote Project**:
```bash
# 1. Authenticate with Supabase
supabase login

# 2. Create or link remote project  
supabase link --project-ref your-project-id

# 3. Deploy your local schema to remote
./scripts/deploy_schema_updates.sh
```

### **Run App on Remote Supabase**:
```bash
# Create production environment file
echo "SUPABASE_URL=https://your-project.supabase.co" > .env.production
echo "SUPABASE_ANON_KEY=your-anon-key" >> .env.production

# Run with remote backend
flutter run --dart-define-from-file=.env.production
```

### **Complete Workflow**:
1. **Develop Locally**: `flutter run` (uses local Docker Supabase)
2. **Test & Iterate**: Make changes, run tests
3. **Deploy Schema**: `./scripts/deploy_schema_updates.sh`
4. **Test Remote**: `flutter run --dart-define-from-file=.env.production`
5. **Build & Deploy**: `flutter build apk --dart-define-from-file=.env.production`

For detailed deployment workflows, see: [`docs/DEPLOYMENT_WORKFLOW.md`](./DEPLOYMENT_WORKFLOW.md)

## Next Steps

1. **Database Schema**: Review and update migration files as needed
2. **Authentication**: Configure auth providers and flows  
3. **Storage**: Set up file storage buckets for receipts
4. **Real-time**: Configure subscriptions for live data
5. **Edge Functions**: Add custom business logic functions
6. **Production Setup**: Follow deployment workflow for remote Supabase

For detailed API documentation, visit the local Studio at http://127.0.0.1:54323 when services are running.