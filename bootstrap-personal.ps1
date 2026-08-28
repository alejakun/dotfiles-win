#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Personal Profile
# ================================================================================
# Installs: HOME + PERSONAL
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-personal.ps1 | iex

$env:DOTFILES_PROFILE="home,personal"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)
