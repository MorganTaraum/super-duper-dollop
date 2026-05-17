# CAPEv2 Windows 10 Guest - Noise Reduction Script
# Converted from disable_win7noise.bat
# Run as Administrator
# To Use this Script:
# 1. Change AutoLogon part. The Username and Password
# 2. Disable WIndows Defedner Tampering Thing

Write-Host "CAPEv2 Guest Setup - Starting..." -ForegroundColor Cyan
Set-ExecutionPolicy Unrestricted -Scope CurrentUser


# ── W4RH4WK DEBLOAT WINDOWS 10 ───────────────────────────────────────────────────────────────────────
# Download
Invoke-WebRequest -Uri "https://github.com/W4RH4WK/Debloat-Windows-10/archive/master.zip" -OutFile "C:\debloat.zip"

# Extract
Expand-Archive -Path "C:\debloat.zip" -DestinationPath "C:\debloat" -Force

# Unblock all scripts (required or PowerShell will refuse to run them)
Get-ChildItem "C:\debloat\Debloat-Windows-10-master\scripts\*" | Unblock-File

# Navigate to scripts folder
Set-Location "C:\debloat\Debloat-Windows-10-master\scripts"

Import-Module -DisableNameChecking $PSScriptRoot\..\lib\New-FolderForced.psm1
Import-Module -DisableNameChecking $PSScriptRoot\..\lib\take-own.psm1

# Disable telemetry and data collection
.\block-telemetry.ps1

# Disable services you don't need
.\disable-services.ps1

# Disable Windows Defender (May need to run twice this one. Run once, reboot, run again, reboot)
.\disable-windows-defender.ps1

# Selected Privacy Ones
.\fix-privacy-settings.ps1

# UI Imrpovements

# This removes the "Trending Searches" results shown when you click on the windows search bar
Write-Output "Disabling Trending Searches"
New-FolderForced -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1

Write-Output "Disable easy access keyboard stuff"
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506"
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" "Flags" "122"
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" "Flags" "58"

Write-Output "Disable Aero-Shake Minimize feature"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "DisallowShaking" 1

Write-Output "Setting default explorer view to This PC"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1


# Windows Update Disabling
.\optimize-windows-update.ps1

# Remove bloatware apps
.\remove-default-apps.ps1

# DELETE ONE DRIVE
.\remove-onedrive.ps1

# ── AutoLogon ───────────────────────────────────────────────────────────────────────
# Change the <USERNAME> and <PASSWORD> value
# reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d <USERNAME> /f
# reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d <PASSWORD> /f

Write-Host "[*] Enabling AutoLogon..." -ForegroundColor Yellow
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d abu_aayob /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d abu_aayob /f



# ── Restrict Internet Communication ───────────────────────────────────────────────────────────────────────
Write-Host "[*] Restricting Internet Connection..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Internet Connection Wizard" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Internet Connection Wizard" `
    -Name "ExitOnMSICW" -Value 1 -Type DWord

# 5.2 Do it at path too
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$newPath = ($currentPath -split ";" | Where-Object { $_ -notlike "*WindowsApps*" }) -join ";"
[Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)


# 6. Disable Firewall for all profiles:
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# ── NTP ───────────────────────────────────────────────────────────────────────
Write-Host "[*] Configuring NTP..." -ForegroundColor Yellow
reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v LocalNTP /t REG_DWORD /d 0 /f | Out-Null

# ── UAC ───────────────────────────────────────────────────────────────────────
Write-Host "[*] Disabling UAC..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "EnableLUA" -Value 0 -Type DWord

# ── WINDOWS DEFENDER ──────────────────────────────────────────────────────────
Write-Host "[*] Disabling Windows Defender..." -ForegroundColor Yellow
Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue
Set-Service  -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue

$defenderPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
New-Item -Path $defenderPath -Force | Out-Null
Set-ItemProperty -Path $defenderPath -Name "DisableAntiSpyware" -Value 1 -Type DWord

