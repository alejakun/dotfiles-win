#!/usr/bin/env pwsh
# ================================================================================
# Windows Essential Applications Installer
# ================================================================================
# Installs common applications using winget
#
# Usage:
#   .\install.ps1           # Install all packages
#   .\install.ps1 -DryRun   # Show what would be installed

param(
    [switch]$DryRun
)

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
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Windows Applications Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if winget is available
Write-Step "Checking winget availability..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found!"
    Write-Host "Please install App Installer from Microsoft Store:" -ForegroundColor Yellow
    Write-Host "  https://www.microsoft.com/p/app-installer/9nblggh4nns1" -ForegroundColor Yellow
    exit 1
}
Write-Success "winget found: $(winget --version)"
Write-Host ""

# Read package list
# Use script directory if available, otherwise use current directory
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$packageFile = Join-Path $scriptDir "winget\packages.txt"
if (-not (Test-Path $packageFile)) {
    Write-Error "Package file not found: $packageFile"
    Write-Host "Script directory: $scriptDir" -ForegroundColor Gray
    Write-Host "Current location: $(Get-Location)" -ForegroundColor Gray
    exit 1
}

Write-Step "Reading package list from: $packageFile"
$packages = Get-Content $packageFile | Where-Object {
    $_ -and $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$'
}

Write-Host "Found $($packages.Count) packages to install" -ForegroundColor White
Write-Host ""

# Dry run mode
if ($DryRun) {
    Write-Warning "DRY RUN MODE - No packages will be installed"
    Write-Host ""
    Write-Host "Packages that would be installed:" -ForegroundColor Yellow
    $packages | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Run without -DryRun to install packages" -ForegroundColor Yellow
    exit 0
}

# Installation
Write-Step "Starting installation..."
Write-Host ""

$installed = 0
$failed = 0
$skipped = 0
$failedPackages = @()

foreach ($package in $packages) {
    Write-Host "📦 Installing: $package" -ForegroundColor Yellow

    try {
        $result = winget install --id $package --silent --accept-package-agreements --accept-source-agreements 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "  Installed: $package"
            $installed++
        } elseif ($result -match "already installed") {
            Write-Host "  ⏭️  Already installed: $package" -ForegroundColor Gray
            $skipped++
        } else {
            Write-Warning "  Failed: $package"
            $failed++
            $failedPackages += $package
        }
    } catch {
        Write-Warning "  Error installing: $package"
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Gray
        $failed++
        $failedPackages += $package
    }

    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✅ Installed:        $installed" -ForegroundColor Green
Write-Host "⏭️  Already installed: $skipped" -ForegroundColor Gray
Write-Host "❌ Failed:           $failed" -ForegroundColor Red
Write-Host ""

if ($failed -gt 0) {
    Write-Warning "Failed packages:"
    $failedPackages | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "See MANUAL_INSTALL.md for manual installation instructions" -ForegroundColor Yellow
}

Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host ""
