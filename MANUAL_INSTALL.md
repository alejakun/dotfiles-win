# Manual Installation Required

Some applications may not be available via winget or require manual installation for full functionality.

---

## Microsoft Office

**Status:** ✅ Installed automatically as part of the `mini` profile

Office is no longer a manual install. `Microsoft.Office` is in the winget
repository and ships the Click-to-Run installer, so it installs unattended along
with the rest of the profile.

**If Office is already installed on the machine:**

This is the one package where installing over an existing copy is not a no-op.
The winget package drives Click-to-Run, so on a machine that already has Office —
common on family computers that shipped with it preinstalled — it can reconfigure
the edition or the update channel rather than simply detecting the existing
install and skipping.

`winget list --id Microsoft.Office --exact` tells you whether winget already sees
it, and `.\install.ps1 -Profile mini -DryRun` shows it as `[=]` if so. If winget
cannot match it, comment the `Microsoft.Office` line out of
`winget/packages-mini.txt` before running.

**What still needs you:**
- Activation happens on **first launch**, not at install time. Open any Office app
  and sign in with the Microsoft account that holds the licence.
- Without a Microsoft 365 subscription or a standalone licence, the apps install
  but run in reduced-functionality mode.
- Corporate machines may be required to use the organisation's own deployment
  method instead — check with your IT department before relying on this.

**If the winget installation fails:**

1. Visit https://www.office.com/
2. Sign in with your Microsoft account
3. Install from your account dashboard

**Alternative (Free):**
- LibreOffice: `winget install TheDocumentFoundation.LibreOffice`
- OnlyOffice: `winget install ONLYOFFICE.DesktopEditors`
- Web-based: https://www.office.com/ (limited features, free)

---

## Ansible

**Status:** ⚠️ Not available in winget - and not supported on Windows natively

**Why manual:**
- No publisher matching "Ansible" exists in the winget repository
- More importantly, Ansible does not support Windows as a **control node**.
  Installing it with `pip` on native Windows produces a configuration the Ansible
  project does not support, even though the install itself succeeds.
- The supported path on Windows is WSL. Windows machines can still be *managed*
  as targets from a Linux control node.

**Installation (via WSL):**

1. Enable WSL if you have not already:
   ```powershell
   wsl --install
   ```
2. Restart, then open the Linux shell and install Ansible:
   ```bash
   sudo apt update
   sudo apt install ansible
   ```
3. Verify:
   ```bash
   ansible --version
   ```

**Alternative:** run Ansible from any Linux or macOS machine you already have,
and point it at the Windows hosts you want to manage.

---

## Kaspersky Antivirus

**Status:** ⚠️ Not available in winget - Requires manual installation

**Why manual:**
- Kaspersky products are not available in the official winget repository
- Requires license activation and account registration
- Different product tiers (Standard, Plus, Premium)

**Installation:**

1. **Download from official site:**
   - Visit: https://www.kaspersky.com/
   - Select your product (Standard, Plus, or Premium)
   - Download installer

2. **Run installer:**
   - Execute downloaded file
   - Follow installation wizard
   - Accept license agreement

3. **Activation:**
   - Enter activation code (if purchased)
   - Create or sign in to My Kaspersky account
   - Complete activation process

**Product Options:**
- **Kaspersky Standard** - Essential antivirus protection
- **Kaspersky Plus** - Standard + VPN and privacy tools
- **Kaspersky Premium** - Plus + identity protection

**Alternative (Free):**
- **Windows Defender** - Built-in Windows protection (already installed)
- **Malwarebytes Free** - Download from https://www.malwarebytes.com/

**Note:** Kaspersky may become available in winget in the future. Check with:
```powershell
winget search kaspersky
```

---

## VMware Workstation Pro

**Status:** ⚠️ Not available in winget - Requires manual installation

**Why manual:**
- Following the Broadcom acquisition, distribution moved to Broadcom's own
  portal and the package was dropped from the winget repository
- Downloading requires a free Broadcom account
- The `VMware` publisher still exists in winget but only ships SpringToolSuite

**Installation:**

1. Create a free account at https://www.broadcom.com/
2. Go to the support portal downloads section
3. Select **VMware Workstation Pro** for Windows
4. Accept the terms and download the installer

**Note:** Workstation Pro is free for personal, non-commercial use. Commercial
use requires a paid license.

