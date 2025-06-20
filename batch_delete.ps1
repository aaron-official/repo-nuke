# RepoNuke - Bulk GitHub Repository Deletion Tool
# Cross-platform PowerShell script for Windows
# Author: aaron-official
# License: MIT

param(
    [string[]]$Repositories = @(),
    [string]$Username = "",
    [string]$File = "",
    [string]$Config = "",
    [switch]$AutoConfirm = $false,
    [switch]$Verbose = $false,
    [switch]$DryRun = $false,
    [switch]$Interactive = $false,
    [switch]$Help = $false
)

# Configuration
$LogFile = Join-Path $env:USERPROFILE ".github-batch-delete.log"

# Global variables
$Script:Username = $Username
$Script:RepositoriesToDelete = @()
$Script:TotalProcessed = 0
$Script:SuccessfulDeletions = 0
$Script:FailedDeletions = 0

# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Add-Content -Path $LogFile
}

# Show usage information
function Show-Usage {
    $usage = @"
RepoNuke - Bulk GitHub Repository Deletion Tool

Usage: .\batch-delete.ps1 [OPTIONS] [REPOSITORIES...]

OPTIONS:
    -Username USER          Specify GitHub username (e.g., aaron-official)
    -File FILE             Read repository list from file
    -Config FILE           Use configuration file (JSON)  
    -AutoConfirm           Skip confirmation prompts (dangerous!)
    -Verbose               Enable verbose output
    -DryRun                Show what would be deleted without deleting
    -Interactive           Interactive repository selection mode
    -Help                  Show this help message

EXAMPLES:
    .\batch-delete.ps1 repo1 repo2 repo3                    # Delete specific repositories
    .\batch-delete.ps1 -File repos.txt                      # Delete from file list
    .\batch-delete.ps1 -Config repos.json                   # Use JSON configuration  
    .\batch-delete.ps1 -Username aaron-official repo1 repo2       # Specify username
    .\batch-delete.ps1 -Interactive                         # Interactive mode
    .\batch-delete.ps1 -DryRun repo1 repo2                  # Preview mode
"@
    Write-Host $usage -ForegroundColor Cyan
}

# Check if GitHub CLI is installed
function Test-GitHubCLI {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "GitHub CLI (gh) is not installed!" -ForegroundColor Red
        Write-Host "Please install it first:" -ForegroundColor Yellow
        Write-Host "  Windows: winget install --id GitHub.cli" -ForegroundColor Blue
        exit 1
    }
}

# Check authentication and permissions
function Test-Authentication {
    Write-Host "Checking GitHub authentication..." -ForegroundColor Blue
    
    try {
        & gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Not authenticated with GitHub!" -ForegroundColor Red
            Write-Host "Please run: gh auth login" -ForegroundColor Yellow
            exit 1
        }
    }
    catch {
        Write-Host "Authentication check failed!" -ForegroundColor Red
        Write-Host "Please run: gh auth login" -ForegroundColor Yellow
        exit 1
    }
    
    # Test API access
    try {
        & gh api user --silent 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Checking delete permissions..." -ForegroundColor Yellow
            & gh auth refresh -h github.com -s delete_repo 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Failed to get delete permissions!" -ForegroundColor Red
                Write-Host "Please run: gh auth refresh -h github.com -s delete_repo" -ForegroundColor Yellow
                exit 1
            }
        }
    }
    catch {
        Write-Host "API access test failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Authentication verified" -ForegroundColor Green
}

# Get current GitHub username
function Get-GitHubUsername {
    if ([string]::IsNullOrEmpty($Script:Username)) {
        $Script:Username = & gh api user --jq '.login' 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($Script:Username)) {
            Write-Host "Could not determine GitHub username" -ForegroundColor Red
        }
    }
    Write-Host "Using GitHub username: $($Script:Username)" -ForegroundColor Cyan
}

# List user repositories
function Get-UserRepositories {
    Write-Host "Fetching your repositories..." -ForegroundColor Blue
    try {
        $repos = & gh repo list $Script:Username --limit 100 --json name --jq '.[].name' 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $repos
        }
        else {
            return @()
        }
    }
    catch {
        return @()
    }
}

