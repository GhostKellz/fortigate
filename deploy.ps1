# deploy.ps1
# Deploy FortiClient IPsec VPN config from XML via GPO Startup Script
## Deploy via GPO sceduled task 
## Scheduled task - At start up, Creation/Modification and Login 
## Program Script: powershell 
## Arguments -ExecutionPolicy Bypass -File "\\RESO-FILE1\it\vpn\deploy.ps1" Or whatever the path of this vpn deployment script is 

## XML File generate via system with forticlient installed and with VPN profile configured
## EXPORT  xml file via cli:
## & "C:\Program Files\Fortinet\FortiClient\fcconfig.exe" -m vpn -o export -f "C:\Temp\vpn.xml" -p "Password2026"
## 
## Import
## & "C:\Program Files\Fortinet\FortiClient\fcconfig.exe" -m vpn -o import -f "C:\Temp\vpn.xml" -p "Password2026"
$xmlSource = "\\RESO-FILE1\IT\vpn\vpn.xml"
$xmlLocal  = "C:\Temp\vpn.xml"
$fcPath    = "C:\Program Files\Fortinet\FortiClient\fcconfig.exe"
$password  = "Password2026GoesHere"
$marker    = "C:\Temp\reso_vpn_imported.txt"
$logFile   = "C:\Program Data\RTScripts\reso_vpn_deploy.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $Message"
}

try {
    if (!(Test-Path "C:\Temp")) {
        New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
    }

    Write-Log "Starting FortiClient IPsec VPN deployment."

    if (Test-Path $marker) {
        Write-Log "Marker file exists. VPN already imported. Exiting."
        exit 0
    }

    if (!(Test-Path $fcPath)) {
        Write-Log "FortiClient not found at $fcPath. Exiting."
        exit 0
    }

    if (!(Test-Path $xmlSource)) {
        Write-Log "Source XML not found: $xmlSource. Exiting."
        exit 1
    }

    Copy-Item -Path $xmlSource -Destination $xmlLocal -Force
    Write-Log "Copied XML from $xmlSource to $xmlLocal."

    & $fcPath -m vpn -o import -f $xmlLocal -p $password
    $exitCode = $LASTEXITCODE

    Write-Log "fcconfig import completed with exit code $exitCode."

    if ($exitCode -eq 0) {
        New-Item -Path $marker -ItemType File -Force | Out-Null
        Write-Log "Import successful. Marker file created."
        exit 0
    } else {
        Write-Log "Import failed."
        exit $exitCode
    }
}
catch {
    Write-Log "Unhandled e:rror: $($_.Exception.Message)"
    exit 1
}