$rtpPath = "$defenderPath\Real-Time Protection"
New-Item -Path $rtpPath -Force | Out-Null
Set-ItemProperty -Path $rtpPath -Name "DisableRealtimeMonitoring"   -Value 1 -Type DWord
Set-ItemProperty -Path $rtpPath -Name "DisableBehaviorMonitoring"   -Value 1 -Type DWord
Set-ItemProperty -Path $rtpPath -Name "DisableOnAccessProtection"   -Value 1 -Type DWord
Set-ItemProperty -Path $rtpPath -Name "DisableScanOnRealtimeEnable" -Value 1 -Type DWord

# ── WINDOWS UPDATE ────────────────────────────────────────────────────────────
Write-Host "[*] Disabling Windows Update..." -ForegroundColor Yellow
$wuPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
New-Item -Path $wuPath -Force | Out-Null
Set-ItemProperty -Path $wuPath -Name "AUOptions" -Value 1 -Type DWord

Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Set-Service  -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue

# ── FIREWALL ──────────────────────────────────────────────────────────────────
Write-Host "[*] Disabling Firewall..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# ── IPv6 TUNNELING ────────────────────────────────────────────────────────────
Write-Host "[*] Disabling IPv6 tunneling..." -ForegroundColor Yellow
netsh interface teredo set state disabled         | Out-Null
netsh interface ipv6 6to4 set state state=disabled undoonstop=disabled | Out-Null
netsh interface ipv6 isatap set state state=disabled | Out-Null

# ── ACTIVE / PASSIVE PROBING (NCSI) ───────────────────────────────────────────
Write-Host "[*] Disabling network probing..." -ForegroundColor Yellow
$nlaSvcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet"
New-Item -Path $nlaSvcPath -Force | Out-Null
Set-ItemProperty -Path $nlaSvcPath -Name "EnableActiveProbing" -Value 0 -Type DWord
Set-ItemProperty -Path $nlaSvcPath -Name "PassivePollPeriod"   -Value 0 -Type DWord

$ncsiPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator"
New-Item -Path $ncsiPath -Force | Out-Null
Set-ItemProperty -Path $ncsiPath -Name "EnableActiveProbing" -Value 0 -Type DWord

# ── NOISY SERVICES ────────────────────────────────────────────────────────────
Write-Host "[*] Disabling noisy services..." -ForegroundColor Yellow
$services = @(
    "SSDPSRV",              # SSDP Discovery
    "Browser",              # Computer Browser
    "WinHttpAutoProxySvc",  # WinHTTP Web Proxy Auto-Discovery
    "FDResPub",             # Function Discovery Resource Publication
    "ClickToRunSvc",        # Office Click-to-Run
    "DiagTrack",            # Connected User Experiences / Telemetry
    "dmwappushservice",     # WAP Push (telemetry)
    "WSearch",              # Windows Search
    "SysMain"               # Superfetch
)
foreach ($svc in $services) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Set-Service  -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    # Also set via registry (Start=4 = disabled) for services that resist sc
    $regSvcPath = "HKLM:\SYSTEM\CurrentControlSet\services\$svc"
    if (Test-Path $regSvcPath) {
        Set-ItemProperty -Path $regSvcPath -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
    }
    Write-Host "    Disabled: $svc"
}

# ── WINHTTP PROXY / FUNCTION DISCOVERY (registry fallback) ───────────────────
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\WinHttpAutoProxySvc" -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\FDResPub"            -Name "Start" -Value 4 -Type DWord -ErrorAction SilentlyContinue

# ── NETBIOS ───────────────────────────────────────────────────────────────────
Write-Host "[*] Disabling NetBIOS service..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\Lmhosts" -Name "Start" -Value 4 -Type DWord

# Disable NetBIOS over TCP/IP on all adapters
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
foreach ($adapter in $adapters) {
    $adapter.SetTcpipNetbios(2) | Out-Null
}

