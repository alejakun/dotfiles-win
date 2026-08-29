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
    [switch]$Extras,
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

# winget decides whether something is installed by matching it to its catalogue,
# and for a few packages that match never happens. Office is the one that matters:
# a machine with Microsoft 365 reports nothing under Microsoft.Office, so winget
# would install Click-to-Run over the existing suite and reconfigure it. These
# packages get their own presence test instead.
$PresenceOverrides = @{
    "Microsoft.Office" = {
        # App Paths is written by Click-to-Run, MSI and retail installs alike;
        # the WOW6432Node copy covers 32-bit Office on 64-bit Windows
        (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\winword.exe") -or
        (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\winword.exe") -or
        (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe") -or
        (Test-Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration")
    }
}

# Single source of truth for "is this already here", used by both the preview and
# the installer so they can never disagree
function Test-PackageInstalled {
    param([string]$PackageId)

    if ($PresenceOverrides.ContainsKey($PackageId)) {
        return [bool](& $PresenceOverrides[$PackageId])
    }

    # --accept-source-agreements matters: without it winget can stop to ask, and
    # with the output redirected the prompt is invisible - it just looks hung
    winget list --id $PackageId --exact --accept-source-agreements 2>&1 | Out-Null
    return $LASTEXITCODE -eq 0
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
    Write-Host "  .\install.ps1 -Extras              Include the optional extras without asking"
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

# Extras are not a rung. They belong on machines you expect to support, which is
# a question about the machine, not about how much software it gets - so it is
# asked rather than derived from the profile. The default follows the profile
# only to make pressing Enter do the right thing for the machine at hand.
$extrasPackages = @(Get-PackagesFromProfile -PackageType "winget" -ProfileNames @("extras") -ScriptDir $scriptDir)

if ($extrasPackages.Count -gt 0) {
    $extrasByDefault = $InstallProfile -in @("mini", "base")

    if ($Extras) {
        $includeExtras = $true
    } elseif (-not [Environment]::UserInteractive) {
        $includeExtras = $extrasByDefault
    } else {
        Write-Host ""
        Write-Host "Optional: remote support tools and Earth Pro" -ForegroundColor Yellow
        $extrasPackages | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Worth having on a machine you will support or hand to someone else." -ForegroundColor Gray
        Write-Host "On your own machine they are mostly services running at boot." -ForegroundColor Gray

        $prompt = if ($extrasByDefault) { "Include these? [Y/n]" } else { "Include these? [y/N]" }
        $answer = Read-Host $prompt

        if ([string]::IsNullOrWhiteSpace($answer)) {
            $includeExtras = $extrasByDefault
        } else {
            $includeExtras = $answer -match '^\s*(y|yes|s|si|sí)\s*$'
        }
        Write-Host ""
    }

    if ($includeExtras) {
        $packages += $extrasPackages | Where-Object { $_ -notin $packages }
        Write-Host "Including $($extrasPackages.Count) extra packages" -ForegroundColor Gray
    }
}
$npmPackages = @(Get-PackagesFromProfile -PackageType "npm" -ProfileNames $profilesToInstall -ScriptDir $scriptDir)

if ($packages.Count -eq 0 -and $npmPackages.Count -eq 0) {
    Write-Err "No packages found for profiles: $($profilesToInstall -join ', ')"
    Write-Host "Available profiles: mini, base, plus, pro, max" -ForegroundColor Yellow
    exit 1
}

# Neutral wording: -DryRun reaches this line too, and installs none of them
Write-Host "Found $($packages.Count) winget packages" -ForegroundColor White
if ($npmPackages.Count -gt 0) {
    Write-Host "Found $($npmPackages.Count) npm packages" -ForegroundColor White
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
    Write-Step "Checking which packages are already present..."
    Write-Host "Queries winget once per package, so this takes a moment." -ForegroundColor Gray
    Write-Host ""

    $present = 0
    $missing = 0

    $index = 0

    foreach ($package in $packages) {
        $index++

        if (Test-PackageInstalled -PackageId $package) {
            Write-Host ("  [{0,2}/{1}] [=] {2}" -f $index, $packages.Count, $package) -ForegroundColor Gray
            $present++
        } else {
            Write-Host ("  [{0,2}/{1}] [+] {2}" -f $index, $packages.Count, $package) -ForegroundColor Green
            $missing++
        }
    }

    Write-Host ""
    Write-Host "  [=] already installed   [+] would be installed" -ForegroundColor DarkGray
    Write-Host ""

    if ($npmPackages.Count -gt 0) {
        Write-Host "npm packages that would be installed:" -ForegroundColor Yellow
        $npmPackages | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Gray
        }
        Write-Host ""
    }

    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Dry Run Summary" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "[=] Already installed: $present" -ForegroundColor Gray
    Write-Host "[+] Would install:     $missing" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detection asks winget whether it can match an installed program to" -ForegroundColor DarkGray
    Write-Host "its catalogue, except for the few packages that carry their own check." -ForegroundColor DarkGray
    Write-Host "Something installed from a different source - the Microsoft Store" -ForegroundColor DarkGray
    Write-Host "rather than winget, say - is a different package as far as winget is" -ForegroundColor DarkGray
    Write-Host "concerned: it shows as [+] and would be installed alongside, not over," -ForegroundColor DarkGray
    Write-Host "what you already have. Check with: winget list <name>" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Run without -DryRun to install them" -ForegroundColor Yellow
    exit 0
}

# Installation
Write-Step "Starting installation..."
Write-Host ""

$installed = 0
$failed = 0
$skipped = 0
$failedPackages = @()
$userScopedPackages = @()
$needsElevationPackages = @()

# Several packages ship both a machine-wide and a per-user installer, and winget
# picks. If it picks per-user, the package lands only in the profile running this
# script - on a machine being handed to someone else, they simply never get it,
# with nothing in the summary to say so. Ask for machine scope explicitly.
# Unelevated there is no point: machine scope would fail every time.
$preferMachineScope = Test-Administrator

foreach ($package in $packages) {
    Write-Host "[>] Processing: $package" -ForegroundColor Yellow

    if (Test-PackageInstalled -PackageId $package) {
        Write-Host "  [=] Already installed: $package" -ForegroundColor Gray
        $skipped++
    } else {
        # Not installed, proceed with installation
        Write-Host "  [*] Installing..." -ForegroundColor Cyan

        $baseArgs = @(
            "install", "--id", $package, "--exact", "--silent",
            "--accept-package-agreements", "--accept-source-agreements"
        )

        try {
            $fellBackToUser = $false

            if ($preferMachineScope) {
                $installResult = & winget @baseArgs --scope machine 2>&1

                if ($LASTEXITCODE -ne 0) {
                    # Either the package has no machine-wide installer, or something
                    # else went wrong. Retry unconstrained and let the outcome say which.
                    $installResult = & winget @baseArgs 2>&1
                    $fellBackToUser = $LASTEXITCODE -eq 0
                }
            } else {
                $installResult = & winget @baseArgs 2>&1
            }

            if ($LASTEXITCODE -eq 0) {
                if ($fellBackToUser) {
                    Write-Success "  Installed (current user only): $package"
                    $userScopedPackages += $package
                } else {
                    Write-Success "  Installed: $package"
                }
                $installed++
            } else {
                if (-not $preferMachineScope) {
                    # Unelevated, winget was already free to use a per-user
                    # installer. That it could not means there is none, which is a
                    # category rather than a fault - report it quietly and in one
                    # place at the end.
                    Write-Host "  [~] Needs elevation: $package" -ForegroundColor DarkGray
                    $needsElevationPackages += $package
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
Write-Host "[+] Installed:         $installed" -ForegroundColor Green
Write-Host "[=] Already installed: $skipped" -ForegroundColor Gray
if ($needsElevationPackages.Count -gt 0) {
    Write-Host "[~] Needs elevation:   $($needsElevationPackages.Count)" -ForegroundColor DarkGray
}
Write-Host "[-] Failed:            $failed" -ForegroundColor Red
Write-Host ""

if ($needsElevationPackages.Count -gt 0) {
    Write-Host "Not installed - no per-user installer available:" -ForegroundColor DarkGray
    $needsElevationPackages | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Expected when running without elevation; run again from an elevated" -ForegroundColor DarkGray
    Write-Host "session to install these. A network or package problem would also" -ForegroundColor DarkGray
    Write-Host "land here, so check the list if something you needed is on it." -ForegroundColor DarkGray
    Write-Host ""
}

if ($userScopedPackages.Count -gt 0) {
    Write-Warn "Installed for the current user only:"
    $userScopedPackages | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "These ship no machine-wide installer, so they live in this account's" -ForegroundColor Gray
    Write-Host "profile and other users on this machine will not see them. To give" -ForegroundColor Gray
    Write-Host "someone else access, run the install again from their session - no" -ForegroundColor Gray
    Write-Host "elevation needed, since a per-user install does not require it." -ForegroundColor Gray
    Write-Host ""
}

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
