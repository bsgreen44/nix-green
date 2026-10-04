#!/usr/bin/env bash
# Install or rebuild nix-green on whatever machine this runs on: detect NixOS,
# macOS or another Linux distro, write this machine's username, hostname
# (NixOS and macOS only) and the Mac's CPU architecture into flake.nix,
# install Nix if it is missing, and run the matching switch command.
#
# Usage: ./scripts/install.sh [kde|hyprland|cli] [--dry-run]
#   kde, hyprland  NixOS desktops
#   hyprland, cli  other Linux distros (Home Manager, with or without Hyprland)
#   (none)         macOS, or pick from a menu on Linux
#   --dry-run      show the flake.nix changes and the command, change nothing
#
# Runs on macOS's stock bash 3.2, so no associative arrays or ${x,,}.
set -euo pipefail

DETERMINATE_URL="https://install.determinate.systems/nix"
NIX_DAEMON_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
# Added on top of the user's nix.conf, so a stock NixOS install can evaluate
# the flake before configuration.nix has turned flakes on.
NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG
}extra-experimental-features = nix-command flakes"
export NIX_CONFIG

DRY_RUN=false

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() { sed -n '7,11s/^# \{0,1\}//p' "$0"; }

detect_platform() {
  if [ "$(uname -s)" = Darwin ]; then
    printf 'darwin\n'
  elif [ -e /etc/NIXOS ]; then
    printf 'nixos\n'
  else
    printf 'linux\n'
  fi
}

detect_hostname() {
  if [ "$1" = darwin ]; then
    scutil --get LocalHostName
  else
    cat /proc/sys/kernel/hostname
  fi
}

detect_darwin_system() {
  case "$(uname -m)" in
    arm64) printf 'aarch64-darwin\n' ;;
    x86_64) printf 'x86_64-darwin\n' ;;
    *) die "unsupported Mac architecture: $(uname -m)" ;;
  esac
}

# Rewrite the value of the single `<key> = "<value>";` line in flake.nix whose
# value matches <value_re>, keeping the rest of the line (comments) intact.
# value_re must not contain groups, so the suffix stays capture group 3.
set_flake_value() {
  local key=$1 new=$2 value_re=$3
  local pattern="^([[:space:]]*${key} = \")(${value_re})(\";.*)\$"
  local count old tmp

  count=$(grep -cE "$pattern" flake.nix || true)
  [ "$count" = 1 ] ||
    die "expected exactly one '${key} = \"...\";' line in flake.nix, found ${count}"

  old=$(sed -nE "s/${pattern}/\\2/p" flake.nix)
  if [ "$old" = "$new" ]; then
    printf '  %-9s %s (unchanged)\n' "$key" "$new"
    return
  fi
  printf '  %-9s %s -> %s\n' "$key" "$old" "$new"
  $DRY_RUN && return

  # sed -i differs between GNU and BSD. Writing back through cat keeps
  # flake.nix's permissions, which mv of a mktemp file would not.
  tmp=$(mktemp "${TMPDIR:-/tmp}/flake.nix.XXXXXX")
  sed -E "s/${pattern}/\\1${new}\\3/" flake.nix >"$tmp"
  cat "$tmp" >flake.nix
  rm -f "$tmp"
}

ensure_nix() {
  command -v nix >/dev/null 2>&1 && return
  if $DRY_RUN; then
    printf 'Nix is not installed; would offer to install it from %s\n' "$DETERMINATE_URL"
    return
  fi

  local answer
  read -r -p "Nix is not installed. Install it with the Determinate Nix Installer? [y/N] " answer
  case "$answer" in
    [yY] | [yY][eE][sS]) ;;
    *) die "Nix is required. See the README for install instructions." ;;
  esac

  curl --proto '=https' --tlsv1.2 -sSf -L "$DETERMINATE_URL" | sh -s -- install
  # The installer only wires Nix into new shells; load it into this one.
  # shellcheck source=/dev/null
  . "$NIX_DAEMON_PROFILE"
  command -v nix >/dev/null 2>&1 || die "Nix installed, but 'nix' is still not on PATH. Open a new terminal and rerun."
}

