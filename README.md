# ASI Coexistence Installer

**Run UE4SS and other `dwmapi.dll` proxy mods together** (The Blood of Dawnwalker).

Small interactive GUI tool. Windows only.

---

## What it does

Many mods hook the game through a "proxy DLL" — usually `dwmapi.dll` (e.g. FPS
uncap mods). But **UE4SS also installs itself as `dwmapi.dll`**, and there can
only be one `dwmapi.dll` in the game folder — so the two collide and one stops
working.

This tool sets up the [Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader)
as `winmm.dll` (or `dxgi.dll` / `version.dll`) so **UE4SS keeps `dwmapi.dll`**
while every other proxy mod is loaded as a `.asi` next to it — as many as you
like, all at once.

## Features

- Auto-detects the game via Steam (Browse fallback for other installs)
- **Remembers your game folder** across restarts
- "Set up everything" — installs the loader in one click, optionally adds a mod
- **Drag & drop a mod's `.dll` onto the window** → copied to `Win64\scripts\`
  as a `.asi`, no manual renaming
- Enable / disable / remove mods from a list
- Proxy dropdown: `winmm.dll` / `dxgi.dll` / `version.dll`

## Install

Grab the latest release: **[Releases](../../releases)**
(or download the tool ZIP from the Nexus mod page).

Unzip anywhere, keep the `loader\` folder next to the `.exe`, double-click
`ASI Coexistence Installer.exe`.

## Requirements

- Windows, PowerShell 5.1+ (built into Windows)
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) installed separately
- The proxy mod(s) you want to run alongside it
- If your game is in `C:\Program Files\...` right-click the `.exe` → *Run as
  administrator* (writing there needs it). Games on other drives don't.

## Build from source

The `.exe` is the PowerShell script wrapped with [ps2exe](https://github.com/MScholtes/PS2EXE):

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe -inputFile 'ASI Coexistence Installer.ps1' `
              -outputFile 'ASI Coexistence Installer.exe' `
              -noConsole -title 'ASI Coexistence Installer' `
              -product 'ASI Coexistence Installer' -version '1.1.0'
```

You can also run the `.ps1` directly (right-click → Run with PowerShell) —
no `.exe` needed.

## Antivirus false-positives

The `.exe` is PowerShell wrapped with ps2exe. Windows Defender / SmartScreen
sometimes flag ps2exe tools as generic PowerShell wrappers — **it is not
malware**. The full source is in this repo; you can read it and build it
yourself, or just run the `.ps1` directly.

## What it does under the hood

1. Copies `winmm.dll` (from `loader\`) into `...\Dawnwalker\Binaries\Win64\`
2. Copies `global.ini` (loader config: `LoadFromScriptsOnly=1`) next to it
3. Creates `Win64\scripts\` if missing
4. When you add a mod, its DLL is copied there as `<Name>.asi`

Nothing else. Fully reversible: "Remove loader" deletes the proxy DLL and
`global.ini`; `scripts\` stays so you don't lose your mods.

## Credits

- [Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader)
  by ThirteenAG (MIT) — the actual loader; `winmm.dll` / `dxgi.dll` /
  `version.dll` in `loader\` **are** this file, renamed (it forwards by its
  own filename).
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)

## License

MIT — see [LICENSE](LICENSE).
