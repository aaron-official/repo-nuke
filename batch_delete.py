#!/usr/bin/env python3
"""
RepoNuke - Bulk GitHub Repository Deletion Tool
Cross-platform Python script
Author: aaron-official
License: MIT
"""

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import List, Optional

# Configuration
LOG_FILE = Path.home() / ".github-batch-delete.log"
CONFIG_FILE = Path.home() / ".github-batch-delete"

# Global state
class BatchDeleter:
    def __init__(self):
        self.username = ""
        self.repositories = []
        self.successful_deletions = 0
        self.failed_deletions = 0
        self.verbose = False
        self.dry_run = False
    
    def log(self, message: str):
        """Log message to file with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"{timestamp} - {message}\n")
    
    def print_color(self, message: str, color: str = ""):
        """Print colored output"""
        colors = {
            "red": "\033[0;31m",
            "green": "\033[0;32m",
            "yellow": "\033[1;33m",
            "blue": "\033[0;34m",
            "cyan": "\033[0;36m",
            "reset": "\033[0m"
        }
        
        if color and color in colors:
            print(f"{colors[color]}{message}{colors['reset']}")
        else:
            print(message)
    
    def check_gh_cli(self):
        """Check if GitHub CLI is installed"""
        try:
            subprocess.run(["gh", "--version"], 
                         capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.print_color("❌ GitHub CLI (gh) is not installed!", "red")
            self.print_color("Please install it first:", "yellow")
            self.print_color("  Windows: winget install --id GitHub.cli", "blue")
            self.print_color("  macOS: brew install gh", "blue")
            self.print_color("  Linux: sudo apt install gh", "blue")
            sys.exit(1)
    
    def check_auth(self):
        """Check authentication and permissions"""
        self.print_color("🔍 Checking GitHub authentication...", "blue")
        
        try:
            subprocess.run(["gh", "auth", "status"], 
                         capture_output=True, check=True)
        except subprocess.CalledProcessError:
            self.print_color("❌ Not authenticated with GitHub!", "red")
            self.print_color("Please run: gh auth login", "yellow")
            sys.exit(1)
        
        # Check if we have delete_repo scope
        try:
            subprocess.run(["gh", "api", "user", "--silent"], 
                         capture_output=True, check=True)
        except subprocess.CalledProcessError:
            self.print_color("⚠️  Checking delete permissions...", "yellow")
            try:
                subprocess.run(["gh", "auth", "refresh", "-h", "github.com", 
                              "-s", "delete_repo"], 
                             capture_output=True, check=True)
            except subprocess.CalledProcessError:
                self.print_color("❌ Failed to get delete permissions!", "red")
                self.print_color("Please run: gh auth refresh -h github.com -s delete_repo", "yellow")
                sys.exit(1)
        
        self.print_color("✅ Authentication verified", "green")
    
    def get_username(self):
        """Get current GitHub username"""
        if not self.username:
            result = subprocess.run(["gh", "api", "user", "--jq", ".login"], capture_output=True, text=True)
            if result.returncode == 0:
                self.username = result.stdout.strip()
            else:
                self.print_color("❌ Could not determine GitHub username", "red")
        self.print_color(f"👤 Using GitHub username: {self.username}", "cyan")
    
    def list_repositories(self) -> List[str]:
        """List user repositories"""
        self.print_color("📋 Fetching your repositories...", "blue")
        try:
            result = subprocess.run([
                "gh", "repo", "list", self.username, 
                "--limit", "100", "--json", "name", "--jq", ".[].name"
            ], capture_output=True, text=True, check=True)
            return [repo.strip() for repo in result.stdout.split('\n') if repo.strip()]
        except subprocess.CalledProcessError:
            return []
    
    def interactive_selection(self):
        """Interactive repository selection"""
        self.print_color("🎯 Interactive Repository Selection", "yellow")
        self.print_color("Available repositories:", "blue")
        
        repos = self.list_repositories()
        
        if not repos:
            self.print_color(f"No repositories found for user: {self.username}", "yellow")
            sys.exit(0)
        
        print()
        for i, repo in enumerate(repos, 1):
            print(f"{i:3d}) {repo}")
        
        print()
        self.print_color("Enter repository numbers to delete (space-separated, e.g., 1 3 5):", "cyan")
        self.print_color("Or enter 'all' to select all repositories", "yellow")
        
        try:
            selection = input().strip()
        except KeyboardInterrupt:
            print("\nOperation cancelled.")
            sys.exit(0)
        
        if selection.lower() == "all":
            self.repositories = repos
        else:
            selected = []
            for num_str in selection.split():
                try:
                    num = int(num_str)
                    if 1 <= num <= len(repos):
                        selected.append(repos[num - 1])
                    else:
                        self.print_color(f"⚠️  Skipping invalid selection: {num_str}", "yellow")
                except ValueError:
                    self.print_color(f"⚠️  Skipping invalid selection: {num_str}", "yellow")
            self.repositories = selected
        
        if not self.repositories:
            self.print_color("No repositories selected. Exiting.", "yellow")
            sys.exit(0)
    
    def load_from_file(self, file_path: str):
        """Load repositories from file"""
        if not os.path.exists(file_path):
            self.print_color(f"❌ File not found: {file_path}", "red")
            sys.exit(1)
        
        repos = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    # Skip empty lines and comments
                    if line and not line.startswith('#'):
                        repos.append(line)
        except Exception as e:
            self.print_color(f"❌ Error reading file: {e}", "red")
            sys.exit(1)
        
        self.repositories = repos
        self.print_color(f"📂 Loaded {len(repos)} repositories from {file_path}", "green")
    
    def load_config(self, config_path: str):
        """Load configuration from JSON file"""
        if not os.path.exists(config_path):
            self.print_color(f"❌ Configuration file not found: {config_path}", "red")
            sys.exit(1)
        
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            if 'username' in config and config['username']:
                self.username = config['username']
            
            if 'repositories' in config and config['repositories']:
                self.repositories = config['repositories']
            
            self.print_color(f"⚙️  Loaded configuration from {config_path}", "green")
        
        except json.JSONDecodeError as e:
            self.print_color(f"❌ Failed to parse configuration file: {e}", "red")
            sys.exit(1)
        except Exception as e:
            self.print_color(f"❌ Error loading configuration: {e}", "red")
            sys.exit(1)
    
    def validate_repository(self, repo: str) -> bool:
        """Validate repository exists"""
        try:
            subprocess.run(["gh", "repo", "view", f"{self.username}/{repo}"], 
                         capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False
    
    def delete_repository(self, repo: str) -> bool:
        """Delete single repository"""
        if self.dry_run:
            self.print_color(f"[DRY RUN] Would delete: {self.username}/{repo}", "blue")
            return True
        
        if self.verbose:
            self.print_color(f"🗑️  Deleting repository: {self.username}/{repo}", "blue")
        
        try:
            subprocess.run(["gh", "repo", "delete", f"{self.username}/{repo}", "--yes"], 
                         capture_output=True, check=True)
            self.print_color(f"✅ Successfully deleted: {self.username}/{repo}", "green")
            self.log(f"SUCCESS: Deleted repository {self.username}/{repo}")
            return True
        except subprocess.CalledProcessError:
            self.print_color(f"❌ Failed to delete: {self.username}/{repo}", "red")
            self.log(f"FAILED: Could not delete repository {self.username}/{repo}")
            return False
    
    def batch_delete(self, auto_confirm: bool = False):
        """Main deletion process"""
        total = len(self.repositories)
        self.successful_deletions = 0
        self.failed_deletions = 0
        
        self.print_color("🚀 Starting batch deletion process...", "yellow")
        self.print_color(f"Total repositories to delete: {total}", "blue")
        print()
        
        # Validate repositories first
        valid_repos = []
        for repo in self.repositories:
            if self.validate_repository(repo):
                valid_repos.append(repo)
            else:
                self.print_color(f"⚠️  Repository not found or inaccessible: {self.username}/{repo}", "yellow")
                self.failed_deletions += 1
        
        if not valid_repos:
            self.print_color("❌ No valid repositories found to delete", "red")
            sys.exit(1)
        
        # Show final confirmation
        if not auto_confirm:
            self.print_color("Repositories to be deleted:", "cyan")
            for repo in valid_repos:
                print(f"  - {self.username}/{repo}")
            print()
            
            if not self.dry_run:
                self.print_color("⚠️  WARNING: This action is IRREVERSIBLE!", "red")
                self.print_color("⚠️  Make sure you have backups of important code!", "yellow")
                print()
            
            try:
                confirmation = input("Are you absolutely sure? Type 'DELETE' to confirm: ")
                if confirmation != "DELETE":
                    self.print_color("Operation cancelled.", "blue")
                    sys.exit(0)
            except KeyboardInterrupt:
                print("\nOperation cancelled.")
                sys.exit(0)
        
        print()
        self.print_color("🔄 Processing deletions...", "green")
        
        # Delete repositories
        for i, repo in enumerate(valid_repos, 1):
            print(f"[{i}/{len(valid_repos)}] ", end="", flush=True)
            
            if self.delete_repository(repo):
                self.successful_deletions += 1
            else:
                self.failed_deletions += 1
            
            # Small delay to avoid rate limiting
            time.sleep(0.5)
        
        # Summary
        print()
        self.print_color("📊 Deletion Summary:", "cyan")
        self.print_color(f"  ✅ Successfully processed: {self.successful_deletions} repositories", "green")
        self.print_color(f"  ❌ Failed to process: {self.failed_deletions} repositories", "red")
        self.print_color(f"  📋 Total processed: {self.successful_deletions + self.failed_deletions} repositories", "blue")
        
        if not self.dry_run:
            self.log(f"SUMMARY: Processed {self.successful_deletions + self.failed_deletions} repositories, {self.successful_deletions} successful, {self.failed_deletions} failed")
        
        if self.failed_deletions > 0:
            print()
            self.print_color(f"⚠️  Some operations failed. Check the log file: {LOG_FILE}", "yellow")
        
        self.print_color("🎉 Batch deletion process completed!", "green")


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="RepoNuke - Bulk GitHub Repository Deletion Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s repo1 repo2 repo3                    # Delete specific repositories
  %(prog)s --file repos.txt                     # Delete from file list
  %(prog)s --config repos.json                  # Use JSON configuration
  %(prog)s --username john-doe repo1 repo2      # Specify username
  %(prog)s --interactive                        # Interactive mode
  %(prog)s --dry-run repo1 repo2                # Preview mode
        """
    )
    
    parser.add_argument("repositories", nargs="*", help="Repository names to delete")
    parser.add_argument("-u", "--username", help="Specify GitHub username")
    parser.add_argument("-f", "--file", help="Read repository list from file")
    parser.add_argument("-c", "--config", help="Use configuration file (JSON)")
    parser.add_argument("-a", "--auto-confirm", action="store_true", 
                       help="Skip confirmation prompts (dangerous!)")
    parser.add_argument("-v", "--verbose", action="store_true", 
                       help="Enable verbose output")
    parser.add_argument("-d", "--dry-run", action="store_true", 
                       help="Show what would be deleted without deleting")
    parser.add_argument("--interactive", action="store_true", 
                       help="Interactive repository selection mode")
    
    args = parser.parse_args()
    
    # Create deleter instance
    deleter = BatchDeleter()
    deleter.verbose = args.verbose
    deleter.dry_run = args.dry_run
    
    if args.username:
        deleter.username = args.username
    
    deleter.print_color("🔧 RepoNuke - Bulk GitHub Repository Deletion Tool", "blue")
    deleter.print_color("======================================", "blue")
    
    # Initialize log
    deleter.log("Starting GitHub Batch Delete session")
    
    # Check prerequisites
    deleter.check_gh_cli()
    deleter.check_auth()
    deleter.get_username()
    
    # Process input parameters
    if args.config:
        deleter.load_config(args.config)
    
    if args.file:
        deleter.load_from_file(args.file)
    
    # Add command line repositories
    if args.repositories:
        deleter.repositories.extend(args.repositories)
    
    # Use interactive mode if no repositories specified
    if args.interactive or not deleter.repositories:
        deleter.interactive_selection()
    
    # Validate we have repositories to delete
    if not deleter.repositories:
        deleter.print_color("No repositories specified for deletion.", "yellow")
        parser.print_help()
        sys.exit(0)
    
    # Start deletion process
    deleter.batch_delete(args.auto_confirm)


if __name__ == "__main__":
    main()
