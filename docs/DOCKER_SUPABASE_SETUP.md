# Docker Supabase Setup Guide

This guide explains how to set up and manage Supabase with Docker for local development of the ExpenseTracker Flutter app.

## Prerequisites

1. **Docker Desktop** - Must be installed and running
2. **Supabase CLI** - Install with: `brew install supabase/tap/supabase`
3. **Flutter/Dart** - For running the app and tests

## Quick Start

### 1. Start Supabase Services

```bash
# Using our management script (recommended)
./scripts/supabase-docker.sh start

# Or using Supabase CLI directly
supabase start
```

### 2. Check Status

```bash
./scripts/supabase-docker.sh status
```

### 3. Test Connection

```bash
./scripts/supabase-docker.sh test
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

## Database Schema

The setup uses the first 2 stable migrations:
- `0001_initial_schema.sql` - Core tables (expenses, categories, accounts, budgets)
- `0002_add_user_auth_context.sql` - User authentication and profiles

Later migrations are skipped to avoid compatibility issues during initial setup.

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

## Integration with Flutter

The app automatically:
- Initializes Supabase client on startup
- Connects to local Docker instance by default
- Handles authentication flows
- Manages offline/online sync

Code locations:
- Supabase initialization: `lib/main.dart`
- Remote data source: `lib/core/data/datasources/supabase_remote_data_source.dart`
- Authentication service: `lib/core/services/authentication_service.dart`
- Sync orchestration: `lib/core/data/services/sync_orchestrator_impl.dart`

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