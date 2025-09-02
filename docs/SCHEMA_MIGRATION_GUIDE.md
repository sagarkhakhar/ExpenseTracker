# Schema Migration Guide

Guide for managing database schema changes from local to remote Supabase.

## Local Schema Development

### Creating New Migrations
```bash
supabase migration new add_feature_name
```

### Testing Migrations Locally
```bash
supabase db reset
flutter run  # Test with app
```

## Remote Deployment

### Prerequisites
```bash
supabase login
supabase link --project-ref your-project-id
```

### Deploy Process
```bash
# 1. Preview changes
./scripts/deploy_schema_updates.sh --dry-run

# 2. Backup and deploy
./scripts/deploy_schema_updates.sh

# 3. Test remote connection
flutter run --dart-define-from-file=.env.production
```

## Best Practices

- **One change per migration**: Keep migrations atomic
- **Always backup**: Backup before production deployment  
- **Test thoroughly**: Test on staging environment first
- **Document rollbacks**: Know how to revert changes

## Common Commands

```bash
# Check migration status
supabase migration list

# View schema differences  
supabase db diff --linked

# Reset remote database
supabase db reset --linked
```

This ensures safe schema deployments from local to production! 🚀