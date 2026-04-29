# Driver Payloads

Store local driver installers here when preparing an offline/fresh-machine kit.

Suggested layout:

```text
Drivers/
  Network/Setup.exe
  GPU/Setup.exe
  Peripherals/Setup.exe
```

Driver packages are disabled by default in `Bootstrap/Config/BootstrapConfig.json`.
Enable only the packages that match the workstation hardware.
