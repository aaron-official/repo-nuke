#!/bin/bash

# RepoNuke - Bulk GitHub Repository Deletion Tool
# Cross-platform script for Unix/Linux/macOS
# Author: aaron-official
# License: MIT

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.github-batch-delete.log"
CONFIG_FILE="$HOME/.github-batch-delete"

# Global variables
USERNAME=""
REPOSITORIES=()
AUTO_CONFIRM=false
VERBOSE=false
DRY_RUN=false

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print usage information
usage() {
    cat << EOF
RepoNuke - Bulk GitHub Repository Deletion Tool

Usage: $0 [OPTIONS] [REPOSITORIES...]

OPTIONS:
    -h, --help              Show this help message
    -u, --username USER     Specify GitHub username (e.g., aaron-official)
    -f, --file FILE         Read repository list from file
    -c, --config FILE       Use configuration file (JSON)
    -a, --auto-confirm      Skip confirmation prompts (dangerous!)
    -v, --verbose           Enable verbose output
    -d, --dry-run           Show what would be deleted without deleting
    --interactive           Interactive repository selection mode

EXAMPLES:
    $0 repo1 repo2 repo3                    # Delete specific repositories
    $0 --file repos.txt                     # Delete from file list
    $0 --config repos.json                  # Use JSON configuration
    $0 --username aaron-official repo1 repo2      # Specify username
    $0 --interactive                        # Interactive mode
    $0 --dry-run repo1 repo2                # Preview mode

EOF
}

# Check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_color $RED "❌ GitHub CLI (gh) is not installed!"
        print_color $YELLOW "Please install it first:"
        print_color $BLUE "  macOS: brew install gh"
        print_color $BLUE "  Linux: sudo apt install gh"
        exit 1
    fi
}

# Check authentication and permissions
check_auth() {
    print_color $BLUE "🔍 Checking GitHub authentication..."
    
    if ! gh auth status &> /dev/null; then
        print_color $RED "❌ Not authenticated with GitHub!"
        print_color $YELLOW "Please run: gh auth login"
        exit 1
    fi
    
    # Check if we have delete_repo scope
    if ! gh api user --silent 2>/dev/null; then
        print_color $YELLOW "⚠️  Checking delete permissions..."
        if ! gh auth refresh -h github.com -s delete_repo 2>/dev/null; then
            print_color $RED "❌ Failed to get delete permissions!"
            print_color $YELLOW "Please run: gh auth refresh -h github.com -s delete_repo"
            exit 1
        fi
    fi
    
    print_color $GREEN "✅ Authentication verified"
}

# Get current GitHub username
get_username() {
    if [ -z "$USERNAME" ]; then
        USERNAME=$(gh api user --jq '.login' 2>/dev/null || echo "")
        if [ -z "$USERNAME" ]; then
            print_color $RED "❌ Could not determine GitHub username"
        fi
    fi
    print_color $CYAN "👤 Using GitHub username: $USERNAME"
}

# List user repositories
list_repositories() {
    print_color $BLUE "📋 Fetching your repositories..."
    gh repo list "$USERNAME" --limit 100 --json name --jq '.[].name'
}

