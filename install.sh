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
  ./install.sh [--dry-run]

Options:
  --dry-run   Show the full interactive plan without creating backups or
              copying files.
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
  printf 'Unknown option: %s\nRun "./install.sh --help" for usage.\n' "$1" >&2
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

if [[ -t 1 && "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_WHITE=$'\033[97m'
  C_MUTED=$'\033[90m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
else
  C_RESET=''
  C_BOLD=''
  C_DIM=''
  C_WHITE=''
  C_MUTED=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
fi

log_info() {
  printf '%s::%s %s\n' "$C_WHITE" "$C_RESET" "$*"
}

log_success() {
  printf '%s::%s %s\n' "$C_GREEN" "$C_RESET" "$*"
}

log_warning() {
  printf '%s:: Warning:%s %s\n' "$C_YELLOW" "$C_RESET" "$*"
}

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

print_rule() {
  local width=67
  printf '%s╭' "$C_MUTED"
  for ((column = 0; column < width; column += 1)); do
    printf '─'
  done
  printf '╮%s\n' "$C_RESET"
}

print_bottom_rule() {
  local width=67
  printf '%s╰' "$C_MUTED"
  for ((column = 0; column < width; column += 1)); do
    printf '─'
  done
  printf '╯%s\n' "$C_RESET"
}

print_logo_row() {
  printf '%s│    %s%s%s    │%s\n' "$C_MUTED" "$C_BOLD$C_WHITE" "$1" "$C_RESET" "$C_RESET"
}

print_banner() {
  local row
  printf '\n'
  print_rule
  printf '%s│%67s│%s\n' "$C_MUTED" '' "$C_RESET"

  print_logo_row '█   █  ███  █   █  ███   ███  █   █ ████   ███  █   █ █████'
  print_logo_row '██ ██ █   █ ██  █ █   █ █     █   █ █   █ █   █ ██ ██ █    '
  print_logo_row '█ █ █ █   █ █ █ █ █   █ █     █████ ████  █   █ █ █ █ ███  '
  print_logo_row '█   █ █   █ █  ██ █   █ █     █   █ █  █  █   █ █   █ █    '
  print_logo_row '█   █  ███  █   █  ███   ███  █   █ █   █  ███  █   █ █████'

  printf '%s│%24s%sDOTFILES INSTALLER%25s│%s\n' "$C_MUTED" '' "$C_BOLD$C_WHITE" '' "$C_RESET"
  printf '%s│%67s│%s\n' "$C_MUTED" '' "$C_RESET"
  print_bottom_rule
  printf '%s  Calm, careful setup for your monochrome desktop.%s\n\n' "$C_DIM" "$C_RESET"
}

print_welcome() {
  log_info 'Welcome to the monochrome installer.'
  printf '  Here is what this installer will do:\n'
  printf '    1. Check a few relevant system tools.\n'
  printf '    2. Let you choose which configurations to install.\n'
  printf '    3. Back up existing destinations before merging files.\n'
  printf '\n'
  printf '  It will not install packages, delete unrelated files, or start services.\n'
  if (( DRY_RUN )); then
    log_warning 'Dry-run mode is on. No files will be copied.'
  fi
  printf '\n%s  Press Enter to continue, or Ctrl+C to quit.%s ' "$C_DIM" "$C_RESET"
  read -r _
  printf '\n'
}

print_environment() {
  log_info 'System check'
  printf '  Config destination: %s\n' "$CONFIG_HOME"
  if command -v qs >/dev/null 2>&1; then
    printf '  Quickshell:         detected at %s\n' "$(command -v qs)"
  else
    log_warning 'Quickshell (qs) was not found. Install it before starting the shell.'
  fi
  if command -v hyprctl >/dev/null 2>&1; then
    printf '  Hyprland tools:     detected at %s\n' "$(command -v hyprctl)"
  else
    log_warning 'hyprctl was not found. The Hyprland component needs a compatible setup.'
  fi
  printf '\n'
}

print_menu() {
  local index=1 component marker
  log_info "Choose components  |  $(selected_count) selected"
  printf '%s  ┌───────────────────────────────────────────────────────────────────┐%s\n' "$C_MUTED" "$C_RESET"
  for component in "${COMPONENTS[@]}"; do
    marker=' '
    [[ "${SELECTED[$component]}" == 1 ]] && marker='x'
    printf '%s  │%s %02d  [%s]  %-53s%s%s│%s\n' \
      "$C_MUTED" "$C_RESET" "$index" "$marker" "$(label_for "$component")" "$C_MUTED" "$C_RESET" "$C_MUTED"
    ((index += 1))
  done
  printf '%s  └───────────────────────────────────────────────────────────────────┘%s\n' "$C_MUTED" "$C_RESET"
  printf '  %s[number]%s toggle  ·  %sa%s all  ·  %sn%s none  ·  %si%s review  ·  %sq%s quit\n\n' \
    "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET"
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
    log_warning 'Hyprland files use Lua modules, not a standard standalone hyprland.conf. Check compatibility before enabling them.'
  fi
  if (( fish_selected )); then
    log_warning 'The Fish config sources CachyOS-specific configuration; adapt that line on other distributions.'
  fi
}

print_complete() {
  local width=67 column
  printf '\n%s╭' "$C_GREEN"
  for ((column = 0; column < width; column += 1)); do
    printf '─'
  done
  printf '╮%s\n' "$C_RESET"
  printf '%s│%67s│%s\n' "$C_GREEN" '' "$C_RESET"
  printf '%s│%23s%sINSTALLATION COMPLETE%23s│%s\n' "$C_GREEN" '' "$C_BOLD" '' "$C_RESET"
  printf '%s│%67s│%s\n' "$C_GREEN" '' "$C_RESET"
  printf '%s╰' "$C_GREEN"
  for ((column = 0; column < width; column += 1)); do
    printf '─'
  done
  printf '╯%s\n' "$C_RESET"
}

install_selected() {
  local component source destination relative backup_path collision_count=0 index=0
  local backup_root="$STATE_HOME/monochrome/backups/$(date '+%Y%m%d-%H%M%S')-$$"
  local -a chosen=()

  for component in "${COMPONENTS[@]}"; do
    [[ "${SELECTED[$component]}" == 1 ]] || continue
    chosen+=("$component")
  done

  if ((${#chosen[@]} == 0)); then
    log_warning 'No components selected. Nothing to install.'
    return 0
  fi

  printf '\n'
  log_info 'Review your installation plan'
  for component in "${chosen[@]}"; do
    source="$(source_for "$component")"
    destination="$(target_for "$component")"
    if [[ ! -d "$source" ]]; then
      printf '%s:: Error:%s missing source directory: %s\n' "$C_RED" "$C_RESET" "$source" >&2
      return 1
    fi
    if has_symlink_in_path "$destination"; then
      printf '%s:: Error:%s refusing to write through a symlink: %s\n' "$C_RED" "$C_RESET" "$destination" >&2
      printf '  Resolve that symlink yourself, then run the installer again. No files have been copied.\n' >&2
      return 1
    fi
    printf '  %-38s  %s\n' "$(label_for "$component")" "$destination"
    if [[ -e "$destination" ]]; then
      ((collision_count += 1))
      printf '    %sExisting files will be backed up before matching files are updated.%s\n' "$C_DIM" "$C_RESET"
    fi
  done

  printf '\n'
  print_warnings
  if (( collision_count > 0 )); then
    printf '  Backup folder: %s\n' "$backup_root"
  else
    printf '  No existing destinations found; no backup is needed.\n'
  fi
  printf '  Files are merged. Unrelated files are not deleted.\n'

  if (( DRY_RUN )); then
    printf '\n'
    log_info 'Dry run complete. No backups or files were created.'
    return 0
  fi

  printf '\n'
  read -r -p 'Install these components now? [y/N] ' answer
  case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *) log_info 'Cancelled. No files were copied.'; return 0 ;;
  esac

  printf '\n'
  log_info 'Installing selected components'
  for component in "${chosen[@]}"; do
    ((index += 1))
    source="$(source_for "$component")"
    destination="$(target_for "$component")"
    relative="$(relative_target_for "$component")"
    printf '\n  [%d/%d] %s\n' "$index" "${#chosen[@]}" "$(label_for "$component")"

    if [[ -e "$destination" ]]; then
      backup_path="$backup_root/$relative"
      mkdir -p -- "$(dirname -- "$backup_path")"
      cp -a -- "$destination" "$backup_path"
      printf '    Backup saved.\n'
    fi

    mkdir -p -- "$destination"
    cp -a -- "$source/." "$destination/"
    log_success 'Files merged.'
  done

  print_complete
  if (( collision_count > 0 )); then
    printf '\n  Backups: %s\n' "$backup_root"
  printf '  Restore a component by copying its backup folder back to %s.\n' "$CONFIG_HOME"
  printf '  The installer did not remove existing files.\n'
  fi
  if [[ "${SELECTED[quickshell]}" == 1 ]]; then
    printf '\n  Next step: install required tools, then run %sqs -c macmono%s.\n' "$C_BOLD" "$C_RESET"
  else
    printf '\n  Selected files are ready under %s.\n' "$CONFIG_HOME"
  fi
  printf '\n'
}

print_banner
print_welcome
print_environment
printf '%sSelect only the components you want. You can review the full plan before confirming.%s\n\n' "$C_DIM" "$C_RESET"

while true; do
  print_menu
  read -r -p '  Selection > ' choice
  case "$choice" in
    a|A) set_all 1; printf '\n  All components selected.\n\n' ;;
    n|N) set_all 0; printf '\n  Selection cleared.\n\n' ;;
    i|I)
      if install_selected; then
        break
      else
        exit 1
      fi
      ;;
    q|Q) log_info 'No changes made.'; exit 0 ;;
    1|2|3|4|5|6|7)
      component="${COMPONENTS[$((choice - 1))]}"
      if [[ "${SELECTED[$component]}" == 1 ]]; then
        SELECTED[$component]=0
      else
        SELECTED[$component]=1
      fi
      printf '\n  %s %s\n\n' "$( [[ "${SELECTED[$component]}" == 1 ]] && printf '[x]' || printf '[ ]' )" "$(label_for "$component")"
      ;;
    '') ;;
    *) printf '\n  Enter a component number, a, n, i, or q.\n\n' ;;
  esac
done
