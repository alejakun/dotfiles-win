# dotfiles-win

> Automated Windows application installation using winget with multiple profiles

---

## 🚀 Quick Start

### One-Line Installation

Profiles form a ladder — **each one installs every level below it**:

```
mini  ->  base  ->  plus  ->  pro  ->  max
```

Open **PowerShell as Administrator** (Win+X → *Terminal (Admin)*) and run the line
for the level you want. The scripts check for elevation and stop with instructions
if it is missing, rather than letting every install fail one by one:

**mini** (family computers — the essentials):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

**base** (adds passwords, calls and media):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-base.ps1 | iex
```

**plus** (your own machine — browsers, editors, terminals):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-plus.ps1 | iex
```

**pro** (adds runtimes, cloud CLIs and databases):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-pro.ps1 | iex
```

**max** (adds containers and virtualization):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-max.ps1 | iex
```

---

## 📋 Profiles

| Profile | Adds | Total | For |
|---|---|---|---|
| `mini` | 8 | 8 | Family computers |
| `base` | +7 | 15 | Everyday use |
| `plus` | +14 | 29 | Your own machine |
| `pro` | +5 | 34 | Working with infrastructure |
| `max` | +2 | 36 | Running infrastructure locally |

### 🏠 mini — 8
Browsers (Chrome, Firefox) · Adobe Acrobat Reader · Google Earth Pro · 7-Zip ·
TeamViewer · AnyDesk · Microsoft Office

Office installs unattended and asks you to sign in the first time you open an app.

### 📦 base — +7
Bitwarden · Rambox · Zoom · Doxie Scanner · QuickLook · ShareX · VLC

### 💼 plus — +14
Dropbox · Brave · Zen Browser · Git · GitHub CLI · VSCode · Windows Terminal ·
WezTerm · Rio · PowerToys · Tailscale · Claude Code · Sublime Text 4 · Spark

### 👨‍💻 pro — +5
Node.js · Python 3.12 · Google Cloud SDK · AWS CLI · DBeaver Community

Read `pro` as *you work with infrastructure* and `max` as *you also run it
locally* — which is why one extends the other.

### 🏗️ max — +2
Docker Desktop · Vagrant

**Note:** Ansible is not available via winget and does not support Windows as a
control node. See [MANUAL_INSTALL.md](MANUAL_INSTALL.md) for the WSL route.

---

## 📦 Installation Methods

### Method 1: One-Liner (Recommended)

See [Quick Start](#-quick-start) above.

### Method 2: Manual Clone

```powershell
git clone https://github.com/alejakun/dotfiles-win.git
cd dotfiles-win
.\install.ps1 -Profile plus
```

### Method 3: Picking a Level

Each profile includes the ones below it, so a single command is always enough:

```powershell
.\install.ps1 -Profile plus    # mini + base + plus
.\install.ps1 -Profile max     # everything
```

Packages already installed are detected and skipped, so moving up a level later
only installs what is missing:

```powershell
.\install.ps1 -Profile plus    # today
.\install.ps1 -Profile pro     # later, adds only the pro layer
```

---

## 🛠️ Advanced Usage

### Preview Mode (Dry Run)

```powershell
.\install.ps1 -Profile plus -DryRun
```

### Show Individual Commands

```powershell
.\install.ps1 -Profile max -ShowCommands
```

This displays individual `winget install` commands you can copy/paste. It is also
the escape hatch when you want a single package without its whole layer — say
Docker on a machine that has no use for Node or the cloud CLIs.

### Help

```powershell
.\install.ps1 -Help
```

---

## 📋 Prerequisites

- **Windows 10** (version 1809+) or **Windows 11**
- **winget** (Windows Package Manager) - Pre-installed on Windows 11
- **PowerShell 5.0+** - Pre-installed on modern Windows
- **Administrator privileges** - most packages install machine-wide

`-DryRun` and `-ShowCommands` do not install anything, so they run fine without
elevation.

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

2. Add to the profile file for the lowest level that should get it
   (`winget/packages-mini.txt`, `packages-plus.txt`, etc.):
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

### "Administrator privileges required"

The scripts refuse to start without elevation, because packages like Office,
Docker and TeamViewer install machine-wide and would fail one by one.

**Solution:**
- Press Win+X → *Terminal (Admin)* or *Windows PowerShell (Admin)*
- Run the same command again

To install without elevation anyway — only user-scope packages will succeed:

```powershell
.\install.ps1 -Profile plus -SkipAdminCheck
```

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
├── bootstrap.ps1                 # Remote installer + mini one-liner
├── bootstrap-base.ps1            # One-liner: base
├── bootstrap-plus.ps1            # One-liner: plus
├── bootstrap-pro.ps1             # One-liner: pro
├── bootstrap-max.ps1             # One-liner: max
├── install.ps1                   # Main installation script
├── winget/
│   ├── packages-mini.txt         # Each file holds only its own layer;
│   ├── packages-base.txt         # install.ps1 walks the ladder and
│   ├── packages-plus.txt         # merges every level below the one
│   ├── packages-pro.txt          # you asked for
│   └── packages-max.txt
├── npm/
│   └── packages-pro.txt          # Global npm packages (needs Node.js, in pro)
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
