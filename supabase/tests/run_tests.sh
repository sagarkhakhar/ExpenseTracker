#!/bin/bash

# Test runner script for Supabase authentication backend
# This script runs various tests to validate the authentication implementation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUPABASE_PROJECT_ID="ExpenseTracker"
SUPABASE_DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"
TEST_DIR="$(dirname "$0")"
REPORTS_DIR="$TEST_DIR/reports"

# Create reports directory
mkdir -p "$REPORTS_DIR"

echo -e "${BLUE}🧪 Starting Supabase Authentication Backend Tests${NC}"
echo -e "${BLUE}===============================================${NC}"

# Function to log messages
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to run a test and capture results
run_test() {
    local test_name="$1"
    local test_file="$2"
    local report_file="$REPORTS_DIR/${test_name}_$(date +%Y%m%d_%H%M%S).txt"
    
    log "Running $test_name..."
    
    if [ ! -f "$test_file" ]; then
        echo -e "${RED}❌ Test file not found: $test_file${NC}"
        return 1
    fi
    
    # Run the test and capture output
    if psql "$SUPABASE_DB_URL" -f "$test_file" > "$report_file" 2>&1; then
        echo -e "${GREEN}✅ $test_name completed${NC}"
        
        # Check for failures in the output
        if grep -q "FAIL" "$report_file"; then
            echo -e "${YELLOW}⚠️  Some tests failed in $test_name${NC}"
            echo -e "${YELLOW}   Check report: $report_file${NC}"
        else
            echo -e "${GREEN}🎉 All tests passed in $test_name${NC}"
        fi
    else
        echo -e "${RED}❌ $test_name failed to execute${NC}"
        echo -e "${RED}   Check report: $report_file${NC}"
        return 1
    fi
}

# Function to check if Supabase is running
check_supabase_status() {
    log "Checking Supabase local instance status..."
    
    if ! command -v supabase &> /dev/null; then
        echo -e "${RED}❌ Supabase CLI not found${NC}"
        echo -e "${YELLOW}   Install with: npm install -g supabase@latest${NC}"
        return 1
    fi
    
    if ! supabase status > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Supabase not running, attempting to start...${NC}"
        if ! supabase start; then
            echo -e "${RED}❌ Failed to start Supabase${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ Supabase is running${NC}"
}

# Function to run database migrations
run_migrations() {
    log "Applying database migrations..."
    
    if supabase db push; then
        echo -e "${GREEN}✅ Migrations applied successfully${NC}"
    else
        echo -e "${RED}❌ Failed to apply migrations${NC}"
        return 1
    fi
}

# Function to test Edge Functions deployment
test_edge_functions() {
    log "Testing Edge Functions..."
    
    # Test user-management function
    if supabase functions deploy user-management > /dev/null 2>&1; then
        echo -e "${GREEN}✅ user-management function deployed${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to deploy user-management function${NC}"
    fi
    
    # Test auth-webhook function
    if supabase functions deploy auth-webhook > /dev/null 2>&1; then
        echo -e "${GREEN}✅ auth-webhook function deployed${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to deploy auth-webhook function${NC}"
    fi
}

# Function to run configuration tests
test_configuration() {
    log "Testing Supabase configuration..."
    
    local config_report="$REPORTS_DIR/configuration_test_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== Supabase Configuration Test ==="
        echo "Date: $(date)"
        echo ""
        
        echo "--- Auth Configuration ---"
        supabase status | grep -A 20 "Auth" || echo "Could not retrieve auth status"
        echo ""
        
        echo "--- Database Configuration ---"
        supabase status | grep -A 10 "DB" || echo "Could not retrieve DB status"
        echo ""
        
        echo "--- Storage Configuration ---"
        supabase status | grep -A 5 "Storage" || echo "Could not retrieve storage status"
        echo ""
        
        echo "--- Edge Functions ---"
        supabase functions list || echo "Could not list functions"
        
    } > "$config_report"
    
    echo -e "${GREEN}✅ Configuration test completed${NC}"
    echo -e "${BLUE}   Report saved: $config_report${NC}"
}