# Interactive repository selection
interactive_selection() {
    print_color $YELLOW "🎯 Interactive Repository Selection"
    print_color $BLUE "Available repositories:"
    
    local repos=($(list_repositories))
    local selected=()
    
    if [ ${#repos[@]} -eq 0 ]; then
        print_color $YELLOW "No repositories found for user: $USERNAME"
        exit 0
    fi
    
    echo ""
    for i in "${!repos[@]}"; do
        printf "%3d) %s\n" $((i+1)) "${repos[i]}"
    done
    
    echo ""
    print_color $CYAN "Enter repository numbers to delete (space-separated, e.g., 1 3 5):"
    print_color $YELLOW "Or enter 'all' to select all repositories"
    read -r selection
    
    if [ "$selection" = "all" ]; then
        REPOSITORIES=("${repos[@]}")
    else
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#repos[@]}" ]; then
                selected+=("${repos[$((num-1))]}")
            else
                print_color $YELLOW "⚠️  Skipping invalid selection: $num"
            fi
        done
        REPOSITORIES=("${selected[@]}")
    fi
    
    if [ ${#REPOSITORIES[@]} -eq 0 ]; then
        print_color $YELLOW "No repositories selected. Exiting."
        exit 0
    fi
}

# Load repositories from file
load_from_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        print_color $RED "❌ File not found: $file"
        exit 1
    fi
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            REPOSITORIES+=("$line")
        fi
    done < "$file"
    
    print_color $GREEN "📂 Loaded ${#REPOSITORIES[@]} repositories from $file"
}

# Load configuration from JSON file
load_config() {
    local config_file=$1
    if [ ! -f "$config_file" ]; then
        print_color $RED "❌ Configuration file not found: $config_file"
        exit 1
    fi
    
    if command -v jq &> /dev/null; then
        USERNAME=$(jq -r '.username // empty' "$config_file")
        readarray -t REPOSITORIES < <(jq -r '.repositories[]?' "$config_file")
    else
        print_color $YELLOW "⚠️  jq not installed, using basic parsing"
        # Basic parsing without jq (not as robust)
        USERNAME=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$config_file" | cut -d'"' -f4)
        readarray -t REPOSITORIES < <(grep -o '"[^"]*"' "$config_file" | grep -v username | sed 's/"//g')
    fi
    
    print_color $GREEN "⚙️  Loaded configuration from $config_file"
}

# Validate repository exists
validate_repository() {
    local repo=$1
    if gh repo view "$USERNAME/$repo" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Delete single repository
delete_repository() {
    local repo=$1
    local success=false
    
    if [ "$DRY_RUN" = true ]; then
        print_color $BLUE "[DRY RUN] Would delete: $USERNAME/$repo"
        return 0
    fi
    
    if [ "$VERBOSE" = true ]; then
        print_color $BLUE "🗑️  Deleting repository: $USERNAME/$repo"
    fi
    
    if gh repo delete "$USERNAME/$repo" --yes 2>/dev/null; then
        success=true
        print_color $GREEN "✅ Successfully deleted: $USERNAME/$repo"
        log "SUCCESS: Deleted repository $USERNAME/$repo"
    else
        print_color $RED "❌ Failed to delete: $USERNAME/$repo"
        log "FAILED: Could not delete repository $USERNAME/$repo"
    fi
    
    return $success
}

# Main deletion process
batch_delete() {
    local total=${#REPOSITORIES[@]}
    local successful=0
    local failed=0
    local current=0
    
    print_color $YELLOW "🚀 Starting batch deletion process..."
    print_color $BLUE "Total repositories to delete: $total"
    echo ""
    
    # Validate repositories first
    local valid_repos=()
    for repo in "${REPOSITORIES[@]}"; do
        if validate_repository "$repo"; then
            valid_repos+=("$repo")
        else
            print_color $YELLOW "⚠️  Repository not found or inaccessible: $USERNAME/$repo"
            ((failed++))
        fi
    done
    
    if [ ${#valid_repos[@]} -eq 0 ]; then
        print_color $RED "❌ No valid repositories found to delete"
        exit 1
    fi
    
    # Show final confirmation
    if [ "$AUTO_CONFIRM" = false ]; then
        print_color $CYAN "Repositories to be deleted:"
        for repo in "${valid_repos[@]}"; do
            echo "  - $USERNAME/$repo"
        done
        echo ""
        
        if [ "$DRY_RUN" = false ]; then
            print_color $RED "⚠️  WARNING: This action is IRREVERSIBLE!"
            print_color $YELLOW "⚠️  Make sure you have backups of important code!"
            echo ""
        fi
        
        read -p "$(print_color $YELLOW 'Are you absolutely sure? Type "DELETE" to confirm: ')" confirmation
        if [ "$confirmation" != "DELETE" ]; then
            print_color $BLUE "Operation cancelled."
            exit 0
        fi
    fi
    
    echo ""
    print_color $GREEN "🔄 Processing deletions..."
    
    # Delete repositories
    for repo in "${valid_repos[@]}"; do
        ((current++))
        printf "[%d/%d] " "$current" "${#valid_repos[@]}"
        
        if delete_repository "$repo"; then
            ((successful++))
        else
            ((failed++))
        fi
        
        # Small delay to avoid rate limiting
        sleep 0.5
    done
    
    # Summary
    echo ""
    print_color $CYAN "📊 Deletion Summary:"
    print_color $GREEN "  ✅ Successfully processed: $successful repositories"
    print_color $RED "  ❌ Failed to process: $failed repositories"
    print_color $BLUE "  📋 Total processed: $((successful + failed)) repositories"
    
    if [ "$DRY_RUN" = false ]; then
        log "SUMMARY: Processed $((successful + failed)) repositories, $successful successful, $failed failed"
    fi
    
    if [ $failed -gt 0 ]; then
        echo ""
        print_color $YELLOW "⚠️  Some operations failed. Check the log file: $LOG_FILE"
    fi
    
    print_color $GREEN "🎉 Batch deletion process completed!"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -u|--username)
                USERNAME="$2"
                shift 2
                ;;
            -f|--file)
                load_from_file "$2"
                shift 2
                ;;
            -c|--config)
                load_config "$2"
                shift 2
                ;;
            -a|--auto-confirm)
                AUTO_CONFIRM=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --interactive)
                interactive_selection
                shift
                ;;
            -*)
                print_color $RED "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                REPOSITORIES+=("$1")
                shift
                ;;
        esac
    done
}

# Main function
main() {
    print_color $BLUE "🔧 RepoNuke - Bulk GitHub Repository Deletion Tool"
    print_color $BLUE "======================================"
    
    # Initialize log
    log "Starting GitHub Batch Delete session"
    
    # Check prerequisites
    check_gh_cli
    check_auth
    get_username
    
    # Parse arguments
    parse_args "$@"
    
    # If no repositories specified, use interactive mode
    if [ ${#REPOSITORIES[@]} -eq 0 ]; then
        interactive_selection
    fi
    
    # Validate we have repositories to delete
    if [ ${#REPOSITORIES[@]} -eq 0 ]; then
        print_color $YELLOW "No repositories specified for deletion."
        usage
        exit 0
    fi
    
    # Start deletion process
    batch_delete
}

# Run main function with all arguments
main "$@"