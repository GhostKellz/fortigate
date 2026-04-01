<#
.SYNOPSIS
    Installs FortiClient VPN if not present or outdated.
.DESCRIPTION
    Checks for FortiClient VPN 7.4.3.4726. Installs from network share
    if missing or older version detected. Intended for GPO scheduled task.
.NOTES
    GPO Task Command: powershell.exe -ExecutionPolicy Bypass -File "\\i2i-file1\IT\vpn\FortiSetup.ps1"
#>

$TargetVersion = "7.4.3.4726"
$MsiPath = "\\reso-file1\IT\vpn\FortiClientVPN.msi"
$LogFile = "$env:ProgramData\FortiClientInstall.log"
$MsiLogFile = "$env:ProgramData\FortiClientMSI.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host $Message
}

function Get-FortiClientVersion {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $regPaths) {
        $installed = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*FortiClient*VPN*" } |
            Select-Object -First 1

        if ($installed) {
            return $installed.DisplayVersion
        }
    }
    return $null
}

function Compare-Version {
    param(
        [string]$Current,
        [string]$Target
    )
    try {
        $currentParts = $Current.Split('.') | ForEach-Object { [int]$_ }
        $targetParts = $Target.Split('.') | ForEach-Object { [int]$_ }

        for ($i = 0; $i -lt [Math]::Max($currentParts.Count, $targetParts.Count); $i++) {
            $c = if ($i -lt $currentParts.Count) { $currentParts[$i] } else { 0 }
            $t = if ($i -lt $targetParts.Count) { $targetParts[$i] } else { 0 }

            if ($c -lt $t) { return -1 }
            if ($c -gt $t) { return 1 }
        }
        return 0
    }
    catch {
        return -1
    }
}

# Main execution
Write-Log "FortiClient VPN deployment check started"

$currentVersion = Get-FortiClientVersion

if ($currentVersion) {
    Write-Log "Found FortiClient VPN version: $currentVersion"

    $comparison = Compare-Version -Current $currentVersion -Target $TargetVersion

    if ($comparison -ge 0) {
        Write-Log "Version $currentVersion meets requirement ($TargetVersion). No action needed."
        exit 0
    }

    Write-Log "Version $currentVersion is older than $TargetVersion. Proceeding with upgrade."
}
else {
    Write-Log "FortiClient VPN not found. Proceeding with installation."
}

# Verify MSI exists
if (-not (Test-Path $MsiPath)) {
    Write-Log "ERROR: MSI not found at $MsiPath"
    exit 1
}

# Stage MSI to ProgramData (not user TEMP - FortiClient has internal copy conflict there)
$stagingDir = "$env:ProgramData\FortiClientSetup"
$localMsi = "$stagingDir\FortiClientVPN.msi"

if (-not (Test-Path $stagingDir)) {
    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
}

Write-Log "Copying MSI to staging directory..."
Copy-Item -Path $MsiPath -Destination $localMsi -Force

# Run msiexec with silent flags
Write-Log "Starting silent MSI installation..."
try {
    $msiArgs = "/i `"$localMsi`" /quiet /norestart /l*v `"$MsiLogFile`" REBOOT=ReallySuppress"
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -WindowStyle Hidden

    if ($process.ExitCode -eq 0) {
        Write-Log "Installation completed successfully (Exit code: 0)"
    }
    elseif ($process.ExitCode -eq 3010) {
        Write-Log "Installation completed. Reboot required (Exit code: 3010)"
    }
    else {
        Write-Log "Installation finished with exit code: $($process.ExitCode)"
        Write-Log "Check MSI log at: $MsiLogFile"
    }
}
catch {
    Write-Log "ERROR: Installation failed - $_"
    exit 1
}
finally {
    # Cleanup staging directory
    Remove-Item -Path $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
}

exit 0
