#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap Installer
# ================================================================================
# One-line installation (mini profile - default):
#   iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
#
# Install a specific profile. Each one extends the ones below it, so "plus"
# installs mini + base + plus:
#   $env:DOTFILES_PROFILE="base"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
#   $env:DOTFILES_PROFILE="plus"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
#   $env:DOTFILES_PROFILE="pro"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
#   $env:DOTFILES_PROFILE="max"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
#
# What this does:
#   1. Checks prerequisites (winget)
#   2. Downloads installation files from GitHub
#   3. Installs all applications via winget
#
# Usage:
#   Invoke-WebRequest -useb URL | Invoke-Expression
#   OR
#   iwr -useb URL | iex

# Read the profile from the environment variable or use the smallest one
$InstallProfile = if ($env:DOTFILES_PROFILE) { $env:DOTFILES_PROFILE.Trim() } else { "mini" }
$ValidProfiles = @("mini", "base", "plus", "pro", "max")

if ($InstallProfile -notin $ValidProfiles) {
    Write-Host "[-] Invalid profile: $InstallProfile" -ForegroundColor Red
    Write-Host "Valid profiles: mini, base, plus, pro, max" -ForegroundColor Yellow
    exit 1
}

# Configuration
$RepoOwner = "alejakun"
$RepoName = "dotfiles-win"
$Branch = if ($env:DOTFILES_BRANCH) { $env:DOTFILES_BRANCH } else { "master" }
$BaseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
$InstallDir = Join-Path $env:TEMP "dotfiles-win-install"

# Colors for output
function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

# Header
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   dotfiles-win Bootstrap Installer" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Step "Checking prerequisites..."

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Err "PowerShell 5.0 or higher required"
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    exit 1
}
Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"

# Check winget availability
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "winget not found!"
    Write-Host ""
    Write-Host "winget is required for this installation." -ForegroundColor Yellow
    Write-Host "Install App Installer from Microsoft Store:" -ForegroundColor Yellow
    Write-Host "  https://www.microsoft.com/p/app-installer/9nblggh4nns1" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Success "winget found: $(winget --version)"
Write-Host ""

# Create temporary directory
Write-Step "Creating temporary directory..."
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Write-Success "Created: $InstallDir"
Write-Host ""

# Download installation files
Write-Step "Downloading installation files from GitHub..."

# install.ps1 owns the ladder, so just fetch every list - they are a few hundred
# bytes each and this keeps that rule in one place.
$allProfiles = @("mini", "base", "plus", "pro", "max")

# Recreate the repository layout install.ps1 expects
New-Item -ItemType Directory -Path (Join-Path $InstallDir "winget") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $InstallDir "npm") -Force | Out-Null

$files = @(
    @{
        Url = "$BaseUrl/install.ps1"
        Path = Join-Path $InstallDir "install.ps1"
        Name = "install.ps1"
        Required = $true
    }
)

foreach ($prof in $allProfiles) {
    # winget lists are mandatory, npm lists are optional (not every profile has one)
    $files += @{
        Url = "$BaseUrl/winget/packages-$prof.txt"
        Path = Join-Path $InstallDir "winget\packages-$prof.txt"
        Name = "winget/packages-$prof.txt"
        Required = $true
    }
    $files += @{
        Url = "$BaseUrl/npm/packages-$prof.txt"
        Path = Join-Path $InstallDir "npm\packages-$prof.txt"
        Name = "npm/packages-$prof.txt"
        Required = $false
    }
}

$downloadSuccess = $true
foreach ($file in $files) {
    Write-Host "  Downloading: $($file.Name)..." -ForegroundColor Yellow
    Write-Host "    URL: $($file.Url)" -ForegroundColor Gray

    try {
        Invoke-WebRequest -Uri $file.Url -OutFile $file.Path -UseBasicParsing
        Write-Success "    Downloaded: $($file.Name)"
    } catch {
        if ($file.Required) {
            Write-Err "    Failed to download: $($file.Name)"
            Write-Host "    URL: $($file.Url)" -ForegroundColor Gray
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
            $downloadSuccess = $false
        } else {
            Write-Host "    Skipped (no such list in the repo): $($file.Name)" -ForegroundColor DarkGray
            if (Test-Path $file.Path) { Remove-Item -Path $file.Path -Force }
        }
    }
}

Write-Host ""

if (-not $downloadSuccess) {
    Write-Err "Some files failed to download"
    Write-Host "Please check your internet connection and try again" -ForegroundColor Yellow
    exit 1
}

# Execute installation
Write-Step "Starting installation..."
Write-Host ""

try {
    # Execute install.ps1 in the correct directory
    $installScript = Join-Path $InstallDir "install.ps1"

    # Save current location
    $previousLocation = Get-Location

    try {
        # Change to install directory
        Set-Location $InstallDir

        # Execute the script directly
        & $installScript -InstallProfile $InstallProfile

        $exitCode = $LASTEXITCODE
    } finally {
        # Restore previous location
        Set-Location $previousLocation
    }

    Write-Host ""

    if ($exitCode -eq 0) {
        Write-Success "Installation completed successfully!"
    } else {
        Write-Warn "Installation completed with errors (exit code: $exitCode)"
    }

} catch {
    Write-Err "Installation failed"
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
    exit 1
}

# Cleanup
Write-Host ""
Write-Step "Cleaning up temporary files..."
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
    Write-Success "Cleanup complete"
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Bootstrap Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
