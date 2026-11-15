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
- [Installation](#installation)
- [Configuration notes](#configuration-notes)
- [License](#license)

## Highlights

| Area | Included |
| --- | --- |
| **Quickshell desktop** | Launcher, workspace overview, menubar, control center, wallpaper picker, notifications, media controls, clipboard history, settings, lock screen, calendar, tray, and OSD. |
| **Hyprland** | Lua-based configuration modules, window rules, gestures, animations, startup scripts, and session helpers. |
| **Media and system panels** | Lyrics view, Cava visualizer, battery status, audio controls, Bluetooth and Wi-Fi panels, and power actions. |
| **Terminal and shell** | Configurations for Kitty, Alacritty, Fish, Starship, fastfetch, and btop. |
| **Visual details** | A monochrome btop theme, Cava themes and shaders, and a consistent dark desktop palette. |

## Repository layout

```text
.
├── install.sh                  Interactive installer
└── dotfiles/
    ├── alacritty/              Alacritty configuration
    ├── btop/                   btop configuration and themes
    ├── cava/                   Cava configuration, themes, and shaders
    ├── fastfetch/              fastfetch configuration and logo
    ├── fish/                   Fish shell configuration
    ├── hypr/                   Hyprland Lua modules and helper scripts
    ├── kitty/                  Kitty configuration and theme
    ├── quickshell/macmono/     Quickshell shell and desktop features
    └── starship.toml           Starship prompt
```

## Requirements

- Linux running a Wayland session with **Hyprland**.
- **Quickshell** for the `macmono` desktop shell.
- **Bash 4 or newer** and standard command-line utilities for the installer.
- **gum** for the interactive installer menu; it is installed automatically when missing.
- Some panels and scripts call tools such as `hyprctl`, `hypridle`, `wl-paste`, `cliphist`, `grim`, `cava`, `brightnessctl`, and `nmcli`. Install the tools required by the features you plan to use.

## Installation

Clone the repository, then start the interactive installer from its root directory:

```sh
git clone https://github.com/esrahmn/monochrome.git
cd monochrome
./install.sh
```

Every component is selected by default. Toggle what you need, press Enter, and confirm the plan. Existing destinations are backed up to `~/.local/state/monochrome/backups/` (or `$XDG_STATE_HOME/monochrome/backups/`) before they are replaced, while your files in `hypr/custom/` and an existing `fish/fish_variables` are kept.

Before touching any config, the installer reads `/etc/os-release` to detect your distribution and package manager (`pacman`, `apt-get`, `dnf`, or `zypper`), checks the binaries required by the selected components, and offers to install the missing ones. It writes into `${XDG_CONFIG_HOME:-~/.config}`, rewrites the author's absolute paths in the btop, fastfetch, and fish configs, makes helper scripts executable, and never starts services. Symlinked destinations are refused. The interactive interface requires `gum`; when it is missing, the installer offers to install it first, using your package manager or the official release binary in `~/.local/bin`. Preview without writing, install everything unattended (no `gum` needed), or only report dependencies:

```sh
./install.sh --dry-run
./install.sh --yes
./install.sh --no-deps
```

After installing Quickshell and its dependencies, start the desktop shell with:

```sh
qs -c macmono
```

## Configuration notes

- The Hyprland files use Lua modules and are not a standard standalone `hyprland.conf`. Check that your setup supports this format before selecting that component.
- Review monitor scale, keyboard layout, keybinds, and application preferences before using the Hyprland configuration. Defaults may not match your hardware or workflow.
- The Fish config sources the CachyOS fish configuration when present and skips it on other distributions.
- Missing system utilities may disable only the related feature. Review the scripts before adapting them to another distribution.

## License

Distributed under the [MIT License](LICENSE).
