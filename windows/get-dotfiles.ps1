#!/usr/bin/env pwsh
# ================================================================================
# Get Dotfiles
# ================================================================================
# Third phase of setting up a Windows machine: get the private dotfiles repo onto
# it, and establish the SSH identity needed to do so.
#
#   prepare-machine.ps1   machine-level changes that need administrator rights
#   install-packages.ps1           packages, including git and GitHub CLI in the pro profile
#   this script           this machine's GitHub identity, and the clone
#   ..\dotfiles\hosts\windows\install.ps1   your configuration
#
# Why this lives in the PUBLIC repo: the code that obtains the credential cannot
# live behind the credential. On a fresh machine this is reachable with
# "iwr ... | iex" while the private repo is not.
#
# The key is registered BEFORE the clone, so the first clone is already over SSH.
# gh only ever hands out an API token here: HTTPS is never a git transport, which
# keeps one identity policy instead of two. See ../dotfiles/docs/ssh-identities.md.
#
# Usage:
#   .\get-dotfiles.ps1           Do what is missing
#   .\get-dotfiles.ps1 -DryRun   Report what would change, touch nothing
#
# Idempotent: an existing key is never regenerated, an already-registered key is
# not registered twice, and an existing clone is left alone.
#
# The body lives inside a function for the same reason as prepare-machine.ps1:
# iex runs in the CALLER's scope, so a bare `exit` would close the user's shell
# and take the error message with it.

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Step    { param([string]$Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Err     { param([string]$Message) Write-Host "[-] $Message" -ForegroundColor Red }

# Native commands that exit non-zero are expected here: `ssh -T git@github.com`
# always exits 1 because GitHub grants no shell, and `gh auth status` exits 1
# when logged out. PowerShell 7.4 turns a non-zero exit into a TERMINATING error
# while ErrorActionPreference is Stop, so these run with it relaxed and the exit
# code is inspected by hand.
function Invoke-Native {
    param([string]$Exe, [string[]]$Arguments)

    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $Exe @Arguments 2>&1 | Out-String
        return [pscustomobject]@{ Output = $output; ExitCode = $LASTEXITCODE }
    } finally {
        $ErrorActionPreference = $previous
    }
}

function Invoke-GetDotfiles {
    param([switch]$DryRun)

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Windows - Get Dotfiles" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Warn "DRY RUN - nothing will be created, registered or cloned."
    Write-Host ""
}

# --------------------------------------------------------------------------------
# Elevation
# --------------------------------------------------------------------------------
# The inverse of prepare-machine.ps1's check, and the more dangerous of the two:
# elevation here does not fail, it silently does the wrong thing. In an elevated
# session $env:USERPROFILE is the administrator's, so the key would be written to
# that profile, the repo cloned into that home, and hosts\windows\install.ps1
# would configure the administrator's environment instead of yours - reporting
# success at every step.
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "This must NOT run elevated"
    Write-Host "  Everything here is per-user: your SSH key, your clone, your profile." -ForegroundColor Gray
    Write-Host "  Run elevated, all three land in the administrator's profile" -ForegroundColor Gray
    Write-Host "  ($env:USERPROFILE) and the run still reports success." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Close this window, open a NORMAL session, and run it again." -ForegroundColor Gray
    Write-Host ""
    return 1
}

$sshDir = Join-Path $env:USERPROFILE ".ssh"
$key    = Join-Path $sshDir "id_ed25519"
$target = Join-Path $env:USERPROFILE ".dotfiles"

# --------------------------------------------------------------------------------
# 1. Prerequisites
# --------------------------------------------------------------------------------
# Both come from install-packages.ps1's pro profile (Git.Git, GitHub.cli). ssh.exe ships
# with Windows itself.
Write-Step "Checking prerequisites..."

# PowerShell 7, not 5.1. Two reasons: the configuration installer this hands off
# to requires it, and step 3 relies on 7.3+ argument passing to hand ssh-keygen a
# genuinely empty passphrase. Under 5.1 that argument can arrive as two literal
# quote characters, silently producing a key whose passphrase is those quotes.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Err "This script needs PowerShell 7, and is running on $($PSVersionTable.PSVersion)"
    Write-Host "  Reopen in pwsh and run it again." -ForegroundColor Gray
    Write-Host ""
    return 1
}