**Alternative (available via winget):**
- VirtualBox: `winget install Oracle.VirtualBox`
- Hyper-V: built into Windows Pro/Enterprise, enable via
  "Turn Windows features on or off"

---

## Krisp

**Status:** ⚠️ Not available in winget - Requires manual installation

**Why manual:**
- Krisp is distributed only from the vendor's own site
- Requires account registration to activate
- No publisher matching "Krisp" exists in the winget repository

**Installation:**

1. Download from https://krisp.ai/
2. Run the installer
3. Create or sign in to a Krisp account

**Note:** The free tier caps noise-cancelled minutes per week.

**Alternatives (free):**
- **NVIDIA Broadcast** - noise removal on RTX GPUs, https://www.nvidia.com/broadcast/
- **Built-in suppression** - Microsoft Teams and Zoom both ship their own noise
  suppression, which may be enough on its own

---

## Adobe Acrobat Reader

**Status:** ✅ Usually available via winget as `Adobe.Acrobat.Reader.64-bit`

**If winget installation fails:**

1. Download from official site: https://get.adobe.com/reader/
2. Uncheck optional offers (McAfee, etc.)
3. Run installer

**Alternative (Lightweight):**
- SumatraPDF: `winget install SumatraPDF.SumatraPDF`
- Foxit Reader: `winget install Foxit.FoxitReader`

---

## Google Earth Pro

**Status:** ✅ Available as `Google.EarthPro`

**If winget installation fails:**

1. Download: https://www.google.com/earth/versions/
2. Select "Google Earth Pro for desktop"
3. Install for personal or business use (both free)

**Note:** Google Earth Pro is free but requires activation:
- Name: (Your name)
- License Key: `GEPFREE` (works for all users)

---

## TeamViewer

**Status:** ✅ Available as `TeamViewer.TeamViewer`

**If winget installation fails:**

1. Download: https://www.teamviewer.com/
2. Choose installation type:
   - **Personal use:** Free for non-commercial use
   - **Business use:** Requires license

**Note:** First launch will ask about usage type (personal vs commercial)

**Alternative:**
- AnyDesk (see below)
- Chrome Remote Desktop (browser-based, free)

---

## AnyDesk

**Status:** ✅ Available as `AnyDesk.AnyDesk`

**If winget installation fails:**

1. Download: https://anydesk.com/
2. Choose version:
   - **Portable:** No installation required
   - **Installed:** Full features, auto-start

**Note:** Free for personal use, license required for commercial use

---

## Verification Commands

### Check if package is available

```powershell
# Search for package
winget search "Package Name"

# Show package details
winget show --id PackageId
```

### List installed packages

```powershell
# All installed packages
winget list

# Specific package
winget list --id PackageId
```

### Upgrade packages

```powershell
# Upgrade all
winget upgrade --all

# Upgrade specific package
winget upgrade --id PackageId
```

---

## Troubleshooting

### Package not found

Some packages may have different IDs or may not be in winget yet.

**Search alternatives:**
```powershell
winget search "partial name"
```

**Common variations:**
- `Microsoft.Office` vs `Microsoft.Office.365`
- `Adobe.Reader` vs `Adobe.Acrobat.Reader.64-bit`

### Installation fails with "installer hash mismatch"

This usually means the package was updated but winget cache is stale.

**Solution:**
```powershell
# Update winget sources
winget source update

# Try again
winget install --id PackageId
```

### "Access denied" errors

**Solution:**
- Run PowerShell as Administrator
- Right-click Start → Windows Terminal (Admin)

### Multiple versions available

**Solution:**
```powershell
# Show available versions
winget show --id PackageId

# Install specific version
winget install --id PackageId --version 1.2.3
```

---

## Additional Recommended Apps

These weren't in the original list but are commonly useful:

### Productivity
```powershell
winget install Notepad++.Notepad++         # Advanced text editor
winget install VideoLAN.VLC                # Media player
winget install ShareX.ShareX               # Screenshots & screen recording
```

### Development
```powershell
winget install Microsoft.PowerToys         # Windows utilities
winget install Microsoft.WindowsTerminal   # Modern terminal
winget install Docker.DockerDesktop        # Containers
```

### Communication
```powershell
winget install Discord.Discord             # Chat/voice
winget install Slack.Slack                 # Team communication
winget install Zoom.Zoom                   # Video conferencing
```

---

**Last updated:** 2025-10-20
