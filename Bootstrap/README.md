# SystemMedic Workstation Bootstrap

Lightweight Windows bootstrap system for rebuilding a development workstation
after a reinstall.

## What It Does

- Installs selectable development tools through `winget` when available.
- Imports a portable Python runtime from a local embeddable zip.
- Installs VS Code extensions and optional user settings/snippets.
- Writes reusable VM/runtime arguments for portable runtime behavior.
- Runs optional local utility and driver installers.
- Logs every step to `Bootstrap/Logs/Bootstrap.log`.
- Uses prompts by default and is safe to rerun.

## What It Does Not Do

- It does not modify the global Windows PATH.
- It does not delete files.
- It does not force driver installs.
- It does not assume every optional package exists.

## Quick Start

Run:

```bat
Bootstrap\RunBootstrap.bat
```

Useful options:

```bat
Bootstrap\RunBootstrap.bat -DryRun
Bootstrap\RunBootstrap.bat -Yes
Bootstrap\RunBootstrap.bat -Only Git,"Portable Python"
```

`-DryRun` prints what would happen without running installers.

`-Yes` auto-confirms prompts. Use it only after a dry run looks right.

`-Only` runs selected module names. Module names match item names in the config,
such as `Git`, `Visual Studio Code`, `Opera GX`, or `Portable Python`.

## Configuration

Edit:

```text
Bootstrap/Config/BootstrapConfig.json
```

Each installer item has:

- `name`: Friendly display name.
- `enabled`: Turns the item on or off.
- `wingetId`: Package id for Windows Package Manager.
- `installerPath`: Optional local installer path under `Bootstrap/Payloads`.
- `detectCommand` or `detectPath`: Used to skip already-installed software.

## Portable Python

Download the official Windows embeddable Python zip manually, then place it at:

```text
Bootstrap/Payloads/PortablePython/python-embed-amd64.zip
```

The bootstrap extracts it to:

```text
DevRuntime/Python
```

Use it directly from that folder. The script deliberately avoids global PATH
changes so the runtime stays self-contained.

## VS Code Settings

Default import folders:

```text
Bootstrap/Profiles/VSCode/User
Bootstrap/Profiles/VSCode/snippets
```

Add settings, keybindings, themes, and snippets there over time. The bootstrap
copies them into the current Windows user profile when VS Code is available.

## VM / Runtime Arguments

Runtime arguments are configured in `Bootstrap/Config/BootstrapConfig.json`:

```json
"vmArgs": {
  "enabled": true,
  "values": {
    "EnablePortablePython": true,
    "UseDevRuntime": true,
    "DebugMode": false
  }
}
```

During bootstrap, these are written to reusable root config files:

```text
Config/VMArgs.json
Config/VMArgs.DEV
```

The `.DEV` file keeps the custom lightweight format:

```text
[VMArgs]:{
    EnablePortablePython=true
    UseDevRuntime=true
    DebugMode=false
}
```

## Drivers

Driver automation is local-package only by default. Put hardware-specific
installers under `Bootstrap/Payloads/Drivers`, then enable the matching package
in the config.

Keep only drivers that match the workstation. Network drivers are the most useful
offline payload because they can restore internet access after a fresh install.

## Maintenance Notes

- Add new installable apps to the JSON config before changing script code.
- Prefer `wingetId` for common tools and `installerPath` for offline payloads.
- Keep optional or machine-specific components disabled until needed.
- Rerun the bootstrap any time; installed items should be detected and skipped.