$missing = @()
foreach ($tool in @("git", "gh", "ssh", "ssh-keygen")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { $missing += $tool }
}

if ($missing.Count -gt 0) {
    Write-Err "Missing: $($missing -join ', ')"
    Write-Host "  Install the pro profile first:  .\install-packages.ps1 -Profile pro" -ForegroundColor Gray
    Write-Host ""
    return 1
}

Write-Success "PowerShell $($PSVersionTable.PSVersion), git, gh and ssh"

# --------------------------------------------------------------------------------
# 2. GitHub authentication
# --------------------------------------------------------------------------------
# gh's default scopes are repo, read:org and gist. Registering an SSH key needs
# admin:public_key, which is NOT among them - asking for it at login avoids a
# second trip to the browser through `gh auth refresh` later on.
Write-Step "Checking GitHub authentication..."

$auth = Invoke-Native "gh" @("auth", "status")
$authenticated = ($auth.ExitCode -eq 0)
$hasScope      = $authenticated -and ($auth.Output -match "admin:public_key")

if ($hasScope) {
    Write-Success "Authenticated, with permission to register keys"
} elseif ($DryRun) {
    if ($authenticated) {
        Write-Warn "Would run: gh auth refresh -h github.com -s admin:public_key"
    } else {
        Write-Warn "Would run: gh auth login -h github.com -p https -w -s admin:public_key"
    }
} else {
    Write-Host "  A browser window will open to authenticate with GitHub." -ForegroundColor Gray
    if ($authenticated) {
        # Already logged in, only the scope is missing: refresh keeps the session.
        & gh auth refresh -h github.com -s admin:public_key
    } else {
        & gh auth login -h github.com -p https -w -s admin:public_key
    }

    $auth = Invoke-Native "gh" @("auth", "status")
    if ($auth.ExitCode -ne 0) {
        Write-Err "GitHub authentication failed"
        Write-Host ""
        return 1
    }
    Write-Success "Authenticated with GitHub"
}

$user = $null
if (-not $DryRun -or $authenticated) {
    $who = Invoke-Native "gh" @("api", "user", "--jq", ".login")
    if ($who.ExitCode -eq 0) { $user = $who.Output.Trim() }
}

if ($user) {
    Write-Success "GitHub user: $user"
} elseif (-not $DryRun) {
    Write-Err "Could not read the GitHub user"
    Write-Host ""
    return 1
}

# --------------------------------------------------------------------------------
# 3. This machine's key
# --------------------------------------------------------------------------------
# A device identity, per ../dotfiles/docs/ssh-identities.md type 2: one key per
# machine, revocable on its own from github.com/settings/keys.
#
# No passphrase, deliberately. There is nowhere on Windows to cache one:
# prepare-machine.ps1 disables the ssh-agent service so Bitwarden's agent can
# claim the OpenSSH pipe, and that agent only serves vault keys - it will not
# load a key from disk. With a passphrase you would type it on every git fetch.
# The defence for this key is being able to revoke it, not the passphrase.
#
# This mirrors ../dotfiles/bin/gh-setup-ssh and the macOS bootstrap. It is
# a port, not a copy that could be shared: those are bash. Change one, change all.
Write-Step "Checking this machine's SSH key..."

if (Test-Path $key) {
    Write-Success "A key already exists at $key"
    & ssh-keygen -lf "$key.pub"
} elseif ($DryRun) {
    Write-Warn "Would generate $key (ed25519, no passphrase)"
} else {
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }

    $comment = "$env:USERNAME@$env:COMPUTERNAME"
    & ssh-keygen -t ed25519 -C $comment -f $key -N "" -q

    if (-not (Test-Path $key)) {
        Write-Err "ssh-keygen did not produce a key"
        Write-Host ""
        return 1
    }

    # Confirm the passphrase really is empty, not the two literal quote
    # characters. Reading the private key with no -P at all only succeeds on an
    # unencrypted key; an encrypted one asks, and fails with stdin closed.
    $plain = Invoke-Native "ssh-keygen" @("-y", "-f", $key)
    if ($plain.ExitCode -ne 0) {
        Write-Err "The key was created WITH a passphrase, which is not what this expects"
        Write-Host "  Windows has nowhere to cache it: prepare-machine.ps1 disables the" -ForegroundColor Gray
        Write-Host "  ssh-agent service so Bitwarden can claim the pipe, and that agent" -ForegroundColor Gray
        Write-Host "  does not load keys from disk - you would type it on every fetch." -ForegroundColor Gray
        Write-Host "  Delete it and run again:  Remove-Item $key, $key.pub" -ForegroundColor Gray
        Write-Host ""
        return 1
    }

    Write-Success "Key generated: $key (no passphrase)"
}

