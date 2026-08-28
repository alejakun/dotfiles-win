#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Pro Profile
# ================================================================================
# Installs: MINI + BASE + PLUS + PRO
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-pro.ps1 | iex

$env:DOTFILES_PROFILE="pro"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1)
