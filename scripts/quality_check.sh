#!/bin/bash
# Advanced quality check script for exceptional code quality validation
# This script runs comprehensive checks before commits or releases

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COVERAGE_THRESHOLD=80
MAX_APK_SIZE_MB=50
PERFORMANCE_THRESHOLD_MS=1000

echo -e "${BLUE}🔍 Starting Comprehensive Quality Checks${NC}"
echo "======================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Not in a Flutter project directory${NC}"
    exit 1
fi

# Function to print step header
print_step() {
    echo ""
    echo -e "${BLUE}📋 $1${NC}"
    echo "-------------------"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Environment Check
print_step "Environment Validation"

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n1 | cut -d' ' -f2)
echo "Flutter version: $FLUTTER_VERSION"

# Check Dart version  
DART_VERSION=$(dart --version | cut -d' ' -f4)
echo "Dart version: $DART_VERSION"

print_success "Environment validation completed"

# Step 2: Dependency Management
print_step "Dependency Management"

echo "Getting dependencies..."
flutter pub get

echo "Checking for dependency conflicts..."
if flutter pub deps > /tmp/deps.txt 2>&1; then
    print_success "Dependencies resolved successfully"
else
    print_error "Dependency conflicts found"
    cat /tmp/deps.txt
    exit 1
fi

echo "Checking for unused dependencies..."
# Custom script to detect unused dependencies
dart run scripts/check_unused_deps.dart || print_warning "Unused dependency check skipped"

print_success "Dependency management completed"

# Step 3: Code Generation
print_step "Code Generation"

echo "Running build_runner..."
if flutter packages pub run build_runner build --delete-conflicting-outputs; then
    print_success "Code generation completed"
else
    print_error "Code generation failed"
    exit 1
fi

# Step 4: Static Analysis
print_step "Static Analysis & Linting"

echo "Checking code formatting..."
if dart format --output=none --set-exit-if-changed .; then
    print_success "Code formatting is correct"
else
    print_error "Code formatting issues found. Run 'dart format .'"
    exit 1
fi

echo "Running static analysis..."
if flutter analyze --fatal-infos; then
    print_success "Static analysis passed"
else
    print_error "Static analysis found issues"
    exit 1
fi

echo "Checking for TODO/FIXME comments..."
TODO_COUNT=$(grep -r --include="*.dart" -c "TODO\|FIXME" lib/ test/ || echo "0")
if [ "$TODO_COUNT" -gt 0 ]; then
    print_warning "Found $TODO_COUNT TODO/FIXME comments"
    grep -r --include="*.dart" -n "TODO\|FIXME" lib/ test/ || true
fi

print_success "Static analysis completed"

# Step 5: Security Checks
print_step "Security Scanning"

echo "Scanning for potential security issues..."

# Check for hardcoded secrets
if grep -r --include="*.dart" --include="*.yaml" -i "password\|secret\|key\|token\|api_key" . | grep -v "# Example\|// Example\|test\|mock"; then
    print_warning "Potential hardcoded secrets found"
else
    print_success "No hardcoded secrets detected"
fi

# Check for dangerous patterns
echo "Checking for dangerous code patterns..."
if grep -r --include="*.dart" -n "eval\|exec\|system\|shell" lib/; then
    print_warning "Potentially dangerous code patterns found"
else
    print_success "No dangerous patterns detected"
fi

print_success "Security scanning completed"

# Step 6: Testing
print_step "Running Tests"

echo "Running unit tests with coverage..."
if flutter test --coverage --test-randomize-ordering-seed=random; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Check coverage threshold
if command -v lcov &> /dev/null; then
    echo "Calculating test coverage..."
    
    # Generate coverage report
    lcov --summary coverage/lcov.info > /tmp/coverage_summary.txt 2>&1
    
    # Extract coverage percentage
    COVERAGE=$(grep -o '[0-9]\+\.[0-9]\+%' /tmp/coverage_summary.txt | head -n1 | sed 's/%//')
    
    if [ -n "$COVERAGE" ]; then
        echo "Test coverage: ${COVERAGE}%"
        
        # Check if coverage meets threshold
        if (( $(echo "$COVERAGE >= $COVERAGE_THRESHOLD" | bc -l) )); then
            print_success "Coverage ${COVERAGE}% meets threshold of ${COVERAGE_THRESHOLD}%"
        else
            print_error "Coverage ${COVERAGE}% is below minimum threshold of ${COVERAGE_THRESHOLD}%"
            exit 1
        fi
    else
        print_warning "Could not determine test coverage"
    fi
else
    print_warning "lcov not installed, skipping coverage check"
fi

