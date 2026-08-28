#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Dev Profile
# ================================================================================
# Installs: HOME + DEV
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-dev.ps1 | iex

$env:DOTFILES_PROFILE="home,dev"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)
