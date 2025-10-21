#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap Installer
# ================================================================================
# One-line installation:
#   iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
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

param(
    [switch]$DryRun,
    [string]$Branch = "master"
)

# Configuration
$RepoOwner = "alejakun"
$RepoName = "dotfiles-win"
$BaseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
$InstallDir = Join-Path $env:TEMP "dotfiles-win-install"

# Colors for output
function Write-Step {
    param([string]$Message)
    Write-Host "🔧 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
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
    Write-Error "PowerShell 5.0 or higher required"
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    exit 1
}
Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"

# Check winget availability
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found!"
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

$files = @(
    @{
        Url = "$BaseUrl/install.ps1"
        Path = Join-Path $InstallDir "install.ps1"
        Name = "install.ps1"
    },
    @{
        Url = "$BaseUrl/winget/packages.txt"
        Path = Join-Path $InstallDir "packages.txt"
        Name = "winget/packages.txt"
    }
)

$downloadSuccess = $true
foreach ($file in $files) {
    Write-Host "  Downloading: $($file.Name)..." -ForegroundColor Yellow
    Write-Host "    URL: $($file.Url)" -ForegroundColor Gray

    try {
        Invoke-WebRequest -Uri $file.Url -OutFile $file.Path -UseBasicParsing
        Write-Success "    Downloaded: $($file.Name)"
    } catch {
        Write-Error "    Failed to download: $($file.Name)"
        Write-Host "    URL: $($file.Url)" -ForegroundColor Gray
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
        $downloadSuccess = $false
    }
}

Write-Host ""

if (-not $downloadSuccess) {
    Write-Error "Some files failed to download"
    Write-Host "Please check your internet connection and try again" -ForegroundColor Yellow
    exit 1
}

# Execute installation
Write-Step "Starting installation..."
Write-Host ""

try {
    # Create winget directory for packages.txt
    $wingetDir = Join-Path $InstallDir "winget"
    New-Item -ItemType Directory -Path $wingetDir -Force | Out-Null

    # Move packages.txt to winget directory
    $packagesSource = Join-Path $InstallDir "packages.txt"
    $packagesDest = Join-Path $wingetDir "packages.txt"
    Move-Item -Path $packagesSource -Destination $packagesDest -Force

    # Execute install.ps1 in the correct directory
    $installScript = Join-Path $InstallDir "install.ps1"

    # Save current location
    $previousLocation = Get-Location

    try {
        # Change to install directory
        Set-Location $InstallDir

        # Execute the script directly
        if ($DryRun) {
            & $installScript -DryRun
        } else {
            & $installScript
        }

        $exitCode = $LASTEXITCODE
    } finally {
        # Restore previous location
        Set-Location $previousLocation
    }

    Write-Host ""

    if ($exitCode -eq 0) {
        Write-Success "Installation completed successfully!"
    } else {
        Write-Warning "Installation completed with errors (exit code: $exitCode)"
    }

} catch {
    Write-Error "Installation failed"
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
