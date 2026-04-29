function Install-PortablePython {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Settings
    )

    if (-not (Test-BootstrapModuleEnabled -Context $Context -ModuleName "Portable Python" -Enabled $Settings.enabled)) {
        return
    }

    Write-Host ""
    Write-Host "Portable Python" -ForegroundColor Cyan

    $targetPath = Resolve-BootstrapPath -Context $Context -Path $Settings.targetPath
    $pythonExe = Join-Path $targetPath "python.exe"

    if (Test-Path $pythonExe) {
        Write-BootstrapLog "Portable Python already exists at $pythonExe." -Level "OK"
        return
    }

    if (-not $Settings.sourceArchive) {
        Write-BootstrapLog "No sourceArchive configured for Portable Python. Place the embeddable zip in Bootstrap\Payloads\PortablePython and update config." -Level "WARN"
        return
    }

    $archive = Resolve-BootstrapPath -Context $Context -Path $Settings.sourceArchive
    if (-not (Test-Path $archive)) {
        Write-BootstrapLog "Portable Python archive not found: $archive" -Level "WARN"
        return
    }

    if (-not (Confirm-BootstrapAction -Context $Context -Prompt "Extract portable Python to $targetPath")) {
        Write-BootstrapLog "Portable Python extraction skipped by user." -Level "SKIP"
        return
    }

    if ($Context.DryRun) {
        Write-BootstrapLog "Dry-run: would extract $archive to $targetPath." -Level "SKIP"
        return
    }

    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    Expand-Archive -Path $archive -DestinationPath $targetPath -Force

    if (Test-Path $pythonExe) {
        Write-BootstrapLog "Portable Python extracted successfully. No global PATH changes were made." -Level "OK"
    }
    else {
        Write-BootstrapLog "Archive extracted, but python.exe was not found at $pythonExe." -Level "WARN"
    }
}

Export-ModuleMember -Function *
