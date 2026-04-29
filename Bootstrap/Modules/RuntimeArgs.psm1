function ConvertTo-RuntimeValueText {
    param([Parameter(Mandatory)]$Value)

    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }

    return [string]$Value
}

function Write-RuntimeArguments {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Settings
    )

    if (-not (Test-BootstrapModuleEnabled -Context $Context -ModuleName "VM Args" -Enabled $Settings.enabled)) {
        return
    }

    Write-Host ""
    Write-Host "VM / Runtime Arguments" -ForegroundColor Cyan

    $jsonOutputPath = Resolve-BootstrapPath -Context $Context -Path $Settings.jsonOutputPath
    $devOutputPath = Resolve-BootstrapPath -Context $Context -Path $Settings.devOutputPath

    Write-BootstrapLog "Runtime args will be stored in $jsonOutputPath and $devOutputPath."

    if ($Context.DryRun) {
        Write-BootstrapLog "Dry-run: would write VM/runtime arguments." -Level "SKIP"
        return
    }

    $jsonFolder = Split-Path -Parent $jsonOutputPath
    $devFolder = Split-Path -Parent $devOutputPath
    New-Item -ItemType Directory -Path $jsonFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $devFolder -Force | Out-Null

    $runtimeConfig = [ordered]@{
        VMArgs = [ordered]@{
            EnablePortablePython = [bool]$Settings.values.EnablePortablePython
            UseDevRuntime = [bool]$Settings.values.UseDevRuntime
            DebugMode = [bool]$Settings.values.DebugMode
        }
    }

    $runtimeConfig | ConvertTo-Json -Depth 4 | Set-Content -Path $jsonOutputPath -Encoding UTF8

    $lines = @(
        "[VMArgs]:{"
        "    EnablePortablePython=$(ConvertTo-RuntimeValueText -Value $runtimeConfig.VMArgs.EnablePortablePython)"
        "    UseDevRuntime=$(ConvertTo-RuntimeValueText -Value $runtimeConfig.VMArgs.UseDevRuntime)"
        "    DebugMode=$(ConvertTo-RuntimeValueText -Value $runtimeConfig.VMArgs.DebugMode)"
        "}"
    )
    Set-Content -Path $devOutputPath -Value $lines -Encoding UTF8

    Write-BootstrapLog "VM/runtime arguments written successfully." -Level "OK"
}

Export-ModuleMember -Function *
