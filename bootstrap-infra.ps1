#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Infra Profile
# ================================================================================
# Installs: HOME + INFRA
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-infra.ps1 | iex

$env:DOTFILES_PROFILE="home,infra"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)
