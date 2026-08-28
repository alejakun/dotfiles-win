# dotfiles-win

> Automated Windows application installation using winget with multiple profiles

---

## 🚀 Quick Start

### One-Line Installation

Open **PowerShell** and run one of these commands:

**HOME only** (family computers - essential apps):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

**HOME + PERSONAL** (your personal laptop):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-personal.ps1 | iex
```

**HOME + DEV** (development workstation):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-dev.ps1 | iex
```

**HOME + INFRA** (infrastructure workstation):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-infra.ps1 | iex
```

**FULL** (everything - home + personal + dev + infra):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-full.ps1 | iex
```

> **Note:** Every one-liner except the HOME one requests `home,<profile>`, so the
> HOME base is always included. Running `install.ps1` by hand installs exactly the
> profiles you name — `-Profile dev` is dev only.

---

## 📋 Profiles

### 🏠 HOME (Default)
**Purpose:** Essential applications for family computers

**Includes:**
- Git, GitHub CLI, VSCode
- Browsers (Chrome, Firefox)
- 7-Zip, Dropbox
- Bitwarden (password manager)
- Rambox, Zoom
- Doxie Scanner
- LocalSend (transferencia de archivos en red local)
- QuickLook (vista previa con barra espaciadora)
- TeamViewer, AnyDesk
- Adobe Acrobat Reader
- Google Earth Pro

### 💼 PERSONAL
**Purpose:** Personal productivity tools

**Includes:**
- Windows Terminal
- PowerToys
- Microsoft Teams
- Krisp.ai (noise cancellation)
- ShareX (screenshots)
- VLC Media Player
- Google Drive Desktop
- Tailscale (VPN mesh network)

### 👨‍💻 DEV
**Purpose:** Development tools for frequent use

**Includes:**
- Claude Code (AI assistant)
- Python 3.12
- Node.js
- Sublime Text 4
- Notepad++
- Google Cloud SDK (gcloud, bq, gsutil)
- AWS CLI

### 🏗️ INFRA
**Purpose:** Infrastructure & virtualization (resource-intensive)

**Includes:**
- DBeaver (database tool)
- Docker Desktop
- VMware Workstation Pro
- Vagrant

**Note:** Ansible not available via winget. Install via WSL or pip.

### 🌐 FULL
**Purpose:** Everything combined (home + personal + dev + infra)

---

## 📦 Installation Methods

### Method 1: One-Liner (Recommended)

See [Quick Start](#-quick-start) above.

### Method 2: Manual Clone

```powershell
git clone https://github.com/alejakun/dotfiles-win.git
cd dotfiles-win
.\install.ps1 -Profile home
```

### Method 3: Composing Profiles

Profiles compose. Pass a comma-separated list and the packages are merged,
de-duplicated and installed in a single pass:

```powershell
.\install.ps1 -Profile home,personal,dev   # your personal workstation
.\install.ps1 -Profile home,dev            # what bootstrap-dev.ps1 runs
```

A single profile means exactly that profile, which is useful when you want the
dev tooling on a machine without the home apps:

```powershell
.\install.ps1 -Profile dev                 # dev only, no home
```

`full` is shorthand for `home,personal,dev,infra`.

---

## 🛠️ Advanced Usage

### Preview Mode (Dry Run)

```powershell
.\install.ps1 -Profile personal -DryRun
```

### Show Individual Commands

```powershell
.\install.ps1 -Profile dev -ShowCommands
```

This displays individual `winget install` commands you can copy/paste.

### Help

```powershell
.\install.ps1 -Help
```

---

## 📋 Prerequisites

- **Windows 10** (version 1809+) or **Windows 11**
- **winget** (Windows Package Manager) - Pre-installed on Windows 11
- **PowerShell 5.0+** - Pre-installed on modern Windows

### Check if winget is installed

```powershell
winget --version
```

If not installed, get it from [Microsoft Store](https://www.microsoft.com/p/app-installer/9nblggh4nns1).

---

## ✏️ Customization

### Adding Applications

1. Find the package ID:
   ```powershell
   winget search "App Name"
   ```

2. Add to appropriate profile file (`winget/packages-home.txt`, `packages-personal.txt`, etc.):
   ```txt
   # My additions
   Notepad++.Notepad++
   VideoLAN.VLC
   ```

3. Run installer again

### Removing Applications

Comment out or delete lines in package files:

```txt
# Mozilla.Firefox  # Don't install Firefox
```

---

## 🔧 Troubleshooting

### "winget not found"

**Solution:**
1. Install App Installer from [Microsoft Store](https://www.microsoft.com/p/app-installer/9nblggh4nns1)
2. Restart PowerShell
3. Verify: `winget --version`

---

### "Access denied"

**Solution:**
- Run PowerShell as Administrator
- Right-click Start → Windows Terminal (Admin)

---

### "Execution policy" error

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### Package installation fails

1. **Check if package exists:**
   ```powershell
   winget search "Package Name"
   ```

2. **Update winget sources:**
   ```powershell
   winget source update
   ```

3. **Try manual installation:**
   See [MANUAL_INSTALL.md](MANUAL_INSTALL.md)

---

## 📝 Notes

### After Installation

Some applications add commands to PATH. To use them in terminals:

- **New PowerShell/Terminal**: Works immediately after installation
- **VSCode**: Requires **full application restart** (not just terminal reload)
- **Existing terminals**: Must be restarted to recognize new PATH

**Example:**

After installing Claude Code via winget:
1. Close VSCode completely (not just the terminal)
2. Reopen VSCode
3. Now `claude` command will work in integrated terminal

**Quick test:**
```powershell
# Restart terminal/VSCode, then:
claude --version
gcloud --version
aws --version
```

---

## 📁 Structure

```
dotfiles-win/
├── bootstrap.ps1                 # Remote installation script
├── bootstrap-personal.ps1        # One-liner: home + personal
├── bootstrap-dev.ps1             # One-liner: home + dev
├── bootstrap-infra.ps1           # One-liner: home + infra
├── bootstrap-full.ps1            # One-liner: everything
├── install.ps1                   # Main installation script
├── winget/
│   ├── packages-home.txt         # Home profile (default)
│   ├── packages-personal.txt     # Personal productivity
│   ├── packages-dev.txt          # Development tools
│   └── packages-infra.txt        # Infrastructure/virtualization
├── npm/
│   └── packages-dev.txt          # Global npm packages (dev profile)
├── MANUAL_INSTALL.md             # Manual installation guide
└── README.md                     # This file
```

---

## 🔄 Maintenance

### Update all installed packages

```powershell
winget upgrade --all
```

### List installed packages

```powershell
winget list --source winget
```

### Uninstall packages

```powershell
winget uninstall --id PackageId
```

---

## 📚 References

- [winget documentation](https://docs.microsoft.com/en-us/windows/package-manager/winget/)
- [winget package repository](https://github.com/microsoft/winget-pkgs)
- [PowerShell documentation](https://docs.microsoft.com/en-us/powershell/)

---

## 📝 License

Personal project - no license specified.

---

**Last updated:** 2026-08-28
