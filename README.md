<div align="center">
  <h1>monochrome</h1>
  <p><strong>A quiet, monochrome desktop for Hyprland.</strong></p>
  <p>Linux &nbsp;·&nbsp; Wayland &nbsp;·&nbsp; Hyprland &nbsp;·&nbsp; Quickshell</p>
</div>

---

A personal dotfiles collection built around a clean Hyprland setup and a feature-rich Quickshell desktop. The focus is simple: restrained visuals, useful controls, and a consistent feel across the desktop.

> The Quickshell configuration in this repository is named `macmono` and is launched with `qs -c macmono`.

## Contents

- [Highlights](#highlights)
- [Repository layout](#repository-layout)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Configuration notes](#configuration-notes)
- [License](#license)

## Highlights

| Area | Included |
| --- | --- |
| **Quickshell desktop** | Launcher, workspace overview, menubar, control center, wallpaper picker, notifications, media controls, clipboard history, settings, lock screen, calendar, tray, and OSD. |
| **Hyprland** | Lua-based configuration modules, window rules, gestures, animations, startup scripts, and session helpers. |
| **Media and system panels** | Lyrics view, Cava visualizer, battery status, audio controls, Bluetooth and Wi-Fi panels, and power actions. |
| **Terminal and shell** | Configurations for Kitty, Alacritty, Fish, and btop. |
| **Visual details** | A monochrome btop theme, Cava themes and shaders, and a consistent dark desktop palette. |

## Repository layout

```text
dotfiles/
├── alacritty/                 Alacritty configuration
├── btop/                      btop configuration and themes
├── cava/                      Cava configuration, themes, and shaders
├── fish/                      Fish shell configuration
├── hypr/                      Hyprland Lua modules and helper scripts
├── kitty/                     Kitty configuration and theme
└── quickshell/macmono/        Quickshell shell and desktop features
```

## Requirements

- Linux running a Wayland session with **Hyprland**.
- **Quickshell** for the `macmono` desktop shell.
- Some panels and scripts call system utilities such as `hyprctl`, `hypridle`, `wl-paste`, `cliphist`, `grim`, `cava`, `brightnessctl`, and `nmcli`. Install the tools required by the features you plan to use.

This is a personal configuration, not a one-click installer. The repository does not currently include an installation script or a complete dependency manifest.

## Getting started

Clone the repository and review the configuration before copying anything into your home directory:

```sh
git clone https://github.com/esrahmn/monochrome.git
cd monochrome
```

Back up your existing configuration first, then selectively merge the directories under `dotfiles/` into their matching locations in `~/.config/`. For example, the Quickshell files under `dotfiles/quickshell/macmono/` belong at `~/.config/quickshell/macmono/`.

Once the Quickshell files are in place, start the shell with:

```sh
qs -c macmono
```

Do not blindly replace your existing `~/.config` or Hyprland setup. The Hyprland configuration here is split into Lua modules; check that your current setup supports that format before enabling it.

## Configuration notes

- Review monitor scale, keyboard layout, keybinds, and application preferences before using the Hyprland configuration. Some defaults may not match your hardware or workflow.
- `dotfiles/fish/config.fish` sources CachyOS's Fish configuration. Remove or adapt that line if you are not using CachyOS.
- Several Quickshell features depend on optional system services and command-line tools. Missing utilities may disable only the related feature, but check the scripts before adapting them to another distribution.

## License

Distributed under the [MIT License](LICENSE).
