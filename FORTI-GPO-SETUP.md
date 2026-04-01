# FortiClient VPN GPO Deployment

Deploy FortiClient VPN silently via Group Policy using a scheduled task.

## Prerequisites

1. Extract the MSI from the EXE installer (see [GET-MSI-FORTICLIENT.md](GET-MSI-FORTICLIENT.md))
2. Place files on a network share accessible by domain computers:
   - `\\reso-file1\IT\vpn\FortiClientVPN.msi`
   - `\\reso-file1\IT\vpn\FortiSetup.ps1`
3. Ensure computer accounts have read access to the share

## FortiSetup.ps1 Overview

The script handles:

| Scenario | Action |
|----------|--------|
| FortiClient not installed | Installs target version |
| Older version installed | Upgrades to target version |
| Target version or newer | Exits, no action |

**Target Version:** 7.4.3.4726 (configurable in script)

### Script Behavior

1. Checks registry for installed FortiClient VPN version
2. Compares against target version
3. If install/upgrade needed:
   - Copies MSI to `C:\ProgramData\FortiClientSetup\` (staging)
   - Runs `msiexec /quiet /norestart`
   - Cleans up staging directory

### Logs

| Log | Location |
|-----|----------|
| Script log | `C:\ProgramData\FortiClientInstall.log` |
| MSI verbose log | `C:\ProgramData\FortiClientMSI.log` |

## GPO Configuration

### Create the GPO

1. Open **Group Policy Management**
2. Create a new GPO: `FortiClient VPN Deployment`
3. Link to target OU (workstations)

### Configure Scheduled Task

Navigate to: **Computer Configuration > Preferences > Control Panel Settings > Scheduled Tasks**

1. Right-click > **New > Scheduled Task (At least Windows 7)**

2. **General Tab:**
   - Name: `FortiClient VPN Install`
   - Run as: `NT AUTHORITY\SYSTEM`
   - Run whether user is logged on or not
   - Run with highest privileges

3. **Triggers Tab:**
   - New trigger: **At startup**
   - (Optional) Add daily trigger for ongoing compliance

4. **Actions Tab:**
   - Action: Start a program
   - Program: `powershell.exe`
   - Arguments:
     ```
     -ExecutionPolicy Bypass -File "\\reso-file1\IT\vpn\FortiSetup.ps1"
     ```

5. **Conditions Tab:**
   - Uncheck "Start only if on AC power" (for laptops)

6. **Settings Tab:**
   - Allow task to be run on demand
   - If task fails, restart every 1 hour
   - Stop task if runs longer than 1 hour

## Testing

### Manual Test on Workstation

```powershell
# Run as Administrator
powershell.exe -ExecutionPolicy Bypass -File "\\i2i-file1\IT\vpn\FortiSetup.ps1"
```

### Verify Installation

```powershell
# Check installed version
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName -like "*FortiClient*VPN*" } |
    Select-Object DisplayName, DisplayVersion
```

### Check Logs

```powershell
# Script execution log
Get-Content C:\ProgramData\FortiClientInstall.log

# MSI detailed log (if issues)
Get-Content C:\ProgramData\FortiClientMSI.log
```

## Updating to New Version

1. Extract new MSI (see GET-MSI-FORTICLIENT.md)
2. Replace MSI on share: `\\reso-file1\IT\vpn\FortiClientVPN.msi`
3. Update `$TargetVersion` in FortiSetup.ps1
4. Clients will upgrade on next scheduled task run

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Exit code 1603 | Check MSI log; ensure not running from user TEMP |
| Script not running | Verify share permissions for computer account |
| Version not detected | Check registry paths in script match installation |
| Network share not accessible | Ensure firewall allows SMB; check DNS resolution |
