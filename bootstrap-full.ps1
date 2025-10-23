#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Full Profile
# ================================================================================
# Installs: HOME + PERSONAL + DEV + INFRA (everything)
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-full.ps1 | iex

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Installing: FULL PROFILE" -ForegroundColor Cyan
Write-Host "   (HOME + PERSONAL + DEV + INFRA)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Install HOME profile
Write-Host "[*] Step 1/4: Installing HOME profile..." -ForegroundColor Cyan
$env:DOTFILES_PROFILE="home"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)

Write-Host ""
Write-Host "[*] Step 2/4: Installing PERSONAL profile..." -ForegroundColor Cyan
$env:DOTFILES_PROFILE="personal"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)

Write-Host ""
Write-Host "[*] Step 3/4: Installing DEV profile..." -ForegroundColor Cyan
$env:DOTFILES_PROFILE="dev"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)

Write-Host ""
Write-Host "[*] Step 4/4: Installing INFRA profile..." -ForegroundColor Cyan
$env:DOTFILES_PROFILE="infra"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "   Full Installation Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
