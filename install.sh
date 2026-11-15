#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$SCRIPT_DIR/dotfiles"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

DRY_RUN=0
ASSUME_YES=0
NO_DEPS=0
GUM_BIN=""
STAGE=""
BACKUP_ROOT=""
INTERNAL_KEY=""
INTERNAL_BACKUP=""
DISTRO_NAME="Linux"
DISTRO_FAMILY=unknown
PKG_MANAGER=""
PKG_ARGS=()
SUDO=""
DEP_INSTALL_OK=0
MISSING_TOOLS=""
MISSING_FONTS=""

usage() {
  cat <<'TXT'
monochrome dotfiles installer

Usage: ./install.sh [options]

Options:
  -n, --dry-run  Show the plan without writing files.
  -y, --yes      Install all components without prompts.
      --no-deps  Report missing tools without installing packages.
  -h, --help     Show this help.

The distribution is detected from /etc/os-release. Missing tools are
installed with pacman, apt-get, dnf, or zypper when available.
The interactive menu requires gum and installs it first when missing.

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
    --no-deps) NO_DEPS=1 ;;
    --_install-component)
      shift
      [[ $# -gt 0 ]] || { printf 'missing value for --_install-component\n' >&2; exit 2; }
      INTERNAL_KEY=$1
      ;;
    --_backup-root)
      shift
      INTERNAL_BACKUP=${1:-}
      ;;
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
declare -A PKG=(
  [arch:gum]=gum
  [arch:qs]=quickshell
  [arch:hyprctl]=hyprland
  [arch:hypridle]=hypridle
  [arch:kitty]=kitty
  [arch:alacritty]=alacritty
  [arch:btop]=btop
  [arch:cava]=cava
  [arch:fish]=fish
  [arch:fastfetch]=fastfetch
  [arch:starship]=starship
  [debian:gum]=gum
  [debian:qs]=quickshell
  [debian:hyprctl]=hyprland
  [debian:hypridle]=hypridle
  [debian:kitty]=kitty
  [debian:alacritty]=alacritty
  [debian:btop]=btop
  [debian:cava]=cava
  [debian:fish]=fish
  [debian:fastfetch]=fastfetch
  [debian:starship]=starship
  [fedora:gum]=gum
  [fedora:qs]=quickshell
  [fedora:hyprctl]=hyprland
  [fedora:hypridle]=hypridle
  [fedora:kitty]=kitty
  [fedora:alacritty]=alacritty
  [fedora:btop]=btop
  [fedora:cava]=cava
  [fedora:fish]=fish
  [fedora:fastfetch]=fastfetch
  [fedora:starship]=starship
  [suse:gum]=gum
  [suse:kitty]=kitty
  [suse:alacritty]=alacritty
  [suse:btop]=btop
  [suse:cava]=cava
  [suse:fish]=fish
  [suse:fastfetch]=fastfetch
  [suse:starship]=starship
)
declare -A ON=()
CHOSEN=()

for key in "${KEYS[@]}"; do
  ON[$key]=1
done

short_path() {
  if [[ "$1" == "$HOME" ]]; then
    printf '~'
  elif [[ "$1" == "$HOME"/* ]]; then
    printf '~%s' "${1:"${#HOME}"}"
  else
    printf '%s' "$1"
  fi
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

detect_distro() {
  local id="" like=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"
    like="${ID_LIKE:-}"
    DISTRO_NAME="${PRETTY_NAME:-${NAME:-Linux}}"
  fi
  case " $id $like " in
    *" arch "*|*" archlinux "*) DISTRO_FAMILY=arch ;;
    *" debian "*|*" ubuntu "*) DISTRO_FAMILY=debian ;;
    *" fedora "*|*" rhel "*) DISTRO_FAMILY=fedora ;;
    *" suse "*|*" opensuse "*) DISTRO_FAMILY=suse ;;
    *) DISTRO_FAMILY=unknown ;;
  esac

  case "$DISTRO_FAMILY" in
    arch) PKG_MANAGER=pacman; PKG_ARGS=(-S --needed --noconfirm) ;;
    debian) PKG_MANAGER=apt-get; PKG_ARGS=(install -y) ;;
    fedora) PKG_MANAGER=dnf; PKG_ARGS=(install -y) ;;
    suse) PKG_MANAGER=zypper; PKG_ARGS=(--non-interactive install) ;;
  esac

  if [[ -n "$PKG_MANAGER" ]] && ! command -v "$PKG_MANAGER" >/dev/null 2>&1; then
    PKG_MANAGER=""
    PKG_ARGS=()
  fi
  if [[ -n "$PKG_MANAGER" ]]; then
    if ((EUID == 0)); then
      DEP_INSTALL_OK=1
    elif command -v sudo >/dev/null 2>&1; then
      SUDO=sudo
      DEP_INSTALL_OK=1
    fi
  fi
}

pkg_for_tool() {
  printf '%s' "${PKG[$DISTRO_FAMILY:$1]:-}"
}

deps_packages() {
  local tool pkg seen=" " out=()
  # shellcheck disable=SC2086
  for tool in $1; do
    pkg="$(pkg_for_tool "$tool")"
    if [[ -z "$pkg" || "$seen" == *" $pkg "* ]]; then
      continue
    fi
    seen+="$pkg "
    out+=("$pkg")
  done
  if ((${#out[@]})); then
    printf '%s' "${out[*]}"
  fi
}

deps_unmapped() {
  local tool seen=" " out=()
  # shellcheck disable=SC2086
  for tool in $1; do
    if [[ -n "$(pkg_for_tool "$tool")" || "$seen" == *" $tool "* ]]; then
      continue
    fi
    seen+="$tool "
    out+=("$tool")
  done
  if ((${#out[@]})); then
    printf '%s' "${out[*]}"
  fi
}

deps_command() {
  local -a cmd=()
  if [[ -n "$SUDO" ]]; then
    cmd+=("$SUDO")
  fi
  cmd+=("$PKG_MANAGER")
  if ((${#PKG_ARGS[@]})); then
    cmd+=("${PKG_ARGS[@]}")
  fi
  printf '%s' "${cmd[*]}"
}

install_packages() {
  local -a cmd=()
  if [[ -n "$SUDO" ]]; then
    cmd+=("$SUDO")
  fi
  cmd+=("$PKG_MANAGER")
  if ((${#PKG_ARGS[@]})); then
    cmd+=("${PKG_ARGS[@]}")
  fi
  cmd+=("$@")
  if [[ -n "${SPIN_TITLE:-}" && -n "$GUM_BIN" && -t 0 && -t 1 ]]; then
    "$GUM_BIN" spin --spinner dot --show-error \
      --spinner.foreground=255 --title.foreground=244 \
      --title "$SPIN_TITLE" -- "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

preview_deps() {
  local packages
  packages="$(deps_packages "$MISSING_TOOLS")"
  if [[ -n "$packages" && $DEP_INSTALL_OK -eq 1 ]]; then
    printf '   %sWould run:%s %s %s\n' "$C_DIM" "$C_RESET" "$(deps_command)" "$packages"
  else
    printf '   %sInstall the missing tools with your package manager.%s\n' "$C_DIM" "$C_RESET"
  fi
}

offer_deps() {
  local missing=$1 packages remaining pkg failed=0
  local -a pkg_list=()
  packages="$(deps_packages "$missing")"
  if [[ -z "$packages" || $DEP_INSTALL_OK -eq 0 ]]; then
    printf '   %sInstall the missing tools manually; no usable package mapping for this system.%s\n' "$C_DIM" "$C_RESET"
    return 0
  fi

  printf '   %sCommand:%s %s %s\n' "$C_DIM" "$C_RESET" "$(deps_command)" "$packages"
  if ! confirm 'Install packages now? [Y/n] '; then
    printf '   %sSkipped package installation.%s\n' "$C_DIM" "$C_RESET"
    return 0
  fi

  read -r -a pkg_list <<<"$packages"
  for pkg in "${pkg_list[@]}"; do
    if SPIN_TITLE="Installing $pkg" install_packages "$pkg"; then
      printf '   %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$pkg"
    else
      printf '   %s✗%s %s\n' "$C_YELLOW" "$C_RESET" "$pkg"
      failed=$((failed + 1))
    fi
  done

  remaining="$(missing_tools)"
  if [[ -n "$remaining" ]]; then
    printf '   %sStill missing:%s %s\n' "$C_YELLOW" "$C_RESET" "$remaining"
  elif ((failed == 0)); then
    printf '   %sAll dependencies are available.%s\n' "$C_GREEN" "$C_RESET"
  fi
}

gum_bootstrap_confirm() {
  local reply
  read -r -p '   Install gum now? [Y/n] ' reply || return 1
  case "${reply:-y}" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

download_gum() {
  local arch url tag tmp
  case "$(uname -m)" in
    x86_64|amd64) arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    armv7l|armv7) arch=armv7 ;;
    *)
      printf '   %sUnsupported CPU architecture for the gum binary: %s%s\n' "$C_YELLOW" "$(uname -m)" "$C_RESET"
      return 1
      ;;
  esac
  if ! command -v tar >/dev/null 2>&1; then
    printf '   %star is required to unpack the gum binary.%s\n' "$C_YELLOW" "$C_RESET"
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    printf '   %scurl or wget is required to download the gum binary.%s\n' "$C_YELLOW" "$C_RESET"
    return 1
  fi

  if command -v curl >/dev/null 2>&1; then
    url="$(curl -fsSL 'https://api.github.com/repos/charmbracelet/gum/releases/latest' 2>/dev/null \
      | grep -oE "https://github.com/charmbracelet/gum/releases/download/[^\"]*_Linux_${arch}\\.tar\\.gz" \
      | head -n1)"
    if [[ -z "$url" ]]; then
      tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' 'https://github.com/charmbracelet/gum/releases/latest' 2>/dev/null)"
      tag="${tag##*/}"
      if [[ "$tag" == v* ]]; then
        url="https://github.com/charmbracelet/gum/releases/download/$tag/gum_${tag#v}_Linux_${arch}.tar.gz"
      fi
    fi
  else
    url="$(wget -qO- 'https://api.github.com/repos/charmbracelet/gum/releases/latest' 2>/dev/null \
      | grep -oE "https://github.com/charmbracelet/gum/releases/download/[^\"]*_Linux_${arch}\\.tar\\.gz" \
      | head -n1)"
  fi

  if [[ -z "$url" ]]; then
    printf '   %sCould not resolve a gum release download.%s\n' "$C_YELLOW" "$C_RESET"
    return 1
  fi

  tmp="$(mktemp -d)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$tmp/gum.tar.gz" || { rm -rf "$tmp"; return 1; }
  else
    wget -qO "$tmp/gum.tar.gz" "$url" || { rm -rf "$tmp"; return 1; }
  fi
  tar -xzf "$tmp/gum.tar.gz" -C "$tmp" || { rm -rf "$tmp"; return 1; }
  local -a extracted=("$tmp"/gum_*/gum)
  mkdir -p -- "$HOME/.local/bin"
  install -m 0755 -- "${extracted[0]}" "$HOME/.local/bin/gum" || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
  printf '   %sInstalled gum to %s%s\n' "$C_GREEN" "$(short_path "$HOME/.local/bin/gum")" "$C_RESET"
}

ensure_gum() {
  local package
  if command -v gum >/dev/null 2>&1; then
    GUM_BIN="$(command -v gum)"
    return 0
  fi
  if [[ -x "$HOME/.local/bin/gum" ]]; then
    GUM_BIN="$HOME/.local/bin/gum"
    return 0
  fi

  printf '\n   %sgum is required for the installer interface and is not installed.%s\n' "$C_YELLOW" "$C_RESET"
  package="$(pkg_for_tool gum)"
  if [[ -n "$package" ]]; then
    printf '   %sPackage:%s %s%s\n' "$C_DIM" "$C_RESET" "$package" "${PKG_MANAGER:+ via $PKG_MANAGER}"
  fi
  if ! gum_bootstrap_confirm; then
    die "gum is required; install it manually: https://github.com/charmbracelet/gum#installation"
  fi

  if [[ -n "$package" && $DEP_INSTALL_OK -eq 1 ]]; then
    SPIN_TITLE='Installing gum' install_packages "$package" || true
  fi
  if ! command -v gum >/dev/null 2>&1; then
    download_gum || true
  fi

  if command -v gum >/dev/null 2>&1; then
    GUM_BIN="$(command -v gum)"
  elif [[ -x "$HOME/.local/bin/gum" ]]; then
    GUM_BIN="$HOME/.local/bin/gum"
  else
    die "could not install gum; install it manually: https://github.com/charmbracelet/gum#installation"
  fi
}

trap 'printf "\n  %sInstallation failed.%s Partial files may remain; backup: %s\n" "$C_RED" "$C_RESET" "${BACKUP_ROOT:-none}" >&2' ERR

print_banner() {
  local -a lines=()
  printf '\n'

  if [[ -n "$GUM_BIN" ]]; then
    lines+=("$("$GUM_BIN" style --bold --foreground 255 'M O N O C H R O M E')")
    lines+=("$("$GUM_BIN" style --foreground 244 'dotfiles installer')")
    lines+=("$("$GUM_BIN" style --foreground 238 '────────────────────────')")
    lines+=("$("$GUM_BIN" style --foreground 244 "configs   $(short_path "$CONFIG_HOME")")")
    lines+=("$("$GUM_BIN" style --foreground 244 "distro    $DISTRO_NAME ($DISTRO_FAMILY${PKG_MANAGER:+ · $PKG_MANAGER})")")
    if ((DRY_RUN)); then
      lines+=("$("$GUM_BIN" style --foreground 214 'dry run   no files will be written')")
    fi
    printf '%s\n' "${lines[@]}" | "$GUM_BIN" style --border rounded \
      --border-foreground 240 --padding '1 3' --margin '0 2' --width 56 --align center
  else
    printf '   %sM O N O C H R O M E%s\n' "$C_BOLD" "$C_RESET"
    printf '   %sdotfiles installer%s\n\n' "$C_DIM" "$C_RESET"
    printf '   %sconfigs → %s%s\n' "$C_DIM" "$(short_path "$CONFIG_HOME")" "$C_RESET"
    printf '   %sdistro  → %s (%s%s)%s\n' "$C_DIM" "$DISTRO_NAME" "$DISTRO_FAMILY" "${PKG_MANAGER:+ · $PKG_MANAGER}" "$C_RESET"
    if ((DRY_RUN)); then
      printf '   %sdry run — no files will be written%s\n' "$C_YELLOW" "$C_RESET"
    fi
  fi
  printf '\n'
}

gum_menu() {
  local key line out options=()
  for key in "${KEYS[@]}"; do
    options+=("${LABEL[$key]}  $(short_path "${DST[$key]}"):$key")
  done

  if ! out="$("$GUM_BIN" choose --no-limit --height=11 --selected='*' \
    --header='Components · x toggles · enter installs' \
    --label-delimiter=':' --cursor.foreground=252 \
    --selected.foreground=255 --header.foreground=244 \
    "${options[@]}")"; then
    printf '\n   No changes made.\n\n'
    exit 0
  fi

  if [[ -z "$out" ]]; then
    printf '   %sNothing selected.%s\n\n' "$C_DIM" "$C_RESET"
    exit 0
  fi

  set_all 0
  while IFS= read -r line; do
    if [[ -n "${LABEL[$line]+set}" ]]; then
      ON[$line]=1
    fi
  done <<<"$out"
}

print_plan() {
  local key destination action existing=0 packages unmapped rows=()
  printf '\n'
  if [[ -n "$GUM_BIN" ]]; then
    printf '  %s\n\n' "$("$GUM_BIN" style --bold --foreground 244 'Plan')"
    for key in "${CHOSEN[@]}"; do
      destination="${DST[$key]}"
      if [[ -e "$destination" ]]; then
        existing=$((existing + 1))
        action='back up + install'
      else
        action='install'
      fi
      rows+=("${LABEL[$key]}|$(short_path "$destination")|$action")
    done
    printf '%s\n' "${rows[@]}" | "$GUM_BIN" table --print --separator '|' \
      --columns 'Component,Destination,Action' --border rounded \
      --border.foreground=240 --header.foreground=255 \
      --cell.foreground=252 --padding '0 1'
  else
    printf '  %sPlan%s\n\n' "$C_BOLD" "$C_RESET"
    for key in "${CHOSEN[@]}"; do
      destination="${DST[$key]}"
      if [[ -e "$destination" ]]; then
        existing=$((existing + 1))
      fi
      printf '   %-20s %s%s%s\n' "${LABEL[$key]}" "$C_DIM" "$(short_path "$destination")" "$C_RESET"
    done
  fi
  printf '\n'
  if ((existing)); then
    printf '   %d existing destination(s) will be backed up to %s%s%s\n' \
      "$existing" "$C_DIM" "$(short_path "$BACKUP_ROOT")" "$C_RESET"
  else
    printf '   %sNo existing configs; nothing to back up.%s\n' "$C_DIM" "$C_RESET"
  fi

  MISSING_TOOLS="$(missing_tools)"
  MISSING_FONTS="$(missing_fonts)"
  if [[ -n "$MISSING_TOOLS" ]]; then
    printf '   %sMissing tools:%s %s\n' "$C_YELLOW" "$C_RESET" "$MISSING_TOOLS"
    packages="$(deps_packages "$MISSING_TOOLS")"
    unmapped="$(deps_unmapped "$MISSING_TOOLS")"
    if [[ -n "$packages" ]]; then
      printf '   %sPackages:%s %s\n' "$C_DIM" "$C_RESET" "$packages"
    fi
    if [[ -n "$unmapped" ]]; then
      printf '   %sNo package mapping:%s %s\n' "$C_DIM" "$C_RESET" "$unmapped"
    fi
  fi
  if [[ -n "$MISSING_FONTS" ]]; then
    printf '   %sMissing fonts:%s %s\n' "$C_YELLOW" "$C_RESET" "$MISSING_FONTS"
  fi
  if [[ "${ON[hypr]}" == 1 ]]; then
    printf '   %sHyprland config uses the Lua module format.%s\n' "$C_DIM" "$C_RESET"
  fi
}

confirm() {
  local prompt=${1:-'Continue? [Y/n] '}
  if ((ASSUME_YES)); then
    return 0
  fi
  prompt=${prompt% \[Y/n\] }
  "$GUM_BIN" confirm --default "$prompt" \
    --prompt.foreground=252 --selected.foreground=232 \
    --selected.background=252 --unselected.foreground=244
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
  local key start elapsed backups=0
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

  for key in "${CHOSEN[@]}"; do
    if [[ -e "${DST[$key]}" ]]; then
      backups=$((backups + 1))
    fi
  done

  BACKUP_ROOT="$STATE_HOME/monochrome/backups/$(date '+%Y%m%d-%H%M%S')-$$"
  print_plan

  if [[ -n "$MISSING_TOOLS" ]]; then
    if ((NO_DEPS)); then
      printf '   %sSkipped dependency installation (--no-deps).%s\n' "$C_DIM" "$C_RESET"
    elif ((DRY_RUN)); then
      preview_deps
    else
      offer_deps "$MISSING_TOOLS"
    fi
  fi

  if ((DRY_RUN)); then
    printf '   %sDry run: nothing was written.%s\n\n' "$C_DIM" "$C_RESET"
    return 0
  fi

  if ! confirm 'Install now? [Y/n] '; then
    printf '   Cancelled. No files were written.\n\n'
    return 0
  fi

  start=$SECONDS
  printf '\n  %sInstalling%s\n\n' "$C_BOLD" "$C_RESET"
  for key in "${CHOSEN[@]}"; do
    if [[ -n "$GUM_BIN" && -t 0 && -t 1 ]]; then
      if ! "$GUM_BIN" spin --spinner dot --show-error \
        --spinner.foreground=255 --title.foreground=244 \
        --title "Installing ${LABEL[$key]}" -- bash "$0" \
        --_install-component "$key" --_backup-root "$BACKUP_ROOT"; then
        die "failed to install ${LABEL[$key]}; backup: $BACKUP_ROOT"
      fi
    else
      install_one "$key"
    fi
    printf '   %s✓%s %s\n' "$C_GREEN" "$C_RESET" "${LABEL[$key]}"
  done
  elapsed=$((SECONDS - start))

  if [[ -n "$GUM_BIN" ]]; then
    local -a summary=()
    summary+=("$("$GUM_BIN" style --bold --foreground 255 "Installed ${#CHOSEN[@]} component(s) in ${elapsed}s")")
    summary+=("configs   $(short_path "$CONFIG_HOME")")
    if ((backups)); then
      summary+=("backup    $(short_path "$BACKUP_ROOT")")
      summary+=("restore   cp -a $(short_path "$BACKUP_ROOT")/. $(short_path "$CONFIG_HOME")/")
    fi
    if [[ "${ON[quickshell]}" == 1 ]]; then
      summary+=("start     qs -c macmono")
    fi
    printf '\n'
    printf '%s\n' "${summary[@]}" | "$GUM_BIN" style --border rounded \
      --border-foreground 240 --padding '1 2' --margin '0 2' --width 70
    printf '\n'
  else
    printf '\n  %sInstalled %d component(s) in %ds%s\n' \
      "$C_GREEN" "${#CHOSEN[@]}" "$elapsed" "$C_RESET"
    printf '   configs   %s\n' "$(short_path "$CONFIG_HOME")"
    if ((backups)); then
      printf '   backup    %s\n' "$(short_path "$BACKUP_ROOT")"
      printf '   restore   cp -a %s/. %s/\n' "$(short_path "$BACKUP_ROOT")" "$(short_path "$CONFIG_HOME")"
    fi
    if [[ "${ON[quickshell]}" == 1 ]]; then
      printf '\n   Start the desktop: log in to Hyprland, then run %sqs -c macmono%s\n' "$C_BOLD" "$C_RESET"
    fi
    printf '\n'
  fi
}

if [[ -n "$INTERNAL_KEY" ]]; then
  [[ -n "$INTERNAL_BACKUP" ]] || die "internal install requires a backup root"
  BACKUP_ROOT=$INTERNAL_BACKUP
  install_one "$INTERNAL_KEY"
  exit 0
fi

detect_distro

if ((ASSUME_YES)); then
  if command -v gum >/dev/null 2>&1; then
    GUM_BIN="$(command -v gum)"
  fi
  print_banner
  set_all 1
  install_selected
  exit 0
fi

if [[ ! -t 0 ]]; then
  die "no interactive terminal; run ./install.sh --yes to install all components"
fi

if ((DRY_RUN)) && ! command -v gum >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/gum" ]]; then
  print_banner
  printf '   %sgum is not installed; the dry-run menu is skipped and all components are used.%s\n' "$C_DIM" "$C_RESET"
  set_all 1
  install_selected
  exit 0
fi

ensure_gum
print_banner
gum_menu
install_selected
exit 0
