# Minecraft Splitscreen Handheld / Bazzite Installer

Simple installer for running **Minecraft splitscreen (1–4 players)** on **Steam Deck, and other handheld devices optimized for Bazzite** using **Prism Launcher**.

## What This Does
- Detects or installs **Prism Launcher** (supports both **AppImage** and **Flatpak**)
- Creates 4 splitscreen instances (`latestUpdate-1` to `latestUpdate-4`)
- Installs Fabric and required splitscreen mods
- Lets you choose optional compatible mods
- Lets you add custom Modrinth/CurseForge mods with compatibility checks
- Optionally adds launchers to Steam and desktop

## Core Mods (Required)
- [Controllable](https://www.curseforge.com/minecraft/mc-mods/controllable)
- [Splitscreen Support](https://modrinth.com/mod/splitscreen)

## Optional Mods
- [Better Name Visibility](https://modrinth.com/mod/better-name-visibility)
- [Full Brightness Toggle](https://modrinth.com/mod/full-brightness-toggle)
- [In-Game Account Switcher](https://modrinth.com/mod/in-game-account-switcher)
- [Just Zoom](https://modrinth.com/mod/just-zoom)
- [Mod Menu](https://modrinth.com/mod/modmenu)
- [Old Combat Mod](https://modrinth.com/mod/old-combat-mod)
- [Reese's Sodium Options](https://modrinth.com/mod/reeses-sodium-options)
- [Sodium](https://modrinth.com/mod/sodium)
- [Sodium Dynamic Lights](https://modrinth.com/mod/sodium-dynamic-lights)
- [Sodium Extra](https://modrinth.com/mod/sodium-extra)
- [Sodium Extras](https://modrinth.com/mod/sodium-extras)

## Requirements
- Linux (Bazzite, Steam Deck, ROG Ally, Lenovo Legion Go, or desktop Linux)
- Internet connection for install/update
- `bash`, `curl` or `wget`, and `jq`
- Python 3 only if you want automatic Steam shortcut integration
- `flatpak` (only if using Flatpak installation option)

No manual Java setup is required. The installer detects and installs the needed Java version automatically.

## Install

### Option 1: Auto-Detection (Recommended)
The installer will automatically detect if Prism Launcher is already installed (Flatpak or AppImage) and use it:
```sh
wget https://raw.githubusercontent.com/LukeDlbrg/MinecraftSplitscreenBazzite/main/install-minecraft-splitscreen.sh
chmod +x install-minecraft-splitscreen.sh
./install-minecraft-splitscreen.sh
```

### Option 2: Force Flatpak Installation
Use this if you want to use Prism Launcher via Flatpak (will install it automatically if missing):
```sh
./install-minecraft-splitscreen.sh --launcher flatpak
```

### Option 3: Force AppImage Installation
Use this if you want to download and use Prism Launcher as an AppImage:
```sh
./install-minecraft-splitscreen.sh --launcher appimage
```

### Debug Mode
Use this if you want verbose logs:
```sh
./install-minecraft-splitscreen.sh --debug
./install-minecraft-splitscreen.sh --launcher flatpak --debug
```

## How Installation Works
1. **Detects or installs Prism Launcher** (AppImage or Flatpak based on your choice)
2. Lets you pick a compatible Minecraft version
3. Detects/installs the correct Java version
4. Checks mod compatibility and lets you choose optional mods
5. Optionally accepts custom mods (URL/ID), validates compatibility, and warns about risk
6. Creates/updates 4 manual Prism Launcher instances with Fabric
7. Installs mods and dependencies
8. Optionally adds Steam + desktop shortcuts (Steam integration is optional on Bazzite)

### Custom Mod Input Formats
- Easiest CurseForge format: paste only the numeric project ID (example: `422301`)
- Easiest Modrinth format: paste mod URL or slug (example: `https://modrinth.com/mod/sodium` or `sodium`)
- Also supported: `mr:<slug-or-id>` and `cf:<id>`

Quick examples:
- `422301`
- `sodium`
- `https://modrinth.com/mod/sodium`
- `cf:422301`

Custom mods are validated against Fabric and your exact selected Minecraft version. If incompatible, the installer lets you skip it or stop. If the mod supports Fabric but not your selected Minecraft version, it also offers switching to a supported version.

Minecraft version selection is list-based (no manual custom version entry).  
If a custom mod is incompatible, you can choose to switch versions and the installer will show only versions that support both core mods and that requested custom mod.

## Launching
After install, run the splitscreen launcher script:

### For Flatpak Installation:
```sh
~/.var/app/org.prismlauncher.PrismLauncher/config/prismlauncher/minecraftSplitscreen.sh
```

### For AppImage Installation:
```sh
~/.local/share/PrismLauncher/minecraftSplitscreen.sh
```

You can also launch from Steam or desktop if you enabled those integrations.

## Install Locations

### For Flatpak Installation:
- Main directory: `~/.var/app/org.prismlauncher.PrismLauncher/config/prismlauncher/`
- Splitscreen launcher: `~/.var/app/org.prismlauncher.PrismLauncher/config/prismlauncher/minecraftSplitscreen.sh`
- Instances: `~/.var/app/org.prismlauncher.PrismLauncher/config/prismlauncher/instances/`

### For AppImage Installation:
- Main directory: `~/.local/share/PrismLauncher/`
- Splitscreen launcher: `~/.local/share/PrismLauncher/minecraftSplitscreen.sh`
- Instances: `~/.local/share/PrismLauncher/instances/`

## Updating
Re-run the installer anytime:
```sh
./install-minecraft-splitscreen.sh
```

The installer updates instance configs and mods for the version you select, while preserving existing instance/user data where possible.

## TODO
- Explore an optional "fast launch mode" for Steam Deck that reduces startup delays where possible while keeping the current reliable default behavior unchanged.
- Investigate cross-desktop-environment fullscreen handling (GNOME and others), potentially via an optional nested-session launch mode to avoid taskbars/panels overlapping lower splitscreen instances. Idea: evaluate a lightweight nested tiling DE/compositor approach for more consistent fullscreen splits.

## Uninstall
```sh
wget https://raw.githubusercontent.com/LukeDlbrg/MinecraftSplitscreenBazzite/main/uninstall-minecraft-splitscreen.sh
chmod +x uninstall-minecraft-splitscreen.sh
./uninstall-minecraft-splitscreen.sh
```

The uninstaller will automatically detect and remove files from both Flatpak and AppImage installations.

Optional uninstall flags:
- `--yes` - Skip confirmation prompts
- `--dry-run` - Show what would be removed without deleting anything
- `--keep-data` - Keep worlds, saves, and accounts (only remove launcher files and shortcuts)

## Troubleshooting
- Connect controllers before launching.
- If controller assignment seems wrong, close all instances and relaunch.
- Steam Deck users can optionally use [Steam-Deck.Auto-Disable-Steam-Controller](https://github.com/scawp/Steam-Deck.Auto-Disable-Steam-Controller) as a fallback for edge-case controller conflicts.
- Custom mods are best-effort and untested in this setup; incompatible or conflicting mods can break splitscreen behavior.

## Credits
- Inspired by [ArnoldSmith86/minecraft-splitscreen](https://github.com/ArnoldSmith86/minecraft-splitscreen)
- Originally created by [FlyingEwok](https://github.com/FlyingEwok) and contributors
- Optimized for Bazzite by [LukeDlbrg](https://github.com/LukeDlbrg)
- Uses [Prism Launcher](https://github.com/PrismLauncher/PrismLauncher) (supports both AppImage and Flatpak)
- Uses [install-jdk-on-steam-deck](https://github.com/FlyingEwok/install-jdk-on-steam-deck) for Java setup on Steam Deck/Linux
- Compatible with [Bazzite](https://bazzite.gg) and other handheld Linux distributions