# Interactive repository selection
function Invoke-InteractiveSelection {
    Write-Host "Interactive Repository Selection" -ForegroundColor Yellow
    Write-Host "Available repositories:" -ForegroundColor Blue
    
    $repos = Get-UserRepositories
    
    if ($repos.Count -eq 0) {
        Write-Host "No repositories found for user: $($Script:Username)" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    for ($i = 0; $i -lt $repos.Count; $i++) {
        Write-Host ("{0,3}) {1}" -f ($i + 1), $repos[$i])
    }
    
    Write-Host ""
    Write-Host "Enter repository numbers to delete (space-separated, e.g., 1 3 5):" -ForegroundColor Cyan
    Write-Host "Or enter 'all' to select all repositories" -ForegroundColor Yellow
    $selection = Read-Host
    
    if ($selection -eq "all") {
        $Script:RepositoriesToDelete = $repos
    }
    else {
        $selectedRepos = @()
        $numbers = $selection -split '\s+'
        foreach ($num in $numbers) {
            if ($num -match '^\d+$' -and [int]$num -ge 1 -and [int]$num -le $repos.Count) {
                $selectedRepos += $repos[[int]$num - 1]
            }
            else {
                Write-Host "Skipping invalid selection: $num" -ForegroundColor Yellow
            }
        }
        $Script:RepositoriesToDelete = $selectedRepos
    }
    
    if ($Script:RepositoriesToDelete.Count -eq 0) {
        Write-Host "No repositories selected. Exiting." -ForegroundColor Yellow
        exit 0
    }
}

# Load repositories from file
function Import-RepositoriesFromFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "File not found: $FilePath" -ForegroundColor Red
        exit 1
    }
    
    $repos = @()
    Get-Content $FilePath | ForEach-Object {
        $line = $_.Trim()
        # Skip empty lines and comments
        if ($line -and -not $line.StartsWith('#')) {
            $repos += $line
        }
    }
    
    $Script:RepositoriesToDelete = $repos
    Write-Host "Loaded $($repos.Count) repositories from $FilePath" -ForegroundColor Green
}

# Load configuration from JSON file
function Import-Configuration {
    param([string]$ConfigPath)
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Configuration file not found: $ConfigPath" -ForegroundColor Red
        exit 1
    }
    
    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        
        if ($config.username) {
            $Script:Username = $config.username
        }
        
        if ($config.repositories) {
            $Script:RepositoriesToDelete = $config.repositories
        }
        
        Write-Host "Loaded configuration from $ConfigPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to parse configuration file: $ConfigPath" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# Validate repository exists
function Test-Repository {
    param([string]$Repository)
    
    try {
        & gh repo view "$($Script:Username)/$Repository" --json name 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

# Delete single repository
function Remove-Repository {
    param([string]$Repository)
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would delete: $($Script:Username)/$Repository" -ForegroundColor Blue
        return $true
    }
    
    if ($Verbose) {
        Write-Host "Deleting repository: $($Script:Username)/$Repository" -ForegroundColor Blue
    }
    
    try {
        & gh repo delete "$($Script:Username)/$Repository" --yes 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully deleted: $($Script:Username)/$Repository" -ForegroundColor Green
            Write-Log "SUCCESS: Deleted repository $($Script:Username)/$Repository"
            return $true
        }
        else {
            Write-Host "Failed to delete: $($Script:Username)/$Repository" -ForegroundColor Red
            Write-Log "FAILED: Could not delete repository $($Script:Username)/$Repository"
            return $false
        }
    }
    catch {
        Write-Host "Failed to delete: $($Script:Username)/$Repository" -ForegroundColor Red
        Write-Log "FAILED: Exception deleting repository $($Script:Username)/$Repository - $($_.Exception.Message)"
        return $false
    }
}