# ── LLMNR ─────────────────────────────────────────────────────────────────────
Write-Host "[*] Disabling LLMNR..." -ForegroundColor Yellow
$dnsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
New-Item -Path $dnsPath -Force | Out-Null
Set-ItemProperty -Path $dnsPath -Name "EnableMulticast" -Value 0 -Type DWord

# ── IE SETTINGS ───────────────────────────────────────────────────────────────
Write-Host "[*] Configuring IE..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name "Start Page" -Value "" -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxyEnable" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# ── DR. WATSON / AeDebug ──────────────────────────────────────────────────────
Write-Host "[*] Disabling Dr. Watson..." -ForegroundColor Yellow
$aeDebugPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug"
New-Item -Path $aeDebugPath -Force | Out-Null
Set-ItemProperty -Path $aeDebugPath -Name "Auto"              -Value "0" -Type String
Set-ItemProperty -Path $aeDebugPath -Name "AutoExclusionList" -Value "0" -Type String

# ── SSL CERT CHECK ────────────────────────────────────────────────────────────
Write-Host "[*] Disabling SSL cert check..." -ForegroundColor Yellow
$sslPath = "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters\SslBindingInfo"
New-Item -Path $sslPath -Force | Out-Null
Set-ItemProperty -Path $sslPath -Name "DefaultSslCertCheckMode" -Value 1 -Type DWord

# ── MONITOR TIMEOUT ───────────────────────────────────────────────────────────
Write-Host "[*] Disabling monitor timeout..." -ForegroundColor Yellow
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0

# ── TELEMETRY ─────────────────────────────────────────────────────────────────
Write-Host "[*] Disabling telemetry..." -ForegroundColor Yellow
$telPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
New-Item -Path $telPath -Force | Out-Null
Set-ItemProperty -Path $telPath -Name "AllowTelemetry" -Value 0 -Type DWord

# Blank out the AutoLogger ETL file
$etlPath = "C:\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl"
if (Test-Path $etlPath) { Clear-Content $etlPath -ErrorAction SilentlyContinue }

$autoLoggerPath = "HKLM:\SYSTEM\ControlSet001\Control\WMI\AutoLogger"
New-Item -Path $autoLoggerPath -Force | Out-Null
Set-ItemProperty -Path $autoLoggerPath -Name "AutoLogger-Diagtrack-Listener" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# ── POWERSHELL LOGGING (for CAPE visibility) ──────────────────────────────────
Write-Host "[*] Enabling PowerShell logging..." -ForegroundColor Yellow
$psBase = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"

New-Item -Path "$psBase\ModuleLogging\ModuleNames" -Force | Out-Null
Set-ItemProperty -Path "$psBase\ModuleLogging\ModuleNames" -Name "*" -Value "*" -Type String

New-Item -Path "$psBase\ScriptBlockLogging" -Force | Out-Null
Set-ItemProperty -Path "$psBase\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1 -Type DWord

New-Item -Path "$psBase\Transcription" -Force | Out-Null
New-Item -Path "C:\PSTranscripts" -ItemType Directory -Force | Out-Null
Set-ItemProperty -Path "$psBase\Transcription" -Name "EnableTranscripting"    -Value 1 -Type DWord
Set-ItemProperty -Path "$psBase\Transcription" -Name "OutputDirectory"        -Value "C:\PSTranscripts" -Type String
Set-ItemProperty -Path "$psBase\Transcription" -Name "EnableInvocationHeader" -Value 1 -Type DWord

# ── SCHEDULED TASKS ───────────────────────────────────────────────────────────
Write-Host "[*] Disabling scheduled tasks..." -ForegroundColor Yellow
$tasks = @(
    "\Microsoft\Office\Office Automatic Updates 2.0",
    "\Microsoft\Office\Office ClickToRun Service Monitor",
    "\Microsoft\Office\Office Feature Updates",
    "\Microsoft\Office\Office Feature Updates Logon",
    "\Microsoft\Office\OfficeTelemetryAgentFallBack2016",
    "\Microsoft\Office\OfficeTelemetryAgentLogOn2016",
    "\Microsoft\Windows\Application Experience\AitAgent",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Windows Media Sharing\UpdateLibrary"
)
foreach ($task in $tasks) {
    Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
    Write-Host "    Disabled task: $task"
}

