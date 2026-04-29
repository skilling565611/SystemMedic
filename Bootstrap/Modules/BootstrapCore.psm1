$script:BootstrapLogPath = $null

function Initialize-BootstrapLog {
    param([Parameter(Mandatory)][string]$Path)

    $script:BootstrapLogPath = $Path
    $folder = Split-Path -Parent $Path
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    $header = @(
        ""
        "============================================================"
        "SystemMedic Bootstrap session started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "============================================================"
    )
    Add-Content -Path $script:BootstrapLogPath -Value $header
}

function Write-BootstrapLog {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SKIP", "OK")]
        [string]$Level = "INFO"
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    if ($script:BootstrapLogPath) {
        Add-Content -Path $script:BootstrapLogPath -Value $line
    }

    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SKIP" { "DarkYellow" }
        "OK" { "Green" }
        default { "Gray" }
    }
    Write-Host $line -ForegroundColor $color
}

function Write-BootstrapBanner {
    Write-Host ""
    Write-Host "SystemMedic Workstation Bootstrap" -ForegroundColor Cyan
    Write-Host "Safe rerunnable setup for a fresh Windows development machine."
    Write-Host "No global PATH changes are made by this bootstrap."
    Write-Host ""
}

function Read-BootstrapConfig {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Bootstrap config was not found: $Path"
    }

    Write-BootstrapLog "Loading config from $Path"
    return Get-Content -Path $Path -Raw | ConvertFrom-Json
}

function New-BootstrapContext {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)]$Config,
        [switch]$DryRun,
        [switch]$Yes
    )

    $context = [pscustomobject]@{
        RootPath = $RootPath
        Config = $Config
        DryRun = [bool]$DryRun
        Yes = [bool]$Yes
        EnabledModuleFilter = @()
    }

    if ($context.DryRun) {
        Write-BootstrapLog "Dry-run mode enabled. No installers or import commands will run." -Level "WARN"
    }
    if ($context.Yes) {
        Write-BootstrapLog "Auto-confirm mode enabled." -Level "WARN"
    }

    return $context
}

function Test-BootstrapModuleEnabled {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$ModuleName,
        [bool]$Enabled = $true
    )

    if (-not $Enabled) {
        Write-BootstrapLog "$ModuleName is disabled in config." -Level "SKIP"
        return $false
    }

    if ($Context.EnabledModuleFilter.Count -gt 0 -and $Context.EnabledModuleFilter -notcontains $ModuleName) {
        Write-BootstrapLog "$ModuleName skipped by -Only filter." -Level "SKIP"
        return $false
    }

    return $true
}

function Resolve-BootstrapPath {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$Path
    )

    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)

    if ([System.IO.Path]::IsPathRooted($expandedPath)) {
        return $expandedPath
    }

    return Join-Path $Context.RootPath $expandedPath
}

function Confirm-BootstrapAction {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$Prompt
    )

    if ($Context.Yes) {
        return $true
    }

    $answer = Read-Host "$Prompt [Y/N]"
    return $answer -match "^(y|yes)$"
}

function Test-CommandAvailable {
    param([Parameter(Mandatory)][string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

Export-ModuleMember -Function *
