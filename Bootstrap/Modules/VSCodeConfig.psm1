function Get-VSCodeCommand {
    if (Test-CommandAvailable -Command "code") {
        return "code"
    }

    $candidate = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
    if (Test-Path $candidate) {
        return $candidate
    }

    return $null
}

function Copy-OptionalFolder {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Label
    )

    $resolvedSource = Resolve-BootstrapPath -Context $Context -Path $Source
    if (-not (Test-Path $resolvedSource)) {
        Write-BootstrapLog "$Label source not found: $resolvedSource" -Level "SKIP"
        return
    }

    if (-not (Confirm-BootstrapAction -Context $Context -Prompt "Import VS Code $Label to $Destination")) {
        Write-BootstrapLog "VS Code $Label import skipped by user." -Level "SKIP"
        return
    }

    if ($Context.DryRun) {
        Write-BootstrapLog "Dry-run: would copy $resolvedSource to $Destination." -Level "SKIP"
        return
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Copy-Item -Path (Join-Path $resolvedSource "*") -Destination $Destination -Recurse -Force
    Write-BootstrapLog "VS Code $Label imported." -Level "OK"
}

function Invoke-VSCodeConfiguration {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Settings
    )

    if (-not (Test-BootstrapModuleEnabled -Context $Context -ModuleName "VS Code Configuration" -Enabled $Settings.enabled)) {
        return
    }

    Write-Host ""
    Write-Host "VS Code Configuration" -ForegroundColor Cyan

    $codeCommand = Get-VSCodeCommand
    if (-not $codeCommand) {
        Write-BootstrapLog "VS Code command was not found. Install VS Code first, then rerun this bootstrap." -Level "WARN"
        return
    }

    foreach ($extension in $Settings.extensions) {
        if (-not $extension.enabled) {
            Write-BootstrapLog "VS Code extension $($extension.id) disabled." -Level "SKIP"
            continue
        }

        if (-not (Confirm-BootstrapAction -Context $Context -Prompt "Install VS Code extension $($extension.id)")) {
            Write-BootstrapLog "VS Code extension $($extension.id) skipped by user." -Level "SKIP"
            continue
        }

        if ($Context.DryRun) {
            Write-BootstrapLog "Dry-run: would install VS Code extension $($extension.id)." -Level "SKIP"
            continue
        }

        & $codeCommand --install-extension $extension.id --force
        if ($LASTEXITCODE -eq 0) {
            Write-BootstrapLog "VS Code extension installed: $($extension.id)" -Level "OK"
        }
        else {
            Write-BootstrapLog "VS Code extension install returned exit code $LASTEXITCODE`: $($extension.id)" -Level "WARN"
        }
    }

    $userData = Join-Path $env:APPDATA "Code\User"
    if ($Settings.settingsSource) {
        Copy-OptionalFolder -Context $Context -Source $Settings.settingsSource -Destination $userData -Label "settings"
    }
    if ($Settings.snippetsSource) {
        Copy-OptionalFolder -Context $Context -Source $Settings.snippetsSource -Destination (Join-Path $userData "snippets") -Label "snippets"
    }
}

Export-ModuleMember -Function *
