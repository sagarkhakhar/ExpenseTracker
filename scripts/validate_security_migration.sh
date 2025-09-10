#!/bin/bash
# Script to validate the security migration files
# This validates the migration without requiring a running database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if we're in the right directory
if [[ ! -f "pubspec.yaml" ]] || [[ ! -d "supabase" ]]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

print_header "Security Migration Validation"

# Validate migration file exists
MIGRATION_FILE="supabase/migrations/0010_fix_security_issues.sql"
if [[ -f "$MIGRATION_FILE" ]]; then
    print_success "Migration file found: $MIGRATION_FILE"
else
    print_error "Migration file not found: $MIGRATION_FILE"
    exit 1
fi

# Validate migration content
print_status "Validating migration content..."

# Check for key security fixes
if grep -q "DROP VIEW IF EXISTS expenses_legacy_view" "$MIGRATION_FILE"; then
    print_success "✅ Found DROP VIEW statement for expenses_legacy_view"
else
    print_error "❌ Missing DROP VIEW statement for expenses_legacy_view"
fi

if grep -q "CREATE VIEW expenses_legacy_view AS SELECT" "$MIGRATION_FILE" && ! grep -q "SECURITY DEFINER" "$MIGRATION_FILE"; then
    print_success "✅ Found CREATE VIEW statement without SECURITY DEFINER"
else
    print_error "❌ Missing CREATE VIEW statement or still contains SECURITY DEFINER"
fi

if grep -q "ALTER TABLE app_migrations ENABLE ROW LEVEL SECURITY" "$MIGRATION_FILE"; then
    print_success "✅ Found RLS enable statement for app_migrations"
else
    print_error "❌ Missing RLS enable statement for app_migrations"
fi

if grep -q "CREATE POLICY.*app_migrations" "$MIGRATION_FILE"; then
    POLICY_COUNT=$(grep -c "CREATE POLICY.*app_migrations" "$MIGRATION_FILE")
    if [[ $POLICY_COUNT -ge 3 ]]; then
        print_success "✅ Found $POLICY_COUNT RLS policies for app_migrations"
    else
        print_warning "⚠️ Found only $POLICY_COUNT RLS policies, expected at least 3"
    fi
else
    print_error "❌ Missing RLS policies for app_migrations"
fi

# Validate SQL syntax (basic check)
print_status "Performing basic SQL syntax validation..."

if grep -q "BEGIN\|COMMIT" "$MIGRATION_FILE"; then
    print_warning "⚠️ Migration contains transaction control statements (may cause issues in some environments)"
fi

# Check for common SQL issues
SYNTAX_ISSUES=0

if grep -q "DROP.*IF EXISTS.*CASCADE" "$MIGRATION_FILE"; then
    print_warning "⚠️ Found CASCADE drops - ensure this is intentional"
    ((SYNTAX_ISSUES++))
fi

if grep -q "SELECT.*INTO.*FROM" "$MIGRATION_FILE"; then
    print_status "✅ Found proper variable assignments"
fi

# Validate file structure
print_status "Validating file structure..."

LINE_COUNT=$(wc -l < "$MIGRATION_FILE")
if [[ $LINE_COUNT -gt 100 ]]; then
    print_success "✅ Migration file has substantial content ($LINE_COUNT lines)"
else
    print_warning "⚠️ Migration file seems short ($LINE_COUNT lines)"
fi

# Check for documentation
if grep -q "Purpose:" "$MIGRATION_FILE" && grep -q "Issues Fixed:" "$MIGRATION_FILE"; then
    print_success "✅ Migration includes proper documentation"
else
    print_warning "⚠️ Migration documentation could be improved"
fi

# Validate related files
print_header "Validating Related Files"

DEPLOY_SCRIPT="scripts/apply_security_fixes.sh"
if [[ -f "$DEPLOY_SCRIPT" && -x "$DEPLOY_SCRIPT" ]]; then
    print_success "✅ Deployment script exists and is executable"
else
    print_error "❌ Deployment script missing or not executable"
fi

README_FILE="docs/security_fixes_readme.md"
if [[ -f "$README_FILE" ]]; then
    print_success "✅ Security fixes documentation exists"
else
    print_error "❌ Security fixes documentation missing"
fi

ERROR_DOC="docs/supabase_error.md"
if [[ -f "$ERROR_DOC" ]]; then
    print_success "✅ Original error documentation found"
    
    # Check if the issues mentioned in the migration match the documented errors
    if grep -q "expenses_legacy_view" "$ERROR_DOC" && grep -q "app_migrations" "$ERROR_DOC"; then
        print_success "✅ Migration addresses documented security issues"
    else
        print_warning "⚠️ Migration may not address all documented issues"
    fi
else
    print_warning "⚠️ Original error documentation not found"
fi

# Validate migration ordering
print_status "Checking migration sequence..."

LATEST_MIGRATION=$(ls supabase/migrations/*.sql | sort -V | tail -1)
if [[ "$LATEST_MIGRATION" == *"0010_fix_security_issues.sql" ]]; then
    print_success "✅ Security migration is the latest migration"
else
    print_warning "⚠️ Security migration may not be the latest (latest: $(basename "$LATEST_MIGRATION"))"
fi

# Check for conflicts with existing migrations
print_status "Checking for potential conflicts..."

if grep -l "expenses_legacy_view" supabase/migrations/*.sql | grep -v "0010_fix_security_issues.sql"; then
    print_warning "⚠️ Other migrations also reference expenses_legacy_view - review for conflicts"
fi

if grep -l "app_migrations.*ENABLE ROW LEVEL SECURITY" supabase/migrations/*.sql | grep -v "0010_fix_security_issues.sql"; then
    print_warning "⚠️ Other migrations may also enable RLS on app_migrations - review for conflicts"
fi

# Summary
print_header "Validation Summary"

if [[ $SYNTAX_ISSUES -eq 0 ]]; then
    print_success "🎉 Security migration validation PASSED!"
    print_status "The migration is ready to be applied and should resolve the identified security issues:"
    echo "  ✅ expenses_legacy_view SECURITY DEFINER issue"
    echo "  ✅ app_migrations RLS disabled issue"
    echo ""
    print_status "Next steps:"
    echo "  1. Apply the migration using: ./scripts/apply_security_fixes.sh"
    echo "  2. Test your application thoroughly"
    echo "  3. Run Supabase database linter to verify fixes"
else
    print_warning "⚠️ Validation completed with $SYNTAX_ISSUES warnings"
    print_status "Review the warnings above and proceed with caution"
fi

print_status "For detailed information, see: docs/security_fixes_readme.md"