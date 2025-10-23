#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Development Profile
# ================================================================================
# Installs: HOME + DEV profiles
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-dev.ps1 | iex

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Installing: HOME + DEV" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Install HOME profile first
Write-Host "[*] Step 1/2: Installing HOME profile..." -ForegroundColor Cyan
$env:DOTFILES_PROFILE="home"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)

Write-Host ""
Write-Host "[*] Step 2/2: Installing DEV profile..." -ForegroundColor Cyan
$env:DOTFILES_PROFILE="dev"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "   Installation Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
