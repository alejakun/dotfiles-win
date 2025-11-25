#!/usr/bin/env pwsh
# ================================================================================
# Windows Essential Applications Installer
# ================================================================================
# Installs common applications using winget
#
# Usage:
#   .\install.ps1                # Install all packages
#   .\install.ps1 -DryRun        # Show what would be installed
#   .\install.ps1 -ShowCommands  # Display individual winget commands
#   .\install.ps1 -Help          # Show help message

param(
    [switch]$DryRun,
    [switch]$ShowCommands,
    [switch]$Help,
    [ValidateSet("home", "personal", "dev", "infra", "full")]
    [string]$Profile = "home"
)

# Colors for output
function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

# Helper function to read packages from profile files
function Get-PackagesFromProfile {
    param(
        [string]$PackageType,  # "winget" or "npm"
        [string]$Profile,
        [string]$ScriptDir
    )

    if ($Profile -eq "full") {
        $profileFiles = @("home", "personal", "dev", "infra")
        $allPackages = @()

        foreach ($prof in $profileFiles) {
            $packageFile = Join-Path $ScriptDir "$PackageType\packages-$prof.txt"

            if (Test-Path $packageFile) {
                $profilePackages = Get-Content $packageFile | Where-Object {
                    $_ -and $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$'
                }
                $allPackages += $profilePackages
            }
        }

        return $allPackages | Select-Object -Unique
    } else {
        $packageFile = Join-Path $ScriptDir "$PackageType\packages-$Profile.txt"

        if (Test-Path $packageFile) {
            return Get-Content $packageFile | Where-Object {
                $_ -and $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$'
            }
        }

        return @()
    }
}

