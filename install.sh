#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$SCRIPT_DIR/dotfiles"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

DRY_RUN=0
ASSUME_YES=0
STAGE=""
BACKUP_ROOT=""
BACKUP_COUNT=0

usage() {
  cat <<'TXT'
monochrome dotfiles installer

Usage: ./install.sh [options]

Options:
  -n, --dry-run  Show the plan without writing files.
  -y, --yes      Install all components without prompts.
  -h, --help     Show this help.

Components (all selected by default): quickshell, hypr, kitty,
alacritty, btop, cava, fish, fastfetch, starship.

Existing destinations are backed up under
$XDG_STATE_HOME/monochrome/backups (default ~/.local/state) before
being replaced. User files in hypr/custom and an existing
fish/fish_variables are preserved.
TXT
}

while (($#)); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

die() {
  printf '\nerror: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$STAGE" ]]; then
    rm -rf -- "$STAGE"
  fi
}
trap cleanup EXIT

[[ -d "$DOTFILES" ]] || die "dotfiles/ not found next to install.sh"
[[ "$CONFIG_HOME" == /* ]] || die "XDG_CONFIG_HOME must be an absolute path"
[[ "$STATE_HOME" == /* ]] || die "XDG_STATE_HOME must be an absolute path"

if [[ -t 1 && "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
else
  C_RESET=''
  C_BOLD=''
  C_DIM=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
fi

KEYS=(quickshell hypr kitty alacritty btop cava fish fastfetch starship)
declare -A LABEL=(
  [quickshell]="Quickshell desktop"
  [hypr]="Hyprland"
  [kitty]="Kitty"
  [alacritty]="Alacritty"
  [btop]="btop"
  [cava]="Cava"
  [fish]="Fish"
  [fastfetch]="fastfetch"
  [starship]="Starship"
)
declare -A SRC=(
  [quickshell]="$DOTFILES/quickshell/macmono"
  [hypr]="$DOTFILES/hypr"
  [kitty]="$DOTFILES/kitty"
  [alacritty]="$DOTFILES/alacritty"
  [btop]="$DOTFILES/btop"
  [cava]="$DOTFILES/cava"
  [fish]="$DOTFILES/fish"
  [fastfetch]="$DOTFILES/fastfetch"
  [starship]="$DOTFILES/starship.toml"
)
declare -A DST=(
  [quickshell]="$CONFIG_HOME/quickshell/macmono"
  [hypr]="$CONFIG_HOME/hypr"
  [kitty]="$CONFIG_HOME/kitty"
  [alacritty]="$CONFIG_HOME/alacritty"
  [btop]="$CONFIG_HOME/btop"
  [cava]="$CONFIG_HOME/cava"
  [fish]="$CONFIG_HOME/fish"
  [fastfetch]="$CONFIG_HOME/fastfetch"
  [starship]="$CONFIG_HOME/starship.toml"
)
declare -A REL=(
  [quickshell]="quickshell/macmono"
  [hypr]="hypr"
  [kitty]="kitty"
  [alacritty]="alacritty"
  [btop]="btop"
  [cava]="cava"
  [fish]="fish"
  [fastfetch]="fastfetch"
  [starship]="starship.toml"
)
declare -A NEEDS=(
  [quickshell]="qs hyprctl"
  [hypr]="hyprctl hypridle"
  [kitty]="kitty"
  [alacritty]="alacritty"
  [btop]="btop"
  [cava]="cava"
  [fish]="fish"
  [fastfetch]="fastfetch"
  [starship]="starship"
)
declare -A ON=()
CHOSEN=()

for key in "${KEYS[@]}"; do
  ON[$key]=1
done

short_path() {
  printf '%s' "${1/#$HOME/~}"
}

selected_count() {
  local key count=0
  for key in "${KEYS[@]}"; do
    if [[ "${ON[$key]}" == 1 ]]; then
      count=$((count + 1))
    fi
  done
  printf '%d' "$count"
}

set_all() {
  local key value=$1
  for key in "${KEYS[@]}"; do
    ON[$key]=$value
  done
}

chosen_keys() {
  local key
  for key in "${KEYS[@]}"; do
    if [[ "${ON[$key]}" == 1 ]]; then
      printf '%s\n' "$key"
    fi
  done
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

missing_tools() {
  local key tool missing=() seen=" "
  for key in "${CHOSEN[@]}"; do
    # shellcheck disable=SC2086
    for tool in ${NEEDS[$key]}; do
      if command -v "$tool" >/dev/null 2>&1; then
        continue
      fi
      if [[ "$seen" == *" $tool "* ]]; then
        continue
      fi
      seen+="$tool "
      missing+=("$tool")
    done
  done
  if ((${#missing[@]})); then
    printf '%s' "${missing[*]}"
  fi
}

font_present() {
  local families
  command -v fc-list >/dev/null 2>&1 || return 0
  families="$(fc-list : family 2>/dev/null | tr '[:upper:]' '[:lower:]')" || true
  grep -qE "$1" <<<"$families"
}

missing_fonts() {
  local missing=()
  command -v fc-list >/dev/null 2>&1 || return 0
  if [[ "${ON[quickshell]}" == 1 ]] && ! font_present '(^|,)[[:space:]]*inter([[:space:]]*,|$)'; then
    missing+=("Inter")
  fi
  if [[ "${ON[kitty]}" == 1 ]] && ! font_present 'jetbrainsmono nerd font'; then
    missing+=("JetBrainsMono Nerd Font")
  fi
  if ((${#missing[@]})); then
    printf '%s' "${missing[*]}"
  fi
}

trap 'printf "\n  %sInstallation failed.%s Partial files may remain; backup: %s\n" "$C_RED" "$C_RESET" "${BACKUP_ROOT:-none}" >&2' ERR

print_banner() {
  printf '\n'
  printf '   █   █  ███  █   █  ███   ███  █   █ ████   ███  █   █ █████\n'
  printf '   ██ ██ █   █ ██  █ █   █ █     █   █ █   █ █   █ ██ ██ █\n'
  printf '   █ █ █ █   █ █ █ █ █   █ █     █████ ████  █   █ █ █ █ ███\n'
  printf '   █   █ █   █ █  ██ █   █ █     █   █ █  █  █   █ █   █ █\n'
  printf '   █   █  ███  █   █  ███   ███  █   █ █   █  ███  █   █ █████\n'
  printf '\n   %smonochrome dotfiles installer%s\n' "$C_BOLD" "$C_RESET"
  printf '   %sconfigs → %s%s\n' "$C_DIM" "$(short_path "$CONFIG_HOME")" "$C_RESET"
  if ((DRY_RUN)); then
    printf '   %sdry run — no files will be written%s\n' "$C_YELLOW" "$C_RESET"
  fi
  printf '\n'
}

print_menu() {
  local index=0 key marker
  printf '  %sComponents%s  %s%d/%d selected%s\n\n' \
    "$C_BOLD" "$C_RESET" "$C_DIM" "$(selected_count)" "${#KEYS[@]}" "$C_RESET"
  for key in "${KEYS[@]}"; do
    index=$((index + 1))
    marker=' '
    if [[ "${ON[$key]}" == 1 ]]; then
      marker='x'
    fi
    printf '   %d  [%s]  %-20s %s%s%s\n' \
      "$index" "$marker" "${LABEL[$key]}" "$C_DIM" "$(short_path "${DST[$key]}")" "$C_RESET"
  done
  printf '\n   %s1-9%s toggle · %sa%s all · %sn%s none · %sEnter%s install · %sq%s quit\n\n' \
    "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET"
}

print_plan() {
  local key destination existing=0 missing fonts
  printf '\n  %sPlan%s\n\n' "$C_BOLD" "$C_RESET"
  for key in "${CHOSEN[@]}"; do
    destination="${DST[$key]}"
    if [[ -e "$destination" ]]; then
      existing=$((existing + 1))
    fi
    printf '   %-20s %s%s%s\n' "${LABEL[$key]}" "$C_DIM" "$(short_path "$destination")" "$C_RESET"
  done
  printf '\n'
  if ((existing)); then
    printf '   %d existing destination(s) will be backed up to %s%s%s\n' \
      "$existing" "$C_DIM" "$(short_path "$BACKUP_ROOT")" "$C_RESET"
  else
    printf '   %sNo existing configs; nothing to back up.%s\n' "$C_DIM" "$C_RESET"
  fi

  missing="$(missing_tools)"
  fonts="$(missing_fonts)"
  if [[ -n "$missing" ]]; then
    printf '   %sMissing tools:%s %s\n' "$C_YELLOW" "$C_RESET" "$missing"
  fi
  if [[ -n "$fonts" ]]; then
    printf '   %sMissing fonts:%s %s\n' "$C_YELLOW" "$C_RESET" "$fonts"
  fi
  if [[ "${ON[hypr]}" == 1 ]]; then
    printf '   %sHyprland config uses the Lua module format.%s\n' "$C_DIM" "$C_RESET"
  fi
}

confirm() {
  if ((ASSUME_YES)); then
    return 0
  fi
  local reply
  read -r -p '   Install now? [Y/n] ' reply || return 1
  case "${reply:-y}" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

retarget() {
  local file=$1 from=$2 to=$3 replacement
  [[ -f "$file" ]] || return 0
  replacement=${to//\\/\\\\}
  replacement=${replacement//&/\\&}
  replacement=${replacement//|/\\|}
  sed -i "s|$from|$replacement|g" -- "$file"
}

post_install() {
  local key=$1 destination=$2
  case "$key" in
    quickshell|hypr)
      find "$destination" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod u+x {} +
      ;;
    btop)
      retarget "$destination/btop.conf" '/home/esra/.config' "$CONFIG_HOME"
      ;;
    fastfetch)
      retarget "$destination/config.jsonc" '/home/esra/.config' "$CONFIG_HOME"
      ;;
    fish)
      retarget "$destination/fish_variables" '/home/esra' "$HOME"
      ;;
  esac
}

install_one() {
  local key=$1 src=${SRC[$1]} destination=${DST[$1]} backup

  [[ -e "$src" ]] || die "missing source: $src"

  if [[ -e "$destination" ]]; then
    backup="$BACKUP_ROOT/${REL[$key]}"
    mkdir -p -- "$(dirname -- "$backup")"
    cp -a -- "$destination" "$backup" || die "backup failed: $destination"
    BACKUP_COUNT=$((BACKUP_COUNT + 1))
  fi

  STAGE="$destination.monochrome-new.$$"
  rm -rf -- "$STAGE"
  mkdir -p -- "$(dirname -- "$destination")"

  if [[ -f "$src" ]]; then
    install -m 0644 -- "$src" "$STAGE"
  else
    mkdir -p -- "$STAGE"
    cp -a -- "$src/." "$STAGE/"
  fi

  if [[ "$key" == "hypr" && -d "$destination/custom" ]]; then
    mkdir -p -- "$STAGE/custom"
    cp -a -- "$destination/custom/." "$STAGE/custom/"
  fi
  if [[ "$key" == "fish" && -f "$destination/fish_variables" ]]; then
    cp -a -- "$destination/fish_variables" "$STAGE/fish_variables"
  fi

  rm -rf -- "$destination"
  mv -- "$STAGE" "$destination"
  STAGE=""

  post_install "$key" "$destination"
}

install_selected() {
  local key start elapsed
  mapfile -t CHOSEN < <(chosen_keys)

  if ((${#CHOSEN[@]} == 0)); then
    printf '  Nothing selected.\n\n'
    return 0
  fi

  for key in "${CHOSEN[@]}"; do
    [[ -e "${SRC[$key]}" ]] || die "missing source: ${SRC[$key]}"
    if has_symlink_in_path "${DST[$key]}"; then
      die "refusing to write through a symlink: ${DST[$key]}"
    fi
  done

  BACKUP_ROOT="$STATE_HOME/monochrome/backups/$(date '+%Y%m%d-%H%M%S')-$$"
  print_plan

  if ((DRY_RUN)); then
    printf '   %sDry run: nothing was written.%s\n\n' "$C_DIM" "$C_RESET"
    return 0
  fi

  if ! confirm; then
    printf '   Cancelled. No files were written.\n\n'
    return 0
  fi

  start=$SECONDS
  printf '\n  %sInstalling%s\n\n' "$C_BOLD" "$C_RESET"
  for key in "${CHOSEN[@]}"; do
    install_one "$key"
    printf '   %s✓%s %s\n' "$C_GREEN" "$C_RESET" "${LABEL[$key]}"
  done
  elapsed=$((SECONDS - start))

  printf '\n  %sInstalled %d component(s) in %ds%s\n' \
    "$C_GREEN" "${#CHOSEN[@]}" "$elapsed" "$C_RESET"
  printf '   configs   %s\n' "$(short_path "$CONFIG_HOME")"
  if ((BACKUP_COUNT)); then
    printf '   backup    %s\n' "$(short_path "$BACKUP_ROOT")"
    printf '   restore   cp -a %s/. %s/\n' "$(short_path "$BACKUP_ROOT")" "$(short_path "$CONFIG_HOME")"
  fi
  if [[ "${ON[quickshell]}" == 1 ]]; then
    printf '\n   Start the desktop: log in to Hyprland, then run %sqs -c macmono%s\n' "$C_BOLD" "$C_RESET"
  fi
  printf '\n'
}

print_banner

if ((ASSUME_YES)); then
  set_all 1
  install_selected
  exit 0
fi

if [[ ! -t 0 ]]; then
  die "no interactive terminal; run ./install.sh --yes to install all components"
fi

while true; do
  print_menu
  read -r -p '   Choice: ' choice || exit 1
  case "$choice" in
    '')
      if [[ "$(selected_count)" == 0 ]]; then
        printf '  %sNothing selected.%s\n\n' "$C_DIM" "$C_RESET"
        continue
      fi
      install_selected
      exit 0
      ;;
    a|A)
      set_all 1
      ;;
    n|N)
      set_all 0
      ;;
    q|Q)
      printf '  No changes made.\n\n'
      exit 0
      ;;
    [1-9])
      key="${KEYS[$((choice - 1))]}"
      if [[ "${ON[$key]}" == 1 ]]; then
        ON[$key]=0
      else
        ON[$key]=1
      fi
      ;;
    *)
      printf '  %sUse 1-9, a, n, Enter, or q.%s\n\n' "$C_DIM" "$C_RESET"
      ;;
  esac
done
