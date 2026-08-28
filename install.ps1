#!/usr/bin/env pwsh
# ================================================================================
# Windows Essential Applications Installer
# ================================================================================
# Installs common applications using winget
#
# Usage:
#   .\install.ps1                # Install the mini profile (default)
#   .\install.ps1 -Profile plus  # Each profile includes the ones below it
#   .\install.ps1 -DryRun        # Show what would be installed
#   .\install.ps1 -ShowCommands  # Display individual winget commands
#   .\install.ps1 -Help          # Show help message
#
# Requires an elevated PowerShell session (Win+X -> Terminal (Admin)).

param(
    [switch]$DryRun,
    [switch]$ShowCommands,
    [switch]$Help,
    [switch]$SkipAdminCheck,
    [ValidateSet("mini", "base", "plus", "pro", "max")]
    [Alias("Profile")]
    [string]$InstallProfile = "mini"
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

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

# Most of these packages install machine-wide, so elevation is not optional
function Test-Administrator {
    # $IsWindows only exists on PowerShell 6+; on 5.1 we are always on Windows
    if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
        return $true
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Profiles form a ladder: each one extends the one before it, so installing
# "plus" installs mini + base + plus. The chain is the install order too.
$ProfileLadder = @("mini", "base", "plus", "pro", "max")

# Helper function to read packages from profile files
function Get-PackagesFromProfile {
    param(
        [string]$PackageType,  # "winget" or "npm"
        [string[]]$ProfileNames,
        [string]$ScriptDir
    )

    $allPackages = @()

    foreach ($prof in $ProfileNames) {
        $packageFile = Join-Path $ScriptDir "$PackageType\packages-$prof.txt"

        if (Test-Path $packageFile) {
            $allPackages += Get-Content $packageFile | Where-Object {
                $_ -and $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$'
            }
        }
    }

    return $allPackages | Select-Object -Unique
}

# Show help if requested
if ($Help) {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Windows Applications Installer - Help" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\install.ps1                      Install mini profile (default)"
    Write-Host "  .\install.ps1 -Profile mini        Family computers"
    Write-Host "  .\install.ps1 -Profile base        + passwords, calls, media"
    Write-Host "  .\install.ps1 -Profile plus        + browsers, editors, terminals"
    Write-Host "  .\install.ps1 -Profile pro         + runtimes, cloud CLIs, databases"
    Write-Host "  .\install.ps1 -Profile max         + containers and virtualization"
    Write-Host "  .\install.ps1 -DryRun              Preview packages without installing"
    Write-Host "  .\install.ps1 -ShowCommands        Display individual winget commands"
    Write-Host "  .\install.ps1 -Help                Show this help message"
    Write-Host "  .\install.ps1 -SkipAdminCheck      Run without elevation (most installs fail)"
    Write-Host ""
    Write-Host "PROFILES:" -ForegroundColor Yellow
    Write-Host "  Each profile extends the one before it, so picking a level installs"
    Write-Host "  every level below it as well:"
    Write-Host ""
    Write-Host "    mini -> base -> plus -> pro -> max"
    Write-Host ""
    Write-Host "  mini - Family computers (DEFAULT). Browsers, Office, Reader,"
    Write-Host "         Earth Pro, 7-Zip, TeamViewer, AnyDesk"
    Write-Host "  base - + Bitwarden, Rambox, Zoom, Doxie, QuickLook, ShareX, VLC"
    Write-Host "  plus - + Dropbox, Brave, Zen, Git, VSCode, terminals, Tailscale,"
    Write-Host "         Claude Code, Sublime Text, Spark"
    Write-Host "  pro  - + Node.js, Python, gcloud, AWS CLI, DBeaver"
    Write-Host "  max  - + Docker Desktop, Vagrant"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Family computer (default)"
    Write-Host "  .\install.ps1"
    Write-Host ""
    Write-Host "  # Your own machine"
    Write-Host "  .\install.ps1 -Profile plus"
    Write-Host ""
    Write-Host "  # Everything"
    Write-Host "  .\install.ps1 -Profile max"
    Write-Host ""
    Write-Host "  # Preview what would be installed"
    Write-Host "  .\install.ps1 -Profile plus -DryRun"
    Write-Host ""
    Write-Host "  # See individual commands to copy/paste"
    Write-Host "  .\install.ps1 -ShowCommands -Profile max"
    Write-Host ""
    exit 0
}

# Header
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Windows Applications Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check for elevation before anything else. -DryRun and -ShowCommands install
# nothing, so they only warn; a real run stops here.
if (-not $SkipAdminCheck) {
    Write-Step "Checking administrator privileges..."

    if (Test-Administrator) {
        Write-Success "Running as administrator"
    } elseif ($DryRun -or $ShowCommands) {
        Write-Warn "Not running as administrator"
        Write-Host "  This preview works, but the real install will not: packages like" -ForegroundColor Gray
        Write-Host "  Office, Docker and TeamViewer install machine-wide." -ForegroundColor Gray
        Write-Host "  Re-open with Win+X -> Terminal (Admin) before installing for real." -ForegroundColor Gray
    } else {
        Write-Err "Administrator privileges required"
        Write-Host ""
        Write-Host "Most packages here - Office, Docker, TeamViewer and others - install" -ForegroundColor Yellow
        Write-Host "machine-wide and will fail one by one without elevation." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Open an elevated shell and run it again:" -ForegroundColor Yellow
        Write-Host "  1. Press Win+X" -ForegroundColor Gray
        Write-Host "  2. Choose 'Terminal (Admin)' or 'Windows PowerShell (Admin)'" -ForegroundColor Gray
        Write-Host "  3. Run:" -ForegroundColor Gray
        Write-Host ""
        Write-Host "     .\install.ps1 -Profile $InstallProfile" -ForegroundColor Green
        Write-Host ""
        Write-Host "To install anyway - only user-scope packages will succeed - use:" -ForegroundColor Gray
        Write-Host "     .\install.ps1 -Profile $InstallProfile -SkipAdminCheck" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }

    Write-Host ""
}

# Check if winget is available
Write-Step "Checking winget availability..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "winget not found!"
    Write-Host "Please install App Installer from Microsoft Store:" -ForegroundColor Yellow
    Write-Host "  https://www.microsoft.com/p/app-installer/9nblggh4nns1" -ForegroundColor Yellow
    exit 1
}
Write-Success "winget found: $(winget --version)"
Write-Host ""

# Read package list based on profile
# Use script directory if available, otherwise use current directory
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

$profilesToInstall = $ProfileLadder[0..$ProfileLadder.IndexOf($InstallProfile)]

Write-Step "Reading package lists..."
Write-Host "Script directory: $scriptDir" -ForegroundColor Gray
Write-Host "Profile: $InstallProfile -> $($profilesToInstall -join ' + ')" -ForegroundColor Gray

$packages = @(Get-PackagesFromProfile -PackageType "winget" -ProfileNames $profilesToInstall -ScriptDir $scriptDir)
$npmPackages = @(Get-PackagesFromProfile -PackageType "npm" -ProfileNames $profilesToInstall -ScriptDir $scriptDir)

if ($packages.Count -eq 0 -and $npmPackages.Count -eq 0) {
    Write-Err "No packages found for profiles: $($profilesToInstall -join ', ')"
    Write-Host "Available profiles: mini, base, plus, pro, max" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($packages.Count) winget packages to install" -ForegroundColor White
if ($npmPackages.Count -gt 0) {
    Write-Host "Found $($npmPackages.Count) npm packages to install" -ForegroundColor White
}
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
    $npmPackages | ForEach-Object {
        Write-Host "npm install -g $_" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "TIP: Use these commands to install only specific packages" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# Dry run mode
if ($DryRun) {
    Write-Warn "DRY RUN MODE - No packages will be installed"
    Write-Host ""
    Write-Host "winget packages that would be installed:" -ForegroundColor Yellow
    $packages | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Gray
    }
    if ($npmPackages.Count -gt 0) {
        Write-Host ""
        Write-Host "npm packages that would be installed:" -ForegroundColor Yellow
        $npmPackages | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Gray
        }
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
                Write-Warn "  Failed: $package"
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
            Write-Warn "  Error installing: $package"
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
    Write-Warn "Failed packages:"
    $failedPackages | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "See MANUAL_INSTALL.md for manual installation instructions" -ForegroundColor Yellow
}

# NPM Package Installation
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
            Write-Warn "npm still not found! Node.js may need to be installed first."
            Write-Host "Please restart your terminal and run this script again." -ForegroundColor Yellow
            Write-Host ""
        }
    }

    # Proceed with npm installation if available
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Success "npm found: $(npm --version)"
        Write-Host "Found $($npmPackages.Count) npm packages to install" -ForegroundColor White
        Write-Host ""

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
                    Write-Warn "  Failed: $package"
                    $npmFailed++
                }
            } catch {
                Write-Warn "  Error: $package"
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

Write-Host "Installation complete!" -ForegroundColor Cyan
Write-Host ""