# Print the chosen target: validate the argument if one was given, otherwise
# ask with a menu.
pick_target() {
  local platform=$1 target=$2 choices choice
  case "$platform" in
    darwin)
      [ -z "$target" ] || die "macOS has a single configuration; run without '$target'."
      printf 'nix-darwin\n'
      return
      ;;
    nixos) choices="kde hyprland" ;;
    linux) choices="cli hyprland" ;;
  esac

  if [ -n "$target" ]; then
    case " $choices " in
      *" $target "*) printf '%s\n' "$target"; return ;;
      *) die "'$target' is not a configuration for $platform. Choose one of: $choices" ;;
    esac
  fi

  printf 'Which configuration?\n' >&2
  # shellcheck disable=SC2086 # word splitting of $choices is the point
  select choice in $choices; do
    [ -n "$choice" ] && { printf '%s\n' "$choice"; return; }
  done
  die "no configuration chosen"
}

run() {
  printf '+ %s\n' "$*"
  $DRY_RUN || "$@"
}

main() {
  local target="" arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=true ;;
      -h | --help) usage; exit 0 ;;
      -*) die "unknown option '$arg'. Run with --help for usage." ;;
      *)
        [ -z "$target" ] || die "only one configuration can be given"
        target=$arg
        ;;
    esac
  done

  [ "$(id -u)" != 0 ] || die "run this as your own user, not root; it calls sudo when needed."
  cd "$(dirname "$0")/.."

  local platform username hostname=""
  platform=$(detect_platform)
  username=$(id -un)
  # Only the NixOS and nix-darwin system configs set the hostname. Standalone
  # Home Manager never reads it, so leave flake.nix alone on other distros.
  if [ "$platform" = linux ]; then
    printf 'Detected %s, user %s\n' "$platform" "$username"
  else
    hostname=$(detect_hostname "$platform")
    printf 'Detected %s, user %s, host %s\n' "$platform" "$username" "$hostname"
  fi

  # These land inside Nix strings and a sed replacement.
  local name
  for name in "$username" ${hostname:+"$hostname"}; do
    printf '%s' "$name" | grep -qE '^[A-Za-z0-9._-]+$' ||
      die "'$name' contains characters this script will not write into flake.nix"
  done

  target=$(pick_target "$platform" "$target")
  if [ "$platform" = nixos ] && [ ! -e /etc/nixos/hardware-configuration.nix ]; then
    die "/etc/nixos/hardware-configuration.nix is missing. Generate it with: sudo nixos-generate-config"
  fi

  printf 'flake.nix:\n'
  [ -z "$hostname" ] || set_flake_value hostname "$hostname" '[^"]*'
  set_flake_value username "$username" '[^"]*'
  if [ "$platform" = darwin ]; then
    set_flake_value system "$(detect_darwin_system)" '[a-z0-9_]+-darwin'
  fi

  case "$platform" in
    nixos)
      run sudo --preserve-env=NIX_CONFIG nixos-rebuild switch --flake ".#$target" --impure
      ;;
    darwin)
      ensure_nix
      if command -v darwin-rebuild >/dev/null 2>&1; then
        run sudo --preserve-env=NIX_CONFIG darwin-rebuild switch --flake ".#$target"
      else
        run sudo --preserve-env=NIX_CONFIG nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#$target"
      fi
      ;;
    linux)
      ensure_nix
      local hm_target=$username
      [ "$target" = hyprland ] && hm_target="$username-hyprland"
      if command -v home-manager >/dev/null 2>&1; then
        run home-manager switch --flake ".#$hm_target"
      else
        run nix run home-manager/master -- switch --flake ".#$hm_target"
      fi
      ;;
  esac
}

# Only run when executed, so the functions can be sourced for testing.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