# Show help if requested
if ($Help) {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Windows Applications Installer - Help" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\install.ps1                      Install home profile (default)"
    Write-Host "  .\install.ps1 -Profile home        Family/essential apps"
    Write-Host "  .\install.ps1 -Profile personal    Personal productivity tools"
    Write-Host "  .\install.ps1 -Profile dev         Development tools"
    Write-Host "  .\install.ps1 -Profile infra       Infrastructure/virtualization"
    Write-Host "  .\install.ps1 -Profile full        Everything combined"
    Write-Host "  .\install.ps1 -DryRun              Preview packages without installing"
    Write-Host "  .\install.ps1 -ShowCommands        Display individual winget commands"
    Write-Host "  .\install.ps1 -Help                Show this help message"
    Write-Host ""
    Write-Host "PROFILES:" -ForegroundColor Yellow
    Write-Host "  home     - Essential apps for family computers (DEFAULT)"
    Write-Host "             Git, VSCode, browsers, Dropbox, Zoom, etc."
    Write-Host "  personal - Personal productivity (Windows Terminal, Teams, VLC, etc.)"
    Write-Host "  dev      - Development tools (Claude, Python, Cloud CLIs, editors)"
    Write-Host "  infra    - Infrastructure (Docker, VMware, Vagrant, DBeaver)"
    Write-Host "  full     - All profiles combined"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Family computer (default)"
    Write-Host "  .\install.ps1"
    Write-Host ""
    Write-Host "  # Your personal workstation"
    Write-Host "  .\install.ps1 -Profile home"
    Write-Host "  .\install.ps1 -Profile personal"
    Write-Host "  .\install.ps1 -Profile dev"
    Write-Host ""
    Write-Host "  # Everything at once"
    Write-Host "  .\install.ps1 -Profile full"
    Write-Host ""
    Write-Host "  # Preview what would be installed"
    Write-Host "  .\install.ps1 -Profile personal -DryRun"
    Write-Host ""
    Write-Host "  # See individual commands to copy/paste"
    Write-Host "  .\install.ps1 -ShowCommands -Profile dev"
    Write-Host ""
    exit 0
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

# Read package list based on profile
# Use script directory if available, otherwise use current directory
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

Write-Step "Reading winget package list..."
Write-Host "Script directory: $scriptDir" -ForegroundColor Gray
Write-Host "Current location: $(Get-Location)" -ForegroundColor Gray

$packages = Get-PackagesFromProfile -PackageType "winget" -Profile $Profile -ScriptDir $scriptDir

if ($packages.Count -eq 0) {
    Write-Error "No winget packages found for profile: $Profile"
    Write-Host "Available profiles: home, personal, dev, infra, full" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($packages.Count) packages to install" -ForegroundColor White
Write-Host ""

# Show commands mode
if ($ShowCommands) {
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Individual Installation Commands" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Copy and paste these commands to install packages individually:" -ForegroundColor Yellow
    Write-Host ""
    $packages | ForEach-Object {
        Write-Host "winget install --id $_ -e --source winget" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "TIP: Use these commands to install only specific packages" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

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
    Write-Host "[>] Processing: $package" -ForegroundColor Yellow

    # Check if already installed (fast check)
    $checkResult = winget list --id $package --exact 2>&1
    $isInstalled = $LASTEXITCODE -eq 0

    if ($isInstalled) {
        Write-Host "  [=] Already installed: $package" -ForegroundColor Gray
        $skipped++
    } else {
        # Not installed, proceed with installation
        Write-Host "  [*] Installing..." -ForegroundColor Cyan

        try {
            $installResult = winget install --id $package --exact --silent --accept-package-agreements --accept-source-agreements 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Success "  Installed: $package"
                $installed++
            } else {
                Write-Warning "  Failed: $package"
                Write-Host "  Error details:" -ForegroundColor Gray
                $installResult | ForEach-Object {
                    if ($_ -and $_ -notmatch '^\s*$') {
                        Write-Host "    $_" -ForegroundColor DarkGray
                    }
                }
                $failed++
                $failedPackages += $package
            }
        } catch {
            Write-Warning "  Error installing: $package"
            Write-Host "    $($_.Exception.Message)" -ForegroundColor Gray
            $failed++
            $failedPackages += $package
        }
    }

    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Installation Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "[+] Installed:        $installed" -ForegroundColor Green
Write-Host "[=] Already installed: $skipped" -ForegroundColor Gray
Write-Host "[-] Failed:           $failed" -ForegroundColor Red
Write-Host ""

if ($failed -gt 0) {
    Write-Warning "Failed packages:"
    $failedPackages | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "See MANUAL_INSTALL.md for manual installation instructions" -ForegroundColor Yellow
}

# NPM Package Installation
$npmPackages = Get-PackagesFromProfile -PackageType "npm" -Profile $Profile -ScriptDir $scriptDir

if ($npmPackages.Count -gt 0) {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "NPM Package Installation" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""

    # Check if npm is available, reload PATH if not
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Step "npm not found, reloading PATH..."
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        # Check again after reloading
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            Write-Warning "npm still not found! Node.js may need to be installed first."
            Write-Host "Please restart your terminal and run this script again." -ForegroundColor Yellow
            Write-Host ""
        }
    }

    # Proceed with npm installation if available
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Success "npm found: $(npm --version)"
        Write-Host "Found $($npmPackages.Count) npm packages to install" -ForegroundColor White
        Write-Host ""

        if (-not $DryRun) {
            $npmInstalled = 0
            $npmFailed = 0

            foreach ($package in $npmPackages) {
                Write-Host "[>] Processing: $package" -ForegroundColor Yellow

                try {
                    npm install -g $package --silent 2>&1 | Out-Null

                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "  Installed: $package"
                        $npmInstalled++
                    } else {
                        Write-Warning "  Failed: $package"
                        $npmFailed++
                    }
                } catch {
                    Write-Warning "  Error: $package"
                    $npmFailed++
                }

                Write-Host ""
            }

            # NPM Summary
            Write-Host "=====================================" -ForegroundColor Cyan
            Write-Host "NPM Installation Summary" -ForegroundColor Cyan
            Write-Host "=====================================" -ForegroundColor Cyan
            Write-Host "[+] Installed: $npmInstalled" -ForegroundColor Green
            Write-Host "[-] Failed:    $npmFailed" -ForegroundColor Red
            Write-Host ""
        }
    }
}

Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host ""
