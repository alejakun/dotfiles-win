#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Full Profile
# ================================================================================
# Installs: HOME + PERSONAL + DEV + INFRA (everything)
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-full.ps1 | iex

$env:DOTFILES_PROFILE="full"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)
