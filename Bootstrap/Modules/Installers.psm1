function Test-AppInstalled {
    param([Parameter(Mandatory)]$Item)

    if ($Item.detectCommand) {
        return Test-CommandAvailable -Command $Item.detectCommand
    }

    if ($Item.detectPath) {
        return Test-Path ([Environment]::ExpandEnvironmentVariables($Item.detectPath))
    }

    if ($Item.wingetId -and (Test-CommandAvailable -Command "winget")) {
        $result = winget list --id $Item.wingetId --exact --accept-source-agreements 2>$null
        return $LASTEXITCODE -eq 0 -and ($result -match [regex]::Escape($Item.wingetId))
    }

    return $false
}

function Invoke-InstallerItem {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string]$GroupName
    )

    $name = $Item.name
    if (-not (Test-BootstrapModuleEnabled -Context $Context -ModuleName $name -Enabled $Item.enabled)) {
        return
    }

    if (Test-AppInstalled -Item $Item) {
        Write-BootstrapLog "$name is already installed or available." -Level "OK"
        return
    }

    $summary = "${GroupName}: install $name"
    if (-not (Confirm-BootstrapAction -Context $Context -Prompt $summary)) {
        Write-BootstrapLog "$name skipped by user." -Level "SKIP"
        return
    }

    if ($Context.DryRun) {
        Write-BootstrapLog "Dry-run: would install $name." -Level "SKIP"
        return
    }

    if ($Item.installerPath) {
        $installerPath = Resolve-BootstrapPath -Context $Context -Path $Item.installerPath
        if (-not (Test-Path $installerPath)) {
            Write-BootstrapLog "$name installer not found: $installerPath" -Level "WARN"
            return
        }

        $arguments = @()
        if ($Item.arguments) {
            $arguments = @($Item.arguments)
        }

        Write-BootstrapLog "Starting local installer for $name."
        $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru
        Write-BootstrapLog "$name installer exited with code $($process.ExitCode)."
        return
    }

    if ($Item.wingetId) {
        if (-not (Test-CommandAvailable -Command "winget")) {
            Write-BootstrapLog "winget is not available. Cannot install $name automatically." -Level "WARN"
            return
        }

        Write-BootstrapLog "Installing $name with winget id $($Item.wingetId)."
        winget install --id $Item.wingetId --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "winget install failed for $name with exit code $LASTEXITCODE"
        }
        Write-BootstrapLog "$name installation command completed." -Level "OK"
        return
    }

    Write-BootstrapLog "$name has no installerPath or wingetId configured." -Level "WARN"
}

function Invoke-ConfiguredInstallers {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$GroupName,
        $Items
    )

    if (-not $Items) {
        Write-BootstrapLog "$GroupName has no configured items." -Level "SKIP"
        return
    }

    Write-Host ""
    Write-Host $GroupName -ForegroundColor Cyan
    foreach ($item in $Items) {
        Invoke-InstallerItem -Context $Context -Item $item -GroupName $GroupName
    }
}

Export-ModuleMember -Function *
