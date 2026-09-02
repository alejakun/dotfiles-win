#!/usr/bin/env pwsh
# ================================================================================
# Windows Machine Preparation
# ================================================================================
# Machine-level changes that require administrator rights, and that nothing else
# in this repo is allowed to do.
#
# Why this is a separate script:
#
#   install.ps1                   installs packages. Elevation is optional there:
#                                 without it, winget falls back to user scope.
#   ../dotfiles/hosts/windows/    configures your environment. It NEVER elevates
#     install.ps1                 by design - junctions, User-scope variables,
#                                 HKCU and $PROFILE are all per-user.
#   this script                   changes the machine itself. Always needs admin,
#                                 and may require a reboot.
#
# Run it ONCE, before everything else. Installing a WSL distribution is NOT done
# here: once the optional components are live it needs no special rights, so it
# belongs with the rest of the software in install.ps1's "wsl" optional group.
#
# Usage:
#   .\prepare-machine.ps1           Apply what is missing
#   .\prepare-machine.ps1 -DryRun   Report what would change, touch nothing
#
# Idempotent: it inspects the current state and skips whatever is already done.
# Written for PowerShell 5.1 as well as 7, because it may run before pwsh exists.

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Step    { param([string]$Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Err     { param([string]$Message) Write-Host "[-] $Message" -ForegroundColor Red }

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Windows - Machine Preparation" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------------------------------------
# Elevation
# --------------------------------------------------------------------------------
# Everything below fails without it, and it fails late and confusingly: the
# service commands report "Acceso denegado" while the feature query throws.
# Refuse up front and say exactly how to fix it.
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "This script requires an elevated session."
    Write-Host "  Win+X -> Terminal (Admin), or:" -ForegroundColor Gray
    Write-Host "    Start-Process powershell -Verb RunAs -ArgumentList '-File','$PSCommandPath'" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

$rebootNeeded = $false
$changed      = 0

# --------------------------------------------------------------------------------
# 1. WSL optional components
# --------------------------------------------------------------------------------
# The winget package (Microsoft.WSL) is NOT enough on its own: wsl.exe then
# reports WSL_E_WSL_OPTIONAL_COMPONENT_REQUIRED, because these are Windows
# optional components and winget cannot enable them. Verified on a real machine
# 2026-08-30, and again 2026-09-02.
#
# VirtualMachinePlatform is the hypervisor side. It is not live until the machine
# reboots, which is why installing a distribution has to wait.
Write-Step "WSL optional components..."

$wslFeatures = @(
    @{ Name = "Microsoft-Windows-Subsystem-Linux"; Label = "Windows Subsystem for Linux" },
    @{ Name = "VirtualMachinePlatform";            Label = "Virtual Machine Platform" }
)

foreach ($feature in $wslFeatures) {
    $state = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction SilentlyContinue

    if (-not $state) {
        Write-Warn "  not available on this edition: $($feature.Label)"
        continue
    }

    if ($state.State -eq "Enabled") {
        Write-Host "  [=] already enabled: $($feature.Label)" -ForegroundColor Gray
        continue
    }

    if ($DryRun) {
        Write-Warn "  would enable: $($feature.Label)"
        $changed++
        continue
    }

    $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature.Name -NoRestart -All
    Write-Success "  enabled: $($feature.Label)"
    $changed++
    if ($result.RestartNeeded) { $rebootNeeded = $true }
}

# --------------------------------------------------------------------------------
# 2. Windows ssh-agent service
# --------------------------------------------------------------------------------
# Bitwarden's SSH agent and this service compete for the same pipe name,
# \\.\pipe\openssh-ssh-agent. Bitwarden claims it ONCE, at startup; if it finds
# the pipe taken it gives up silently and never retries. The toggle stays on
# while the agent serves nothing.
#
# Happened 2026-09-02: a Windows update left the service on Automatic and after a
# reboot it won the race. The symptom - Permission denied (publickey) with no
# Bitwarden prompt - does not point at the service.
#
# Disabled, not just Stopped: on Automatic it wins the race again every boot.
Write-Step "Windows ssh-agent service..."

$agentSvc = Get-Service ssh-agent -ErrorAction SilentlyContinue
if (-not $agentSvc) {
    Write-Host "  [=] not present on this machine" -ForegroundColor Gray
}
elseif ($agentSvc.Status -eq "Stopped" -and $agentSvc.StartType -eq "Disabled") {
    Write-Host "  [=] already stopped and disabled" -ForegroundColor Gray
}
elseif ($DryRun) {
    Write-Warn "  would stop and disable (now: $($agentSvc.Status) / $($agentSvc.StartType))"
    $changed++
}
else {
    if ($agentSvc.Status -ne "Stopped") { Stop-Service ssh-agent -Force }
    Set-Service ssh-agent -StartupType Disabled
    Write-Success "  stopped and disabled, the pipe is free for Bitwarden"
    Write-Host "    If Bitwarden was already running, quit it completely" -ForegroundColor Gray
    Write-Host "    (system tray included) and reopen it." -ForegroundColor Gray
    $changed++
}

# --------------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------------
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "   Dry run - nothing was changed" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $changed item(s) would be applied." -ForegroundColor Gray
    Write-Host ""
    exit 0
}

Write-Host "   Done" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if ($changed -eq 0) {
    Write-Host "  Nothing to do - the machine was already prepared." -ForegroundColor Gray
    Write-Host ""
    exit 0
}

if ($rebootNeeded) {
    Write-Warn "REBOOT REQUIRED before continuing."
    Write-Host "  VirtualMachinePlatform is not live until the machine restarts," -ForegroundColor Gray
    Write-Host "  so installing a WSL distribution would fail right now." -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Next, in a NORMAL (non-elevated) session:" -ForegroundColor Gray
Write-Host "  .\install.ps1 -Profile pro        packages, including the wsl group" -ForegroundColor Gray
Write-Host "  pwsh <dotfiles>\hosts\windows\install.ps1   your configuration" -ForegroundColor Gray
Write-Host ""
