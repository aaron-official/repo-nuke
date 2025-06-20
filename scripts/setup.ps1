# Windows setup script

# Install GitHub CLI if not present
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Installing GitHub CLI via winget..." -ForegroundColor Cyan
    winget install --id GitHub.cli
} else {
    Write-Host "GitHub CLI already installed." -ForegroundColor Green
}

# (Optional) Install jq for JSON parsing
if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
    Write-Host "Installing jq via winget..." -ForegroundColor Cyan
    winget install --id stedolan.jq
} else {
    Write-Host "jq already installed." -ForegroundColor Green
}

# No Python dependencies required for RepoNuke
