# Extracting FortiClient VPN MSI from EXE Installer

The FortiClient VPN EXE installer does not support true silent installation. To deploy via GPO, extract the MSI file using this method.

## Steps

### 1. Download the EXE Installer

Download FortiClient VPN Only from the Fortinet Support portal.

- File format: `FortiClientVPNSetup_7.x.x.xxxx_x64.exe`
- Example: `FortiClientVPNSetup_7.4.3.1790_x64.exe`

Reference: [Technical Tip: How to download FortiClient offline installer](https://community.fortinet.com/t5/FortiGate/Technical-Tip-How-to-download-FortiClient-offline-installer/ta-p/198344)

### 2. Run the EXE (Do NOT Install)

1. Execute the downloaded EXE file
2. The Setup Wizard will appear
3. **Click Cancel** - do not proceed with installation
4. This extracts the MSI to a temporary location

### 3. Locate the Extracted MSI

The MSI is created at:

```
C:\ProgramData\Applications\Cache\<GUID>\<Version>\FortiClientVPN.msi
```

Example path:
```
C:\ProgramData\Applications\Cache\{15C7B361-A0B2-4E79-93E0-868B5000BA3F}\7.4.3.4726\FortiClientVPN.msi
```

### 4. Copy the MSI

Copy `FortiClientVPN.msi` to your deployment share:

```
\\i2i-file1\IT\vpn\FortiClientVPN.msi
```

## Notes

- This method works for FortiClient VPN versions 7.2.x and 7.4.x
- The extracted MSI supports true silent installation via `msiexec /quiet`
- The temp folder is cleaned up after reboot, so copy the MSI immediately

## References

- [Fortinet Community: Extraction of MSI from EXE](https://community.fortinet.com/t5/FortiGate/Technical-Tip-Extraction-of-msi-file-from-exe-file-FortiClient/ta-p/411131)
