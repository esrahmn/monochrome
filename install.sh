#!/usr/bin/env bash
set -Eeuo pipefail

# Interactive installer for the monochrome dotfiles repository.
# Copies selected configurations into the user's XDG config directory.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
STATE_HOME="${XDG_STATE_HOME:-${HOME:?HOME is not set}/.local/state}"
DRY_RUN=0

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP'
monochrome interactive installer

Usage:
  bash install.sh [--dry-run]

Options:
  --dry-run   Walk through the interactive menus and show the plan without
              creating backups or copying files.
  -h, --help  Show this help.

The installer copies selected configurations into XDG_CONFIG_HOME (or
~/.config), backs up existing destinations under XDG_STATE_HOME (or
~/.local/state), and does not install system packages or run the desktop shell.
HELP
  exit 0
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ $# -gt 0 ]]; then
  printf 'Unknown option: %s\nRun "bash install.sh --help" for usage.\n' "$1" >&2
  exit 2
fi

if [[ ! -d "$SCRIPT_DIR/dotfiles" ]]; then
  printf 'Could not find the repository dotfiles/ directory. Run this script from a cloned monochrome repository.\n' >&2
  exit 1
fi

if [[ "$CONFIG_HOME" != /* || "$STATE_HOME" != /* ]]; then
  printf 'XDG_CONFIG_HOME and XDG_STATE_HOME must be absolute paths.\n' >&2
  exit 1
fi

COMPONENTS=(quickshell hyprland kitty alacritty btop cava fish)
declare -A SELECTED=(
  [quickshell]=0
  [hyprland]=0
  [kitty]=0
  [alacritty]=0
  [btop]=0
  [cava]=0
  [fish]=0
)

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_CYAN=$'\033[36m'
  C_YELLOW=$'\033[33m'
  C_GREEN=$'\033[32m'
  C_RED=$'\033[31m'
else
  C_RESET=''
  C_BOLD=''
  C_DIM=''
  C_CYAN=''
  C_YELLOW=''
  C_GREEN=''
  C_RED=''
fi

label_for() {
  case "$1" in
    quickshell) printf 'Quickshell desktop (macmono)' ;;
    hyprland)  printf 'Hyprland configuration and scripts' ;;
    kitty)     printf 'Kitty terminal' ;;
    alacritty) printf 'Alacritty terminal' ;;
    btop)      printf 'btop and themes' ;;
    cava)      printf 'Cava visualizer, themes, and shaders' ;;
    fish)      printf 'Fish shell' ;;
    *)         printf '%s' "$1" ;;
  esac
}

source_for() {
  case "$1" in
    quickshell) printf '%s' "$SCRIPT_DIR/dotfiles/quickshell/macmono" ;;
    hyprland)  printf '%s' "$SCRIPT_DIR/dotfiles/hypr" ;;
    *)         printf '%s' "$SCRIPT_DIR/dotfiles/$1" ;;
  esac
}

target_for() {
  case "$1" in
    quickshell) printf '%s' "$CONFIG_HOME/quickshell/macmono" ;;
    hyprland)  printf '%s' "$CONFIG_HOME/hypr" ;;
    *)         printf '%s' "$CONFIG_HOME/$1" ;;
  esac
}

relative_target_for() {
  case "$1" in
    quickshell) printf 'quickshell/macmono' ;;
    hyprland)  printf 'hypr' ;;
    *)         printf '%s' "$1" ;;
  esac
}

selected_count() {
  local count=0 component
  for component in "${COMPONENTS[@]}"; do
    if [[ "${SELECTED[$component]}" == 1 ]]; then
      ((count += 1))
    fi
  done
  printf '%s' "$count"
}

set_all() {
  local value="$1" component
  for component in "${COMPONENTS[@]}"; do
    SELECTED[$component]="$value"
  done
}

print_header() {
  printf '\n%s%s monochrome | interactive installer %s\n' "$C_BOLD" "$C_CYAN" "$C_RESET"
  printf '%sA careful setup for your existing desktop. Nothing is copied until you review and confirm the plan.%s\n\n' "$C_DIM" "$C_RESET"
}

print_environment() {
  printf 'Config destination: %s\n' "$CONFIG_HOME"
  if command -v qs >/dev/null 2>&1; then
    printf 'Quickshell:         detected (%s)\n' "$(command -v qs)"
  else
    printf '%sQuickshell:         not detected; the desktop shell will not start until it is installed.%s\n' "$C_YELLOW" "$C_RESET"
  fi
  if command -v hyprctl >/dev/null 2>&1; then
    printf 'Hyprland tools:     detected (%s)\n' "$(command -v hyprctl)"
  else
    printf '%sHyprland tools:     not detected; install/use this configuration only on a compatible Hyprland setup.%s\n' "$C_YELLOW" "$C_RESET"
  fi
  printf '\n'
}

print_menu() {
  local index=1 component marker
  printf '%sChoose components%s (type a number to toggle):\n' "$C_BOLD" "$C_RESET"
  for component in "${COMPONENTS[@]}"; do
    marker=' '
    [[ "${SELECTED[$component]}" == 1 ]] && marker='x'
    printf '  %s) [%s] %s\n' "$index" "$marker" "$(label_for "$component")"
    ((index += 1))
  done
  printf '\n  a) Select all       n) Select none\n'
  printf '  i) Review and install selected (%s)\n' "$(selected_count)"
  printf '  q) Quit\n\n'
}

has_symlink_in_path() {
  local path="$1"
  while [[ "$path" != "/" ]]; do
    if [[ -L "$path" ]]; then
      return 0
    fi
    path="$(dirname -- "$path")"
  done
  return 1
}

print_warnings() {
  local hyprland_selected=0 fish_selected=0 component
  for component in "${COMPONENTS[@]}"; do
    [[ "${SELECTED[$component]}" == 1 ]] || continue
    [[ "$component" == hyprland ]] && hyprland_selected=1
    [[ "$component" == fish ]] && fish_selected=1
  done

  if (( hyprland_selected )); then
    printf '%sNote:%s the Hyprland files use Lua modules and are not a standard standalone hyprland.conf. Check compatibility before enabling them.\n' "$C_YELLOW" "$C_RESET"
  fi
  if (( fish_selected )); then
    printf '%sNote:%s the Fish config sources CachyOS-specific configuration; adapt that line on other distributions.\n' "$C_YELLOW" "$C_RESET"
  fi
}

install_selected() {
  local component source destination relative backup_path collision_count=0
  local backup_root="$STATE_HOME/monochrome/backups/$(date '+%Y%m%d-%H%M%S')-$$"
  local -a chosen=()

  for component in "${COMPONENTS[@]}"; do
    [[ "${SELECTED[$component]}" == 1 ]] || continue
    chosen+=("$component")
  done

  if ((${#chosen[@]} == 0)); then
    printf '%sNo components selected. Nothing to install.%s\n' "$C_YELLOW" "$C_RESET"
    return 0
  fi

  printf '\n%sInstallation plan%s\n' "$C_BOLD" "$C_RESET"
  for component in "${chosen[@]}"; do
    source="$(source_for "$component")"
    destination="$(target_for "$component")"
    if [[ ! -d "$source" ]]; then
      printf '%sMissing source directory:%s %s\n' "$C_RED" "$C_RESET" "$source" >&2
      return 1
    fi
    if has_symlink_in_path "$destination"; then
      printf '%sRefusing to write through a symlink:%s %s\n' "$C_RED" "$C_RESET" "$destination" >&2
      printf 'Move or resolve that symlink yourself, then run the installer again. No files have been copied.\n' >&2
      return 1
    fi
    printf '  %-38s -> %s\n' "$(label_for "$component")" "$destination"
    if [[ -e "$destination" ]]; then
      ((collision_count += 1))
      printf '    Existing files will be backed up before matching files are updated.\n'
    fi
  done

  printf '\n'
  print_warnings
  if (( collision_count > 0 )); then
    printf 'Backup location: %s\n' "$backup_root"
  else
    printf 'No existing destination folders found; no backup is needed.\n'
  fi
  printf 'The installer only merges files; it does not delete unrelated files or install system packages.\n'

  if (( DRY_RUN )); then
    printf '\n%sDry run only:%s no backups or files were created.\n' "$C_CYAN" "$C_RESET"
    return 0
  fi

  printf '\n'
  read -r -p 'Proceed with this plan? [y/N] ' answer
  case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *) printf 'Cancelled. No files were copied.\n'; return 0 ;;
  esac

  for component in "${chosen[@]}"; do
    source="$(source_for "$component")"
    destination="$(target_for "$component")"
    relative="$(relative_target_for "$component")"

    if [[ -e "$destination" ]]; then
      backup_path="$backup_root/$relative"
      mkdir -p -- "$(dirname -- "$backup_path")"
      cp -a -- "$destination" "$backup_path"
      printf '%sBacked up%s %s\n' "$C_DIM" "$C_RESET" "$destination"
    fi

    mkdir -p -- "$destination"
    cp -a -- "$source/." "$destination/"
    printf '%sInstalled%s %s\n' "$C_GREEN" "$C_RESET" "$(label_for "$component")"
  done

  if (( collision_count > 0 )); then
    printf '\nBackups are saved under:\n  %s\n' "$backup_root"
    printf 'To restore a component, copy its backed-up folder back to the matching path under %s.\n' "$CONFIG_HOME"
  fi
  printf '\n%sDone.%s Start the Quickshell desktop with %sqs -c macmono%s after its files and dependencies are in place.\n' "$C_GREEN" "$C_RESET" "$C_BOLD" "$C_RESET"
}

print_header
print_environment
printf 'Select only what you want. Existing destination folders are backed up before files are merged.\n'

while true; do
  print_menu
  read -r -p 'Selection > ' choice
  case "$choice" in
    a|A) set_all 1 ;;
    n|N) set_all 0 ;;
    i|I)
      if install_selected; then
        break
      else
        exit 1
      fi
      ;;
    q|Q) printf 'No changes made.\n'; exit 0 ;;
    '' ) ;;
    *[!0-9]*) printf 'Please choose a listed number, a, n, i, or q.\n\n' ;;
    *)
      if (( choice >= 1 && choice <= ${#COMPONENTS[@]} )); then
        component="${COMPONENTS[$((choice - 1))]}"
        if [[ "${SELECTED[$component]}" == 1 ]]; then
          SELECTED[$component]=0
        else
          SELECTED[$component]=1
        fi
      else
        printf 'That number is not in the menu.\n\n'
      fi
      ;;
  esac
done
