# dotfiles-win

> Automated Windows application installation using winget

---

## 🚀 Quick Start

### One-Line Installation

Open **PowerShell** and run:

```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

This will automatically:
- Check prerequisites (winget)
- Download installation files
- Install all applications listed in `winget/packages.txt`

---

### Preview Mode (Dry Run)

To see what would be installed without actually installing:

```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex -DryRun
```

---

## 📦 Included Applications

### Development Tools
- **Git** - Version control
- **Visual Studio Code** - Code editor
- **Claude Code** - AI-powered coding assistant CLI

### Browsers
- **Google Chrome** - Web browser
- **Mozilla Firefox** - Web browser

### Productivity
- **7-Zip** - File compression

### Security
- **Bitwarden** - Password manager

### Design & CAD
- **AutoCAD** - CAD software

### Remote Access
- **TeamViewer** - Remote desktop
- **AnyDesk** - Remote desktop

### Viewers
- **Adobe Acrobat Reader** - PDF viewer

### Geographic Tools
- **Google Earth Pro** - 3D globe viewer

### Office Suite
- **Microsoft Office** - ⚠️ Commented out, requires manual installation

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

## 🛠️ Manual Installation

If you prefer to clone the repository and run locally:

### 1. Clone the repository

```powershell
git clone https://github.com/alejakun/dotfiles-win.git
cd dotfiles-win
```

### 2. Run the installer

```powershell
.\install.ps1
```

### 3. Dry run mode

```powershell
.\install.ps1 -DryRun
```

### 4. Show individual commands

Get individual winget commands to copy/paste for selective installation:

```powershell
.\install.ps1 -ShowCommands
```

This displays commands like:
```powershell
winget install --id Git.Git -e --source winget
winget install --id Anthropic.ClaudeCode -e --source winget
```

Useful when you only want to install 1-2 specific packages.

### 5. Show help

```powershell
.\install.ps1 -Help
```

---

## ✏️ Customization

### Adding Applications

1. Find the package ID:
   ```powershell
   winget search "App Name"
   ```

2. Add to `winget/packages.txt`:
   ```txt
   # My additions
   Notepad++.Notepad++
   VideoLAN.VLC
   ```

3. Run installer again

### Removing Applications

Comment out or delete lines in `winget/packages.txt`:

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
```

---

## 📁 Structure

```
dotfiles-win/
├── bootstrap.ps1           # Remote installation script
├── install.ps1             # Main installation script
├── winget/
│   └── packages.txt        # List of packages to install
├── MANUAL_INSTALL.md       # Manual installation guide
└── README.md               # This file
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

MIT License - See [LICENSE](LICENSE) file for details

---

**Last updated:** 2025-10-21
