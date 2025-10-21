# Manual Installation Required

Some applications may not be available via winget or require manual installation for full functionality.

---

## Microsoft Office

**Status:** ⚠️ Requires license and manual installation

**Why manual:**
- Requires valid Microsoft 365 subscription or standalone license
- Needs Microsoft account authentication
- Corporate deployments use organization-specific methods

**Installation:**

1. **Microsoft 365 (Subscription)**
   - Visit: https://www.office.com/
   - Sign in with your Microsoft account
   - Install from your account dashboard

2. **Standalone Office**
   - Visit: https://www.microsoft.com/microsoft-365/buy/compare-all-microsoft-365-products
   - Purchase and download
   - Activate with product key

3. **Corporate/Organization**
   - Use your organization's deployment portal
   - Contact IT department for installation instructions

**Alternative (Free):**
- LibreOffice: `winget install TheDocumentFoundation.LibreOffice`
- OnlyOffice: `winget install ONLYOFFICE.DesktopEditors`
- Web-based: https://www.office.com/ (limited features, free)

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
