# dotfiles-win

> Automated Windows application installation using winget with multiple profiles

---

## 🚀 Quick Start

### One-Line Installation

Profiles form a ladder — **each one installs every level below it**:

```
mini  ->  base  ->  pro
```

Open **PowerShell as Administrator** (Win+X → *Terminal (Admin)*) and run the line
for the level you want. The scripts check for elevation and stop with instructions
if it is missing, rather than letting every install fail one by one:

**mini** (a machine for someone else — the essentials):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

**base** (adds passwords, calls and media):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-base.ps1 | iex
```

**pro** (your own machine — browsers, editors, terminals):
```powershell
iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap-pro.ps1 | iex
```

Each run also **asks** about the optional groups that apply. See
[Optional groups](#-optional-groups).

### Other one-liners

Swap the profile name in these for whichever level you want.

**Preview first — lists what is already installed and what would be added.**
Needs neither git nor elevation:
```powershell
$env:DOTFILES_PROFILE="pro"; $env:DOTFILES_DRYRUN="1"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

**Any profile without its own URL**, if you would rather use one address:
```powershell
$env:DOTFILES_PROFILE="pro"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

**Test a branch before merging it:**
```powershell
$env:DOTFILES_BRANCH="my-branch"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

> `DOTFILES_DRYRUN` is consumed when read, so it cannot silently turn a later
> command in the same window into another preview. `DOTFILES_PROFILE` and
> `DOTFILES_BRANCH` persist for the session, so a retry after a network failure
> does not need them typed again — set them to something else, or open a new
> window, to change them.

---

## 📋 Profiles

| Profile | Adds | Total | For |
|---|---|---|---|
| `mini` | 5 | 5 | A machine you hand to someone else |
| `base` | +7 | 12 | Everyday family use |
| `pro` | +18 | 30 | Your own machine |

### 🏠 mini — 5
Chrome · Firefox · Adobe Acrobat Reader · 7-Zip · Microsoft Office

### 📦 base — +7
Bitwarden · Rambox · Zoom · Doxie Scanner · QuickLook · ShareX · VLC

### 💼 pro — +18
Dropbox · Brave · Zen Browser · Git · GitHub CLI · VSCode · Windows Terminal ·
WezTerm · Rio · PowerToys · Tailscale · Claude · Claude Code · Sublime Text 4 ·
Spark · **PowerShell 7** · **Starship** · **JetBrains Mono Nerd Font**

The last three are the shell environment. Windows ships PowerShell 5.1 and keeps
it; 7 installs alongside as `pwsh`. Starship reads the same `starship.toml` you
already use elsewhere, and the Nerd Font is what stops its glyphs rendering as
boxes.

---

## 🧰 Optional groups

Runtimes, cloud CLIs and containers are **not** rungs. Whether you want them is a
question about what the machine is *for*, not about how much software it gets —
and wanting Docker does not follow from wanting the cloud CLIs. So the script
asks, and each answer is independent.

| Group | Packages | Offered from | Default |
|---|---|---|---|
| `extras` | TeamViewer · AnyDesk · Google Earth Pro | `mini` | **yes** on mini and base |
| `cli` | bat · eza · fd · ripgrep · fzf · zoxide · yazi · Neovim · lazygit · jq · yq | `pro` | no |
| `dev` | Node.js · Python 3.12 · DBeaver Community | `pro` | no |
| `cloud` | Google Cloud SDK · AWS CLI | `pro` | no |
| `infra` | Docker Desktop · Vagrant | `pro` | no |
| `wsl` | Windows Subsystem for Linux | `pro` | no |

**`extras`** are worth pre-installing on a machine you expect to support, so the
remote access tools are already there the day you need them — and worth leaving
off your own machine, where they are services running at boot for nothing.

Everything else defaults to **no** on purpose: undoing an unwanted install costs
more than running again when you notice something missing. A second run skips
whatever is already there.

To answer in advance, or from a script:

```powershell
.\install.ps1 -Profile pro -Optional dev,cloud
```

With no interactive session the defaults are applied silently rather than
blocking on a prompt nobody can see.

### Adding a group

Drop a `winget/optional-<name>.txt` file with this header and add `<name>` to
`$OptionalGroupNames` in `install.ps1` and `$allGroups` in `bootstrap.ps1`:

```
# Label:   What the prompt calls it
# Offer:   pro
# Default:
```

`Offer` is the lowest rung it appears from; `Default` lists the profiles where the
answer defaults to yes. No other code changes.

---

## 📦 Installation Methods

### Method 1: One-Liner (Recommended)

