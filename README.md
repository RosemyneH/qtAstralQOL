<div align="center">

# qtAstralQOL

**Astral gem overlays for Project Astral — event colors, disenchant toasts, character dock, inspect, deposit all.**

<br/>

[![WoW](https://img.shields.io/badge/WoW-3.3.5a-6f42c1?style=flat-square)](#)
[![For](https://img.shields.io/badge/for-Project%20Astral-1784d1?style=flat-square)](#)
[![Requires](https://img.shields.io/badge/requires-ProjectAstral-2ea44f?style=flat-square)](#)
[![License](https://img.shields.io/badge/license-GPL--2.0-blue?style=flat-square)](LICENSE)
[![Release](https://img.shields.io/github/v/release/RosemyneH/qtAstralQOL?style=flat-square&label=release)](https://github.com/RosemyneH/qtAstralQOL/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/RosemyneH/qtAstralQOL/total?style=flat-square)](https://github.com/RosemyneH/qtAstralQOL/releases)

<br/>

[**Latest Release**](https://github.com/RosemyneH/qtAstralQOL/releases/latest)
&nbsp;·&nbsp;
[**Changelog**](CHANGELOG.md)
&nbsp;·&nbsp;
[**Issues**](https://github.com/RosemyneH/qtAstralQOL/issues)

</div>

---

<div align="center">

## Features

| | |
| :---: | :--- |
| **Event color pips** | Socket overlays tinted by melee, cast, heal, struck, crit, DoT, or any. |
| **Spell gem icons** | Replaces generic gem art with the matching spell icon when it can be resolved. |
| **Smarter picker** | Search, event, and tier filters; hides families already socketed. |
| **Disenchant toasts** | New-family gem toasts stack beside the Astral table. |
| **Character dock** | Loadout panel docked to the character frame. |
| **Inspect gems** | Loadout panel on inspect. |
| **Deposit All** | Extra button on the Astral table to stash every gem and scroll. |
| **Fusion hints** | Tooltip stash counts toward the next fusion. |

</div>

---

<div align="center">

## Install

</div>

1. Download the zip from the [latest release](https://github.com/RosemyneH/qtAstralQOL/releases/latest).
2. Extract the `qtAstralQOL` folder into `Interface\AddOns` on your **Project Astral** client.
3. Enable **ProjectAstral** and **qtAstralQOL** on the AddOns screen, then `/reload`.

Keep the folder name as it is. The `.toc` must sit at:

```text
Interface\AddOns\qtAstralQOL\qtAstralQOL.toc
```

---

<div align="center">

## Dev symlink

</div>

The working copy lives in this repo. The live client loads a directory junction:

| | |
| :---: | :--- |
| **Repo** | `C:\Users\Qt\Documents\Repos\qtAstralQOL\qtAstralQOL` |
| **Client** | `C:\astralvibes\Interface\AddOns\qtAstralQOL` |

Recreate it from an elevated PowerShell:

```powershell
New-Item -ItemType Junction -Force `
  -Path "C:\astralvibes\Interface\AddOns\qtAstralQOL" `
  -Target "C:\Users\Qt\Documents\Repos\qtAstralQOL\qtAstralQOL"
```

Edit here, `/reload` in-game. No copy step.

---

<div align="center">

## Commands

| Command | Action |
| :---: | :--- |
| `/qgems` or `/qolgems` | Open the Astral gems tab |
| `/qgems deposit` | Deposit all gems and scrolls to stash |
| `/qgems notify` | Toggle disenchant toasts |
| `/qgems dock` | Toggle the character-frame gem dock |
| `/astral gem` | Same as `/qgems` |

</div>

---

<div align="center">

## Releases

</div>

Every merge to `main` is scanned for [Conventional Commits](https://www.conventionalcommits.org/). When there are releasable changes, [release-please](https://github.com/googleapis/release-please) opens a release pull request with an updated changelog and TOC version. Merging that PR tags a GitHub Release and attaches an AddOns zip.

Versions are two-part: **1.1**, **1.2**, … **1.20**, then **2.0**. Each releasable merge bumps the second number. There is no `1.1.1` patch line.

| Prefix | Version bump | Example |
| :---: | :---: | :--- |
| `feat:` or `fix:` | 1.n → 1.n+1 | `feat: add inspect gem dock` |
| `docs:`, `chore:`, `ci:` | no release | `docs: clarify install path` |

After **1.20**, jump to **2.0** by including this footer on the commit:

```text
Release-As: 2.0
```

---

<div align="center">

## License

Released under the [GNU General Public License v2.0](LICENSE).

Requires **ProjectAstral**. Built for **Project Astral** on World of Warcraft 3.3.5a (`Interface: 30300`).

</div>
