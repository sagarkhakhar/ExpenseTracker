#!/bin/bash
# Deploy Schema Updates to Remote Supabase

set -e

print_status() { echo "[INFO] $1"; }
print_success() { echo "[SUCCESS] $1"; }
print_error() { echo "[ERROR] $1"; }

main() {
    print_status "Deploying to remote Supabase..."
    
    if ! supabase projects list &> /dev/null; then
        print_error "Not authenticated. Run: supabase login"
        exit 1
    fi
    
    timestamp=$(date +"%Y%m%d_%H%M%S")
    mkdir -p backups
    supabase db dump --linked > "backups/remote_backup_${timestamp}.sql"
    
    supabase db push --linked
    print_success "Deployment completed!"
}

case "${1:-}" in
    "--dry-run") supabase db diff --linked ;;
    *) main ;;
esac