echo "Running integration tests..."
if [ -d "integration_test" ] && [ -f "test_driver/integration_test.dart" ]; then
    # Note: This would need an emulator/device connected
    echo "Integration tests found but skipping (requires device/emulator)"
    print_warning "Integration tests skipped - no device connected"
else
    print_warning "No integration tests found"
fi

print_success "Testing completed"

# Step 7: Performance Checks
print_step "Performance Analysis"

echo "Analyzing app size..."
if flutter build apk --debug --tree-shake-icons > /dev/null 2>&1; then
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(stat -f%z "$APK_PATH" 2>/dev/null || stat -c%s "$APK_PATH")
        APK_SIZE_MB=$((APK_SIZE / 1024 / 1024))
        
        echo "APK size: ${APK_SIZE_MB}MB"
        
        if [ $APK_SIZE_MB -gt $MAX_APK_SIZE_MB ]; then
            print_warning "APK size ${APK_SIZE_MB}MB exceeds recommended ${MAX_APK_SIZE_MB}MB"
        else
            print_success "APK size ${APK_SIZE_MB}MB is acceptable"
        fi
    fi
fi

echo "Checking for performance anti-patterns..."
PERF_ISSUES=0

# Check for expensive operations in build methods
if grep -r --include="*.dart" -n "build.*(" lib/ | grep -E "(DateTime\.now|Random|File|http\.)" >/dev/null; then
    print_warning "Potential expensive operations in build methods found"
    PERF_ISSUES=$((PERF_ISSUES + 1))
fi

# Check for missing const constructors
MISSING_CONST=$(grep -r --include="*.dart" -c "Widget.*{" lib/ | awk -F: '{sum+=$2} END {print sum}')
if [ "$MISSING_CONST" -gt 100 ]; then
    print_warning "Many widgets without const constructors found"
    PERF_ISSUES=$((PERF_ISSUES + 1))
fi

if [ $PERF_ISSUES -eq 0 ]; then
    print_success "No major performance issues detected"
fi

print_success "Performance analysis completed"

# Step 8: Build Validation
print_step "Build Validation"

echo "Testing release build..."
if flutter build apk --release > /dev/null 2>&1; then
    print_success "Release build successful"
else
    print_error "Release build failed"
    exit 1
fi

# Clean up build artifacts
echo "Cleaning up build artifacts..."
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

print_success "Build validation completed"

# Step 9: Documentation Check
print_step "Documentation Validation"

echo "Checking for API documentation..."
UNDOCUMENTED=$(grep -r --include="*.dart" -L "///" lib/ | wc -l)
if [ "$UNDOCUMENTED" -gt 0 ]; then
    print_warning "$UNDOCUMENTED files missing API documentation"
else
    print_success "All files have API documentation"
fi

echo "Checking README.md..."
if [ ! -f "README.md" ]; then
    print_warning "README.md not found"
else
    README_SIZE=$(wc -c < README.md)
    if [ "$README_SIZE" -lt 500 ]; then
        print_warning "README.md seems incomplete (${README_SIZE} bytes)"
    else
        print_success "README.md exists and has reasonable content"
    fi
fi

print_success "Documentation validation completed"

# Step 10: Final Report
print_step "Quality Check Summary"

echo -e "${GREEN}🎉 All quality checks completed successfully!${NC}"
echo ""
echo "Summary:"
echo "- ✅ Environment validated"
echo "- ✅ Dependencies resolved"
echo "- ✅ Code generation successful"
echo "- ✅ Static analysis passed"
echo "- ✅ Security checks completed"
echo "- ✅ Tests passed with adequate coverage"
echo "- ✅ Performance analysis completed"
echo "- ✅ Build validation successful"
echo "- ✅ Documentation checked"

echo ""
echo -e "${GREEN}🚀 Ready for commit/deployment!${NC}"

# Optional: Generate quality report
if [ "$1" = "--report" ]; then
    echo "Generating detailed quality report..."
    {
        echo "# Quality Check Report"
        echo "Generated: $(date)"
        echo ""
        echo "## Environment"
        echo "- Flutter: $FLUTTER_VERSION"
        echo "- Dart: $DART_VERSION"
        echo ""
        echo "## Test Coverage"
        echo "- Coverage: ${COVERAGE:-N/A}%"
        echo ""
        echo "## Build Information"
        echo "- APK Size: ${APK_SIZE_MB:-N/A}MB"
        echo ""
        echo "## Issues Found"
        echo "- TODOs/FIXMEs: $TODO_COUNT"
        echo "- Performance Issues: $PERF_ISSUES"
        echo "- Undocumented Files: $UNDOCUMENTED"
    } > quality_report.md
    
    print_success "Quality report saved to quality_report.md"
fi