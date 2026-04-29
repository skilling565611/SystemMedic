[CmdletBinding()]
param(
    [string]$ConfigPath,
    [switch]$DryRun,
    [switch]$Yes,
    [string[]]$Only
)

$ErrorActionPreference = "Stop"

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $PSScriptRoot "Config\BootstrapConfig.json"
}

Import-Module (Join-Path $PSScriptRoot "Modules\BootstrapCore.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\Installers.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\PortablePython.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\VSCodeConfig.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\RuntimeArgs.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\Drivers.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "Modules\FutureHooks.psm1") -Force

$LogPath = Join-Path $PSScriptRoot "Logs\Bootstrap.log"
Initialize-BootstrapLog -Path $LogPath

Write-BootstrapBanner
Write-BootstrapLog "Bootstrap started. Config: $ConfigPath"

try {
    $config = Read-BootstrapConfig -Path $ConfigPath
    $context = New-BootstrapContext -RootPath $PSScriptRoot -Config $config -DryRun:$DryRun -Yes:$Yes

    if ($Only.Count -gt 0) {
        Write-BootstrapLog "Filtering enabled modules to: $($Only -join ', ')"
        $context.EnabledModuleFilter = $Only
    }

    Invoke-ConfiguredInstallers -Context $context -GroupName "Core Development" -Items $config.coreDevelopment
    Install-PortablePython -Context $context -Settings $config.portablePython
    Invoke-ConfiguredInstallers -Context $context -GroupName "Browser" -Items $config.browser
    Invoke-VSCodeConfiguration -Context $context -Settings $config.vsCode
    Write-RuntimeArguments -Context $context -Settings $config.vmArgs
    Invoke-ConfiguredInstallers -Context $context -GroupName "Utilities" -Items $config.utilities
    Invoke-DriverPackages -Context $context -Settings $config.drivers
    Invoke-FutureHooks -Context $context -Settings $config.futureFeatures

    Write-BootstrapLog "Bootstrap completed successfully."
    Write-Host ""
    Write-Host "All enabled bootstrap steps are complete. Log written to:" -ForegroundColor Green
    Write-Host "  $LogPath"
    exit 0
}
catch {
    Write-BootstrapLog "Bootstrap failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Host ""
    Write-Host "Bootstrap stopped because something failed:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""
    Write-Host "The log has the full trail:"
    Write-Host "  $LogPath"
    exit 1
}