See [Quick Start](#-quick-start) above.

### Method 2: Manual Clone

Needs git, which this repo installs in `pro` — so on a fresh machine use the
one-liner, or grab the zip:

```powershell
iwr -useb https://github.com/alejakun/dotfiles-win/archive/refs/heads/master.zip -OutFile dotfiles.zip
Expand-Archive dotfiles.zip -DestinationPath .
cd dotfiles-win-master
```

With git available:

```powershell
git clone https://github.com/alejakun/dotfiles-win.git
cd dotfiles-win
.\install.ps1 -Profile pro
```

### Method 3: Picking a Level

Each profile includes the ones below it, so a single command is always enough:

```powershell
.\install.ps1 -Profile pro     # mini + base + pro
```

Packages already installed are detected and skipped, so moving up a level later
only installs what is missing:

```powershell
.\install.ps1 -Profile pro     # mini + base + pro
```

---

## 🛠️ Advanced Usage

### Preview Mode (Dry Run)

Needs neither git nor elevation, so it works on a machine straight out of the box:

```powershell
$env:DOTFILES_PROFILE="pro"; $env:DOTFILES_DRYRUN="1"; iwr -useb https://raw.githubusercontent.com/alejakun/dotfiles-win/master/bootstrap.ps1 | iex
```

`DOTFILES_DRYRUN` is consumed on read, so the next run in the same terminal
installs for real rather than silently previewing again.

From a cloned repo:

```powershell
.\install.ps1 -Profile pro -DryRun
```

Checks each package against winget and marks what is already on the machine, so
you can see the real impact before installing anything:

```
  [=] Google.Chrome
  [+] Zen-Team.Zen-Browser
  [+] wez.wezterm

  [=] already installed   [+] would be installed
```

Detection covers apps installed outside winget too, as long as winget can match
the installed program to its catalogue.

### Show Individual Commands

```powershell
.\install.ps1 -Profile pro -ShowCommands
```

This displays individual `winget install` commands you can copy/paste. It is also
the escape hatch when you want a single package without its whole layer — say
Docker on a machine that has no use for Node or the cloud CLIs.

### Help

```powershell
.\install.ps1 -Help
```

---

## 👥 Setting up a machine for someone else

Run the install from the **administrator account**, elevated. Most packages
install machine-wide, so they are available to every account on the box
regardless of who installed them — `install.ps1` asks winget for machine scope
explicitly rather than letting it choose, since a per-user install would land
only in the installing account's profile and the other user would silently never
see it.

A few packages ship no machine-wide installer at all. Those are listed at the end
of the run under **"Installed for the current user only"**.

To give the other person those, log into their account and run **the same line
you ran the first time**. Seeing it is not elevated, the script explains the
situation and asks whether to continue; answer yes and it installs what does not
need elevation.

Anything the administrator already installed machine-wide is detected and
skipped, and the packages that need elevation are listed together at the end
rather than reported as errors. You do not have to know which packages are which,
and there is only one command to remember.

Do **not** run it from the standard account by elevating with the admin's
password: Windows then runs the process as the administrator, so per-user
installs still land in the wrong profile, and you have typed your password into
someone else's session for nothing.

---

## 📋 Prerequisites

- **Windows 10** (version 1809+) or **Windows 11**
- **winget** (Windows Package Manager) - Pre-installed on Windows 11
- **PowerShell 5.0+** - Pre-installed on modern Windows
- **Administrator privileges** - most packages install machine-wide

`-DryRun` and `-ShowCommands` do not install anything, so they run fine without
elevation — they warn that the real install will need it.

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
   (`winget/packages-mini.txt`, `packages-pro.txt`, etc.):
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
.\install.ps1 -Profile pro -SkipAdminCheck
```

---

### "Execution policy" error

Windows ships with script execution disabled (`Restricted`) by default.

**The one-liners already handle this.** They are run from memory by `iex`, which
the policy does not apply to, and they launch `install.ps1` in a child process
with `-ExecutionPolicy Bypass` — so your own session's policy is never changed.

You only hit this running `.\install.ps1` yourself from a clone. Either run it
the same way:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile pro
```

or allow local scripts for your user, which persists:

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
├── bootstrap-pro.ps1             # One-liner: pro
├── install.ps1                   # Main installation script
├── winget/
│   ├── packages-mini.txt         # The ladder. Each file holds only its own
│   ├── packages-base.txt         # layer; install.ps1 merges every level
│   ├── packages-pro.txt          # below the one you asked for
│   ├── optional-extras.txt       # Optional groups, asked at run time.
│   ├── optional-dev.txt          # Metadata in each file header decides
│   ├── optional-cloud.txt        # where it is offered and its default
│   └── optional-infra.txt
├── npm/
│   └── optional-dev.txt          # Global npm packages, tied to the dev group
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