# ── WINDOWS STORE ─────────────────────────────────────────────────────────────
Write-Host "[*] Disabling Microsoft Store..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "RemoveWindowsStore" -Value 1 -Type DWord

# Remove WindowsApps from user PATH (CAPE issue #1237)
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$newPath = ($currentPath -split ";" | Where-Object { $_ -notlike "*WindowsApps*" }) -join ";"
[Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)


# ── WINDOWS SEARCH AT INTERNET ─────────────────────────────────────────────────────────────
# Disable web results via policy (machine-wide)
$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
New-Item -Path $policyPath -Force | Out-Null
Set-ItemProperty -Path $policyPath -Name "DisableWebSearch"             -Value 1 -Type DWord
Set-ItemProperty -Path $policyPath -Name "ConnectedSearchUseWeb"        -Value 0 -Type DWord
Set-ItemProperty -Path $policyPath -Name "ConnectedSearchUseWebOverMeteredConnections" -Value 0 -Type DWord

# ── CORTANA ─────────────────────────────────────────────────────────────
# Disable Cortana via policy (recommended for VM - machine-wide)
$cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
New-Item -Path $cortanaPath -Force | Out-Null
Set-ItemProperty -Path $cortanaPath -Name "AllowCortana"                -Value 0 -Type DWord
Set-ItemProperty -Path $cortanaPath -Name "AllowCortanaAboveLock"       -Value 0 -Type DWord
Set-ItemProperty -Path $cortanaPath -Name "AllowSearchToUseLocation"    -Value 0 -Type DWord

# Disable Cortana user consent
$cortanaUserPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
New-Item -Path $cortanaUserPath -Force | Out-Null
Set-ItemProperty -Path $cortanaUserPath -Name "CortanaEnabled"  -Value 0 -Type DWord
Set-ItemProperty -Path $cortanaUserPath -Name "CortanaConsent"  -Value 0 -Type DWord

# Disable Cortana scheduled tasks
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Cortana\QueueReporting"     -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -ErrorAction SilentlyContinue

# OR BETTER YET. UNINSTALL IT!
# Uninstall Cortana app (Win10 2004+ / Win11)
Get-AppxPackage -Name "Microsoft.549981C3F5F10" -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue

# Also remove provisioned package so it doesn't reinstall on new profiles
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*Cortana*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

# ── COPILOT ─────────────────────────────────────────────────────────────
# Disable Copilot via policy (machine-wide)
$copilotPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
New-Item -Path "$copilotPath\WindowsCopilot" -Force | Out-Null
Set-ItemProperty -Path "$copilotPath\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord

# Disable Copilot button in taskbar (current user)
$taskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
New-Item -Path $taskbarPath -Force | Out-Null
Set-ItemProperty -Path $taskbarPath -Name "ShowCopilotButton" -Value 0 -Type DWord

# Disable via user policy too
$copilotUserPolicy = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
New-Item -Path $copilotUserPolicy -Force | Out-Null
Set-ItemProperty -Path $copilotUserPolicy -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord

# Uninstall Copilot app if present (Win11 / recent Win10 builds)
Get-AppxPackage -Name "Microsoft.Windows.Ai.Copilot.Provider" -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name "MicrosoftWindows.Client.Copilot"       -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*Copilot*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

# Disable scheduled tasks
Disable-ScheduledTask -TaskName "\Microsoft\Windows\WindowsCopilot\*" -ErrorAction SilentlyContinue


# ── DONE ──────────────────────────────────────────────────────────────────────
Write-Host "`nDone! Run 'gpupdate /force' then reboot." -ForegroundColor Green
gpupdate /force