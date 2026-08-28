#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Base Profile
# ================================================================================
# Installs: MINI + BASE
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-base.ps1 | iex

$env:DOTFILES_PROFILE="base"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)
