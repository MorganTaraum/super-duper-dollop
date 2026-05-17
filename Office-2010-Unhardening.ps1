# Dehardening Office Security Settings (Office 2010 / 14.0)
# Run as Administrator

$officeApps = @("Word", "Excel", "PowerPoint", "Publisher", "Outlook")
$version    = "14.0"  # Change to 15.0 (2013) or 16.0 (2016/2019/365) if needed

# ── COMMON SECURITY (all Office apps) ────────────────────────────────────────
$commonPath = "HKCU:\Software\Microsoft\Office\Common\Security"
New-Item -Path $commonPath -Force | Out-Null
Set-ItemProperty -Path $commonPath -Name "DisableAllActiveX" -Value 0 -Type DWord
Set-ItemProperty -Path $commonPath -Name "UFIControls"       -Value 1 -Type DWord

# ── PER-APP SETTINGS ──────────────────────────────────────────────────────────
foreach ($app in $officeApps) {
    Write-Host "Configuring $app..." -ForegroundColor Yellow

    $secPath      = "HKCU:\Software\Microsoft\Office\$version\$app\Security"
    $pvPath       = "$secPath\ProtectedView"
    $fbPath       = "$secPath\FileBlock"
    $tlPath       = "$secPath\Trusted Locations"
    $generalPath  = "HKCU:\Software\Microsoft\Office\$version\$app\Common\General"
    $policyPath   = "HKCU:\Software\Policies\Microsoft\Office\$version\$app\Security"

    foreach ($path in @($secPath, $pvPath, $fbPath, $tlPath, $generalPath, $policyPath)) {
        New-Item -Path $path -Force | Out-Null
    }

    # General
    Set-ItemProperty -Path $generalPath -Name "ShownOptIn"              -Value 1 -Type DWord

    # Macro / Security
    Set-ItemProperty -Path $secPath -Name "VBAWarnings"                 -Value 1 -Type DWord
    Set-ItemProperty -Path $secPath -Name "AccessVBOM"                  -Value 1 -Type DWord
    Set-ItemProperty -Path $secPath -Name "DisableDDEServerLaunch"      -Value 0 -Type DWord
    Set-ItemProperty -Path $secPath -Name "ExtensionHardening"          -Value 0 -Type DWord
    Set-ItemProperty -Path $secPath -Name "UFIControls"                 -Value 1 -Type DWord
    Set-ItemProperty -Path $secPath -Name "EnableDEP"                   -Value 1 -Type DWord

    # Policy
    Set-ItemProperty -Path $policyPath -Name "MarkInternalAsUnsafe"     -Value 0 -Type DWord

    # Trusted Locations
    Set-ItemProperty -Path $tlPath -Name "AllowNetworkLocations"        -Value 1 -Type DWord

    # Protected View - disable all
    Set-ItemProperty -Path $pvPath -Name "DisableAttachmentsInPV"       -Value 1 -Type DWord
    Set-ItemProperty -Path $pvPath -Name "DisableInternetFilesInPV"     -Value 1 -Type DWord
    Set-ItemProperty -Path $pvPath -Name "DisableUnsafeLocationsInPV"   -Value 1 -Type DWord

    # File Block - uncheck all
    $fileBlockSettings = @(
        "Word2AndEarlier", "Word6AndEarlier", "Word97AndEarlier", "Word2003",
        "Word2007", "WordOpenXml", "XmlFiles",
        "Excel2AndEarlier", "Excel3AndEarlier", "Excel4Workbooks",
        "Excel4Sheets", "Excel95", "Excel97", "Excel2003",
        "Excel2007", "ExcelOpenXml",
        "PowerPoint2AndEarlier", "PowerPoint97", "PowerPoint2003",
        "PowerPoint2007", "PowerPointOpenXml"
    )
    foreach ($setting in $fileBlockSettings) {
        Set-ItemProperty -Path $fbPath -Name $setting -Value 0 -Type DWord -ErrorAction SilentlyContinue
    }
}

Write-Host "`nDone." -ForegroundColor Green