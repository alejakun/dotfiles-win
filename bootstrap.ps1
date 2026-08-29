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
# Preview without installing anything (no git and no elevation needed):
#   $env:DOTFILES_DRYRUN="1"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
#
# Without elevation it asks whether to continue and install only what does not
# need it - that is the second pass to run from another account.
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

# The whole body lives in a function on purpose. This script is delivered with
# "iwr | iex", which runs it in the CALLER's scope, so a bare "exit" would end
# the user's PowerShell session and close the window - destroying the very error
# message that explains what went wrong. Inside a function, "return" is contained.
function Invoke-DotfilesBootstrap {
    # Read the profile from the environment variable or use the smallest one
    $InstallProfile = if ($env:DOTFILES_PROFILE) { $env:DOTFILES_PROFILE.Trim() } else { "mini" }
    $ValidProfiles = @("mini", "base", "plus", "pro", "max")

    # Preview only. Consumed immediately: left set, the next real run in this same
    # terminal would silently install nothing.
    $DryRun = [bool]$env:DOTFILES_DRYRUN
    Remove-Item Env:\DOTFILES_DRYRUN -ErrorAction SilentlyContinue

    # Set only if the user answers the elevation prompt below
    $SkipAdminCheck = $false

    if ($InstallProfile -notin $ValidProfiles) {
        Write-Host "[-] Invalid profile: $InstallProfile" -ForegroundColor Red
        Write-Host "Valid profiles: mini, base, plus, pro, max" -ForegroundColor Yellow
        return
    }

    # Configuration
    $RepoOwner = "alejakun"
    $RepoName = "dotfiles-win"
    $Branch = if ($env:DOTFILES_BRANCH) { $env:DOTFILES_BRANCH } else { "master" }
    $BaseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
    $InstallDir = Join-Path $env:TEMP "dotfiles-win-install"

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
        return
    }
    Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"

    # Check for elevation. A dry run installs nothing and the second pass only
    # wants the per-user packages, so both of those warn instead of stopping.
    if (Test-Administrator) {
        Write-Success "Running as administrator"
    } elseif ($DryRun) {
        Write-Warn "Not running as administrator"
        Write-Host "  This preview works, but the real install will not." -ForegroundColor Gray
    } else {
        $script = if ($InstallProfile -eq "mini") { "bootstrap.ps1" } else { "bootstrap-$InstallProfile.ps1" }

        Write-Warn "Not running as administrator"
        Write-Host ""
        Write-Host "Most packages here - Office, TeamViewer, VLC and others - install" -ForegroundColor Yellow
        Write-Host "machine-wide and cannot be installed from this session." -ForegroundColor Yellow
        Write-Host ""

        # A Read-Host with nobody there waits forever. We already lost ten minutes
        # to an invisible winget prompt; do not build a second one.
        if (-not [Environment]::UserInteractive) {
            Write-Err "No interactive session to ask in - stopping"
            Write-Host "Run elevated: iwr -useb $BaseUrl/$script | iex" -ForegroundColor Gray
            Write-Host ""
            return
        }

        Write-Host "You can continue anyway. Anything already installed machine-wide" -ForegroundColor Gray
        Write-Host "is detected and skipped, and packages that install per-user will" -ForegroundColor Gray
        Write-Host "work - this is how you finish setting up your own account after" -ForegroundColor Gray
        Write-Host "an administrator has prepared the machine." -ForegroundColor Gray
        Write-Host ""

        $answer = Read-Host "Continue without elevation? [y/N]"

        if ($answer -notmatch '^\s*(y|yes|s|si|sí)\s*$') {
            Write-Host ""
            Write-Host "Stopped. To run elevated:" -ForegroundColor Yellow
            Write-Host "  1. Press Win+X" -ForegroundColor Gray
            Write-Host "  2. Choose 'Terminal (Admin)' or 'Windows PowerShell (Admin)'" -ForegroundColor Gray
            Write-Host "  3. Paste:" -ForegroundColor Gray
            Write-Host ""
            Write-Host "     iwr -useb $BaseUrl/$script | iex" -ForegroundColor Green
            Write-Host ""
            return
        }

        $SkipAdminCheck = $true
        Write-Host ""
    }

    # Check winget availability
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Err "winget not found!"
        Write-Host ""
        Write-Host "winget is required for this installation." -ForegroundColor Yellow
        Write-Host "Install App Installer from Microsoft Store:" -ForegroundColor Yellow
        Write-Host "  https://www.microsoft.com/p/app-installer/9nblggh4nns1" -ForegroundColor Yellow
        Write-Host ""
        return
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

    # No file is flagged as mandatory here. Whether a list exists is a property of
    # the repository, not something this script should carry a second copy of, so
    # it asks for every one and lets the answer decide.
    $files = @(
        @{
            Url = "$BaseUrl/install.ps1"
            Path = Join-Path $InstallDir "install.ps1"
            Name = "install.ps1"
        }
    )

    foreach ($prof in $allProfiles) {
        $files += @{
            Url = "$BaseUrl/winget/packages-$prof.txt"
            Path = Join-Path $InstallDir "winget\packages-$prof.txt"
            Name = "winget/packages-$prof.txt"
        }
        $files += @{
            Url = "$BaseUrl/npm/packages-$prof.txt"
            Path = Join-Path $InstallDir "npm\packages-$prof.txt"
            Name = "npm/packages-$prof.txt"
        }
    }

    $downloadSuccess = $true
    $found = 0

    foreach ($file in $files) {
        try {
            Invoke-WebRequest -Uri $file.Url -OutFile $file.Path -UseBasicParsing
            Write-Success "  $($file.Name)"
            $found++
        } catch {
            $status = $null
            if ($_.Exception.Response) {
                $status = [int]$_.Exception.Response.StatusCode
            }

            # A partial download leaves a file behind; do not let it look real
            if (Test-Path $file.Path) {
                Remove-Item -Path $file.Path -Force
            }

            # 404 means the repository simply has no such file - nothing to say.
            # Anything else means we could not fetch it, which is worth stopping for.
            if ($status -ne 404) {
                Write-Err "  Failed to download: $($file.Name)"
                Write-Host "    $($_.Exception.Message)" -ForegroundColor Gray
                $downloadSuccess = $false
            }
        }
    }

    Write-Host ""
    Write-Host "  $found files downloaded" -ForegroundColor Gray

    Write-Host ""

    if (-not $downloadSuccess) {
        Write-Err "Some files failed to download"
        Write-Host "Please check your internet connection and try again" -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path (Join-Path $InstallDir "install.ps1"))) {
        Write-Err "install.ps1 was not found in the repository"
        Write-Host "Branch: $Branch" -ForegroundColor Gray
        return
    }

    # Execute installation
    Write-Step "Starting installation..."
    Write-Host ""

    try {
        # This script is run from memory by iex, which the execution policy does
        # not apply to. install.ps1 is a file on disk, so it does - and Restricted
        # is the default on Windows client. Run it in a child process with the
        # policy bypassed rather than changing the policy of the user's session.
        $installScript = Join-Path $InstallDir "install.ps1"
        $psExe = if ($PSVersionTable.PSEdition -eq "Core") { "pwsh" } else { "powershell" }

        $psArgs = @(
            "-NoProfile"
            "-ExecutionPolicy", "Bypass"
            "-File", $installScript
            "-InstallProfile", $InstallProfile
        )
        if ($DryRun) {
            $psArgs += "-DryRun"
        }
        if ($SkipAdminCheck) {
            $psArgs += "-SkipAdminCheck"
        }

        # -File sets $PSScriptRoot for install.ps1, so it finds the package lists
        # without needing us to move the user's working directory
        & $psExe @psArgs
        $exitCode = $LASTEXITCODE

        Write-Host ""

        if ($exitCode -eq 0) {
            if ($DryRun) {
                Write-Success "Preview complete - nothing was installed"
            } else {
                Write-Success "Installation completed successfully!"
            }
        } else {
            Write-Warn "Installation completed with errors (exit code: $exitCode)"
        }

    } catch {
        Write-Err "Installation failed"
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
        return
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

}

Invoke-DotfilesBootstrap