# Main deletion process
function Invoke-BatchDelete {
    $total = $Script:RepositoriesToDelete.Count
    $Script:SuccessfulDeletions = 0
    $Script:FailedDeletions = 0
    $current = 0
    
    Write-Host "Starting batch deletion process..." -ForegroundColor Yellow
    Write-Host "Total repositories to delete: $total" -ForegroundColor Blue
    Write-Host ""
    
    # Validate repositories first
    $validRepos = @()
    foreach ($repo in $Script:RepositoriesToDelete) {
        if (Test-Repository $repo) {
            $validRepos += $repo
        }
        else {
            Write-Host "Repository not found or inaccessible: $($Script:Username)/$repo" -ForegroundColor Yellow
            $Script:FailedDeletions++
        }
    }
    
    if ($validRepos.Count -eq 0) {
        Write-Host "No valid repositories found to delete" -ForegroundColor Red
        exit 1
    }
    
    # Show final confirmation
    if (-not $AutoConfirm) {
        Write-Host "Repositories to be deleted:" -ForegroundColor Cyan
        foreach ($repo in $validRepos) {
            Write-Host "  - $($Script:Username)/$repo"
        }
        Write-Host ""
        if (-not $DryRun) {
            Write-Host "WARNING: This action is IRREVERSIBLE!" -ForegroundColor Red
            Write-Host "Make sure you have backups of important code!" -ForegroundColor Yellow
            Write-Host ""
        }
        # Clean confirmation prompt
        $confirmation = Read-Host "Are you absolutely sure? Type DELETE to confirm"
        if ($confirmation -ne "DELETE") {
            Write-Host "Operation cancelled." -ForegroundColor Blue
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "Processing deletions..." -ForegroundColor Green
    
    # Delete repositories
    foreach ($repo in $validRepos) {
        $current++
        Write-Host "[$current/$($validRepos.Count)] " -NoNewline
        
        if (Remove-Repository $repo) {
            $Script:SuccessfulDeletions++
        }
        else {
            $Script:FailedDeletions++
        }
        
        # Small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
    }
    
    # Summary
    Write-Host ""
    Write-Host "Deletion Summary:" -ForegroundColor Cyan
    Write-Host "  Successfully processed: $($Script:SuccessfulDeletions) repositories" -ForegroundColor Green
    Write-Host "  Failed to process: $($Script:FailedDeletions) repositories" -ForegroundColor Red
    Write-Host "  Total processed: $($Script:SuccessfulDeletions + $Script:FailedDeletions) repositories" -ForegroundColor Blue
    
    if (-not $DryRun) {
        Write-Log "SUMMARY: Processed $($Script:SuccessfulDeletions + $Script:FailedDeletions) repositories, $($Script:SuccessfulDeletions) successful, $($Script:FailedDeletions) failed"
    }
    
    if ($Script:FailedDeletions -gt 0) {
        Write-Host ""
        Write-Host "Some operations failed. Check the log file: $LogFile" -ForegroundColor Yellow
    }
    
    Write-Host "Batch deletion process completed!" -ForegroundColor Green
}

# Main execution
function Main {
    Write-Host "RepoNuke - Bulk GitHub Repository Deletion Tool" -ForegroundColor Blue
    Write-Host "======================================" -ForegroundColor Blue
    
    # Show help if requested
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    # Initialize log
    Write-Log "Starting GitHub Batch Delete session"
    
    # Check prerequisites
    Test-GitHubCLI
    Test-Authentication
    Get-GitHubUsername
    
    # Process input parameters
    if ($Config) {
        Import-Configuration $Config
    }
    elseif ($File) {
        Import-RepositoriesFromFile $File
    }
    elseif ($Interactive) {
        Invoke-InteractiveSelection
    }
    elseif ($Repositories.Count -gt 0) {
        $Script:RepositoriesToDelete = $Repositories
    }
    else {
        # No repositories specified, use interactive mode
        Invoke-InteractiveSelection
    }
    
    # Validate we have repositories to delete
    if ($Script:RepositoriesToDelete.Count -eq 0) {
        Write-Host "No repositories specified for deletion." -ForegroundColor Yellow
        Show-Usage
        exit 0
    }
    
    # Start deletion process
    Invoke-BatchDelete
}

# Run main function
Main