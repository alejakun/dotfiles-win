#!/usr/bin/env pwsh
# ================================================================================
# dotfiles-win Bootstrap - Max Profile
# ================================================================================
# Installs: everything (MINI + BASE + PLUS + PRO + MAX)
# Usage: iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-max.ps1 | iex

$env:DOTFILES_PROFILE="max"
iex (iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 -UseBasicParsing)