# --------------------------------------------------------------------------------
# 4. Register it on GitHub
# --------------------------------------------------------------------------------
# No browser: the token from step 2 already carries admin:public_key.
Write-Step "Registering the key on GitHub..."

if ($DryRun -and -not (Test-Path $key)) {
    Write-Warn "Would register the new key as '$env:COMPUTERNAME'"
} else {
    $fingerprint = ((& ssh-keygen -lf "$key.pub") -split '\s+')[1]
    $known = Invoke-Native "gh" @("ssh-key", "list")

    if ($known.ExitCode -eq 0 -and $known.Output -match [regex]::Escape($fingerprint)) {
        Write-Success "The key was already registered"
    } elseif ($DryRun) {
        Write-Warn "Would register the key as '$env:COMPUTERNAME'"
    } else {
        & gh ssh-key add "$key.pub" --title $env:COMPUTERNAME
        Write-Success "Key registered as '$env:COMPUTERNAME'"
    }
}

# --------------------------------------------------------------------------------
# 5. Verify end to end
# --------------------------------------------------------------------------------
# accept-new records GitHub's host key without asking. On a new machine it is not
# in known_hosts, and the clone below would stop waiting for a "yes" nobody types.
if (-not $DryRun) {
    Write-Step "Verifying SSH access to GitHub..."

    $probe = Invoke-Native "ssh" @("-T", "-o", "StrictHostKeyChecking=accept-new", "git@github.com")
    if ($probe.Output -match "successfully authenticated") {
        Write-Success "GitHub answers to this machine's key"
    } else {
        Write-Err "GitHub did not recognise the key"
        Write-Host "  Check with:  ssh -vT git@github.com" -ForegroundColor Gray
        Write-Host ""
        return 1
    }
}

# --------------------------------------------------------------------------------
# 6. Clone
# --------------------------------------------------------------------------------
# Full clone, submodules included. hosts/windows/README.md used to recommend a
# sparse checkout of three paths; that predates WSL, which runs
# hosts/debian/install.sh from THIS copy and whose fish config reads
# private/.env. A sparse checkout would leave both out.
Write-Step "Cloning dotfiles..."

if (Test-Path $target) {
    Write-Success "$target already exists; leaving it alone"
} elseif ($DryRun) {
    Write-Warn "Would clone into $target"
} else {
    & git clone --recurse-submodules "git@github.com:$user/dotfiles.git" $target
    if (-not (Test-Path (Join-Path $target "hosts\windows\install.ps1"))) {
        Write-Err "The clone did not produce hosts\windows\install.ps1"
        Write-Host ""
        return 1
    }
    Write-Success "Cloned into $target"
}

# --------------------------------------------------------------------------------
# 7. Hand off
# --------------------------------------------------------------------------------
# Invoked through pwsh on purpose: that installer requires PowerShell 7 and says
# so in its own preflight.
Write-Host ""

if ($DryRun) {
    Write-Host "Next, this would run:" -ForegroundColor Gray
    Write-Host "  pwsh $target\hosts\windows\install.ps1" -ForegroundColor Gray
    Write-Host ""
    return 0
}

$configure = Join-Path $target "hosts\windows\install.ps1"
if (Test-Path $configure) {
    Write-Step "Handing off to your configuration..."
    Write-Host ""
    & pwsh $configure
} else {
    Write-Warn "Could not find $configure"
}

Write-Host ""
Write-Host "Remember: when you retire this machine, delete its key from" -ForegroundColor Gray
Write-Host "  https://github.com/settings/keys" -ForegroundColor Gray
Write-Host ""
return 0
}

# Delivered with "iwr ... | iex", where there is no way to pass a parameter, so
# the env var is the only channel for a dry run. Same convention as bootstrap.ps1.
if ($env:DOTFILES_DRYRUN -eq "1") { $DryRun = $true }

Invoke-GetDotfiles -DryRun:$DryRun | Out-Null
