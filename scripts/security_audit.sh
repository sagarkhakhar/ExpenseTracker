#!/bin/bash

# 🛡️ COMPREHENSIVE SECURITY AUDIT SCRIPT
# This script validates that all sensitive files are properly ignored by git

echo "🔍 SECURITY AUDIT: Checking for exposed sensitive files..."
echo "=================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counter for issues
ISSUES_FOUND=0

# Function to check if files are tracked by git
check_sensitive_files() {
    local pattern="$1"
    local description="$2"
    
    echo -e "${BLUE}Checking: $description${NC}"
    
    # Find files matching pattern
    found_files=$(find . -name "$pattern" -not -path "./.git/*" 2>/dev/null)
    
    if [ -n "$found_files" ]; then
        # Check if any are tracked by git
        tracked_files=""
        while IFS= read -r file; do
            if [ -n "$file" ] && git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
                tracked_files="$tracked_files\n  $file"
            fi
        done <<< "$found_files"
        
        if [ -n "$tracked_files" ]; then
            echo -e "${RED}❌ SECURITY ISSUE: Tracked sensitive files found:${NC}"
            echo -e "$tracked_files"
            ((ISSUES_FOUND++))
        else
            echo -e "${GREEN}✅ Protected: Files found but properly ignored${NC}"
        fi
    else
        echo -e "${GREEN}✅ Clean: No files of this type found${NC}"
    fi
    echo
}

# Function to check for credentials in tracked files
check_credentials_in_files() {
    echo -e "${BLUE}Checking: Credentials in tracked files${NC}"
    
    # Search for potential credentials in tracked files
    credential_patterns=(
        "SUPABASE_URL.*=.*https://[a-z0-9]+\.supabase\.co"
        "SUPABASE.*KEY.*=.*eyJ[A-Za-z0-9]"
        "password.*=.*[^(example|placeholder|YOUR_|template)]"
        "secret.*=.*[^(example|placeholder|YOUR_|template)]"
        "api.*key.*=.*[^(placeholder|YOUR_|template)]"
        "token.*=.*[^(sample|YOUR_|template)]"
    )
    
    for pattern in "${credential_patterns[@]}"; do
        found=$(git grep -i "$pattern" 2>/dev/null | grep -v "example\|placeholder\|sample\|template\|test\|demo\|YOUR_\|config\.toml\|secrets\.\|secrets\[\|secrets\{\|\$\{\{" | head -3)
        if [ -n "$found" ]; then
            echo -e "${RED}❌ POTENTIAL CREDENTIAL EXPOSURE:${NC}"
            echo "$found"
            ((ISSUES_FOUND++))
        fi
    done
    
    if [ $ISSUES_FOUND -eq 0 ]; then
        echo -e "${GREEN}✅ No credentials found in tracked files${NC}"
    fi
    echo
}

# Main security checks
echo "🔍 PHASE 1: Checking sensitive file patterns..."
check_sensitive_files "*.env" "Environment files"
check_sensitive_files "*secret*" "Secret files"  
check_sensitive_files "*credential*" "Credential files"
check_sensitive_files "*.key" "Key files"
check_sensitive_files "*.pem" "Certificate files"
check_sensitive_files "*.p12" "Certificate files"
check_sensitive_files "*.keystore" "Android keystores"
check_sensitive_files "*.jks" "Java keystores"
check_sensitive_files ".vscode/launch.json" "VS Code launch configurations"
check_sensitive_files "supabase/.env*" "Supabase environment files"
check_sensitive_files "*_credentials.*" "Credential files"
check_sensitive_files "*_secrets.*" "Secret files"
check_sensitive_files "*_keys.*" "Key files"

echo "🔍 PHASE 2: Checking for embedded credentials..."
check_credentials_in_files

echo "🔍 PHASE 3: Checking AI tool configurations..."
check_sensitive_files ".cursor*" "Cursor AI configurations"
check_sensitive_files ".copilot*" "GitHub Copilot configurations"
check_sensitive_files ".anthropic*" "Anthropic API configurations"
check_sensitive_files ".openai*" "OpenAI configurations"
check_sensitive_files "ai_credentials.*" "AI credential files"

echo "🔍 PHASE 4: Checking database and cache files..."
check_sensitive_files "*.sqlite*" "SQLite databases"
check_sensitive_files "*.db" "Database files"
check_sensitive_files "*.hive" "Hive database files"
check_sensitive_files "cache/" "Cache directories"
check_sensitive_files "user_data/" "User data directories"

echo "🔍 PHASE 5: Checking build artifacts..."
check_sensitive_files "*.zip" "Archive files"
check_sensitive_files "*.rar" "Archive files"
check_sensitive_files "*.tar*" "Archive files"
check_sensitive_files "build/" "Build directories"
check_sensitive_files "dist/" "Distribution directories"

# Final report
echo "=================================================================="
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 SECURITY AUDIT PASSED!${NC}"
    echo -e "${GREEN}✅ No security issues found. All sensitive files are properly protected.${NC}"
else
    echo -e "${RED}⚠️  SECURITY AUDIT FAILED!${NC}"
    echo -e "${RED}❌ Found $ISSUES_FOUND security issue(s) that need immediate attention.${NC}"
    echo
    echo -e "${YELLOW}🔧 RECOMMENDED ACTIONS:${NC}"
    echo "1. Remove any exposed credential files from git history"
    echo "2. Add missing patterns to .gitignore"
    echo "3. Rotate any exposed credentials"
    echo "4. Re-run this audit script to verify fixes"
fi
echo "=================================================================="

exit $ISSUES_FOUND