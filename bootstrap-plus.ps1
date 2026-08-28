#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Plus Profile
# ================================================================================
# Installs: MINI + BASE + PLUS
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-plus.ps1 | iex

$env:DOTFILES_PROFILE="plus"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1)
