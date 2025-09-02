#!/bin/bash

# Supabase Docker Management Script
# This script helps manage the Supabase Docker setup for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Supabase CLI is installed
check_supabase_cli() {
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI not found. Please install it first:"
        echo "  brew install supabase/tap/supabase"
        echo "  or visit: https://supabase.com/docs/guides/cli"
        exit 1
    fi
    print_success "Supabase CLI found: $(supabase --version)"
}

# Check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker is running"
}

# Start Supabase services
start_supabase() {
    print_status "Starting Supabase services..."
    
    if supabase status &> /dev/null; then
        print_warning "Supabase is already running"
        show_status
        return
    fi
    
    # Start with basic schema (first 2 migrations only)
    print_status "Starting Supabase with basic schema..."
    supabase start
    
    # Reset to stable migrations only
    print_status "Applying stable migrations..."
    supabase db reset --version=0002 --no-seed
    
    print_success "Supabase started successfully!"
    show_connection_info
}

# Stop Supabase services  
stop_supabase() {
    print_status "Stopping Supabase services..."
    supabase stop
    print_success "Supabase stopped"
}

# Restart Supabase services
restart_supabase() {
    print_status "Restarting Supabase services..."
    stop_supabase
    sleep 2
    start_supabase
}

# Show current status
show_status() {
    print_status "Checking Supabase status..."
    if supabase status &> /dev/null; then
        supabase status
    else
        print_warning "Supabase is not running"
        echo "Use '$0 start' to start services"
    fi
}

# Show connection information
show_connection_info() {
    print_status "Connection Information:"
    echo "  API URL: http://127.0.0.1:54321"
    echo "  Database: postgresql://postgres:postgres@127.0.0.1:54322/postgres"  
    echo "  Studio: http://127.0.0.1:54323"
    echo "  Inbucket (Email): http://127.0.0.1:54324"
    echo ""
    echo "Environment variables for Flutter app:"
    echo "  SUPABASE_URL=http://127.0.0.1:54321"
    echo "  SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
}

# Show Docker container information
show_containers() {
    print_status "Supabase Docker containers:"
    docker ps --filter label=com.supabase.cli.project=ExpenseTracker --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Test connection
test_connection() {
    print_status "Testing Supabase connection..."
    
    # Test the correct API endpoint, not /health which doesn't exist
    if curl -s http://127.0.0.1:54321/rest/v1/ > /dev/null 2>&1; then
        print_success "Supabase API is responding correctly"
        print_status "Testing database connection..."
        if psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "SELECT version();" > /dev/null 2>&1; then
            print_success "Database connection successful"
        else
            print_warning "Database connection failed"
        fi
    else
        print_error "Supabase API not responding at http://127.0.0.1:54321/rest/v1/"
        print_status "Manual test: Check if http://127.0.0.1:54321/rest/v1/ responds"
    fi
}

# Reset database with safe migrations
reset_database() {
    print_status "Resetting database with stable migrations..."
    supabase db reset --version=0002 --no-seed
    print_success "Database reset completed"
}

# Full setup (fresh installation)
full_setup() {
    print_status "Running full Supabase Docker setup..."
    check_supabase_cli
    check_docker
    start_supabase
    test_connection
    print_success "Full setup completed!"
}

# Show help
show_help() {
    echo "Supabase Docker Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start       Start Supabase services"
    echo "  stop        Stop Supabase services"
    echo "  restart     Restart Supabase services"
    echo "  status      Show current status"
    echo "  info        Show connection information"
    echo "  containers  Show Docker containers"
    echo "  test        Test connection"
    echo "  reset       Reset database to stable state"
    echo "  setup       Full setup (install + start + test)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start      # Start services"
    echo "  $0 status     # Check what's running"
    echo "  $0 setup      # Full fresh setup"
}

# Main script logic
case "${1:-help}" in
    "start")
        check_supabase_cli
        check_docker
        start_supabase
        ;;
    "stop")
        check_supabase_cli
        stop_supabase
        ;;
    "restart")
        check_supabase_cli
        check_docker
        restart_supabase
        ;;
    "status")
        check_supabase_cli
        show_status
        ;;
    "info")
        show_connection_info
        ;;
    "containers")
        check_docker
        show_containers
        ;;
    "test")
        test_connection
        ;;
    "reset")
        check_supabase_cli
        reset_database
        ;;
    "setup")
        full_setup
        ;;
    "help"|*)
        show_help
        ;;
esac