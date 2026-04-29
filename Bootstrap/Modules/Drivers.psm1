function Invoke-DriverPackages {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Settings
    )

    if (-not (Test-BootstrapModuleEnabled -Context $Context -ModuleName "Drivers" -Enabled $Settings.enabled)) {
        return
    }

    Write-Host ""
    Write-Host "Drivers / Hardware" -ForegroundColor Cyan
    Write-BootstrapLog "Driver automation is local-package only by default for safety."

    foreach ($package in $Settings.packages) {
        if (-not $package.enabled) {
            Write-BootstrapLog "Driver package $($package.name) disabled." -Level "SKIP"
            continue
        }

        $installer = Resolve-BootstrapPath -Context $Context -Path $package.installerPath
        if (-not (Test-Path $installer)) {
            Write-BootstrapLog "Driver package not found for $($package.name): $installer" -Level "SKIP"
            continue
        }

        if (-not (Confirm-BootstrapAction -Context $Context -Prompt "Run driver package $($package.name)")) {
            Write-BootstrapLog "Driver package $($package.name) skipped by user." -Level "SKIP"
            continue
        }

        if ($Context.DryRun) {
            Write-BootstrapLog "Dry-run: would run driver installer $installer." -Level "SKIP"
            continue
        }

        $arguments = @()
        if ($package.arguments) {
            $arguments = @($package.arguments)
        }

        $process = Start-Process -FilePath $installer -ArgumentList $arguments -Wait -PassThru
        Write-BootstrapLog "Driver package $($package.name) exited with code $($process.ExitCode)."
    }
}

Export-ModuleMember -Function *