# Function to run email template tests
test_email_templates() {
    log "Testing email templates..."
    
    local templates_dir="../templates"
    local template_report="$REPORTS_DIR/email_templates_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== Email Templates Test ==="
        echo "Date: $(date)"
        echo ""
        
        for template in confirmation recovery invite; do
            local template_file="$templates_dir/${template}.html"
            if [ -f "$template_file" ]; then
                echo "✅ $template.html exists ($(wc -l < "$template_file") lines)"
                
                # Basic validation
                if grep -q "{{.*}}" "$template_file"; then
                    echo "   ✅ Contains template variables"
                else
                    echo "   ⚠️  No template variables found"
                fi
                
                if grep -q "<html>" "$template_file" && grep -q "</html>" "$template_file"; then
                    echo "   ✅ Valid HTML structure"
                else
                    echo "   ⚠️  HTML structure may be invalid"
                fi
            else
                echo "❌ $template.html missing"
            fi
            echo ""
        done
    } > "$template_report"
    
    echo -e "${GREEN}✅ Email templates test completed${NC}"
    echo -e "${BLUE}   Report saved: $template_report${NC}"
}

# Function to generate final report
generate_final_report() {
    local final_report="$REPORTS_DIR/final_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "========================================"
        echo "  SUPABASE AUTHENTICATION TEST REPORT"
        echo "========================================"
        echo "Date: $(date)"
        echo "Project: $SUPABASE_PROJECT_ID"
        echo ""
        
        echo "--- Test Files Generated ---"
        ls -la "$REPORTS_DIR"/*.txt 2>/dev/null || echo "No test reports found"
        echo ""
        
        echo "--- Summary ---"
        local total_reports=$(find "$REPORTS_DIR" -name "*.txt" -type f | wc -l)
        echo "Total test reports: $total_reports"
        
        local failed_tests=0
        for report in "$REPORTS_DIR"/*.txt; do
            if [ -f "$report" ] && grep -q "FAIL\|❌\|ERROR" "$report"; then
                failed_tests=$((failed_tests + 1))
            fi
        done
        
        echo "Reports with failures: $failed_tests"
        
        if [ "$failed_tests" -eq 0 ]; then
            echo "Status: 🎉 ALL TESTS PASSED"
        else
            echo "Status: ⚠️  SOME TESTS FAILED - Review individual reports"
        fi
        
        echo ""
        echo "--- Next Steps ---"
        echo "1. Review individual test reports in: $REPORTS_DIR"
        echo "2. Fix any failing tests"
        echo "3. Re-run tests until all pass"
        echo "4. Proceed with Story 3.1 (Frontend UI Implementation)"
        
    } > "$final_report"
    
    echo -e "${BLUE}📊 Final test report generated: $final_report${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting test execution...${NC}"
    
    # Pre-flight checks
    check_supabase_status || exit 1
    
    # Run migrations
    run_migrations || exit 1
    
    # Run all tests
    test_configuration
    test_email_templates
    test_edge_functions
    
    # Run SQL integration tests
    if [ -f "$TEST_DIR/auth_integration_test.sql" ]; then
        run_test "SQL Integration Tests" "$TEST_DIR/auth_integration_test.sql"
    fi
    
    if [ -f "$TEST_DIR/../test_auth_flows.sql" ]; then
        run_test "Auth Flows Test" "$TEST_DIR/../test_auth_flows.sql"
    fi
    
    # Generate final report
    generate_final_report
    
    echo ""
    echo -e "${GREEN}🎉 Test execution completed!${NC}"
    echo -e "${BLUE}📁 All reports saved to: $REPORTS_DIR${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "${YELLOW}1. Review test reports for any failures${NC}"
    echo -e "${YELLOW}2. Fix failing tests if any${NC}"
    echo -e "${YELLOW}3. Proceed with Story 3.1 implementation${NC}"
}

# Execute main function
main "$@"