#!/bin/bash
# uninstall-nix.sh - remove nix-green (github.com/bsgreen44/nix-green) and Nix
# from macOS or a non-NixOS Linux distro, and return the machine to a clean,
# default state for this user.
#
# macOS removes: Homebrew casks, Nix-installed apps (Brave, Obsidian, LibreOffice,
# Signal, LocalSend, VLC, VSCodium), nix-darwin, Home Manager, Determinate/
# official Nix, the Nix Store volume, Tailscale daemon, SketchyBar, AeroSpace,
# Nix fonts, and the macOS settings nix-darwin changed.
# Linux removes: Nix-installed apps, Home Manager dotfiles and user services,
# Determinate/official Nix (/nix, nix-daemon, nixbld users), and the swayosd
# udev rule from the README. Packages from the distro's package manager stay.
# Optionally: app data, Homebrew itself (macOS), and ~/nix-green.
#
# NixOS is not supported: there Nix is the operating system.
# Safe to re-run if a previous run was interrupted.
# Usage: /bin/bash uninstall-nix.sh   (as your normal user; it asks for sudo)

# Always run under the system's own bash so nothing breaks when /nix disappears.
if [[ "${BASH:-}" != "/bin/bash" ]]; then exec /bin/bash "$0" "$@"; fi
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
set -o pipefail

info() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '    \033[1;33m!\033[0m %s\n' "$*"; }
ask()  { local a; read -r -p "$1 " a; a="${a:-$2}"; [[ "$a" =~ ^[Yy] ]]; }

# Remove paths under $HOME given as relative patterns (globs allowed, spaces OK).
rm_home() {
  local IFS=$'\n' p f
  for p in "$@"; do
    for f in $HOME/$p; do
      if [[ -e "$f" || -L "$f" ]]; then rm -rf "$f" && ok "Removed ~/${f#"$HOME"/}"; fi
    done
  done
}

# Label of a launchd plist (falls back to the file name for dangling links).
plist_label() {
  local l
  l=$(/usr/libexec/PlistBuddy -c 'Print :Label' "$1" 2>/dev/null) || l=""
  [[ -n "$l" ]] || l=$(basename "$1" .plist)
  printf '%s' "$l"
}

# A plist belongs to Nix if it is a link into /nix, mentions /nix, or has a Nix label.
is_nix_plist() {
  local f="$1" name; name=$(basename "$f")
  [[ -L "$f" && "$(readlink "$f")" == /nix/* ]] && return 0
  [[ "$name" == org.nixos.* || "$name" == org.nix-community.* || "$name" == systems.determinate.* ]] && return 0
  [[ -f "$f" ]] && grep -qa '/nix/' "$f" 2>/dev/null && return 0
  return 1
}

if [[ "$(uname)" == "Darwin" ]]; then
  OS=darwin
elif [[ -e /etc/NIXOS ]]; then
  echo "This is NixOS, where Nix is the operating system and cannot be uninstalled."
  echo "Switch to another configuration, or install a different distro instead."
  exit 1
elif [[ "$(uname)" == "Linux" ]]; then
  OS=linux
else
  echo "This script supports macOS and Linux only."; exit 1
fi
[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (the script uses sudo itself)."; exit 1; }

# In-place sed; BSD sed needs an explicit empty backup suffix, GNU sed rejects it.
# An array rather than a function so it also works after sudo.
SEDI=(sed -i); [[ $OS == darwin ]] && SEDI=(sed -i '')

BREW=""
if [[ $OS == darwin ]]; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [[ -x "$b" ]] && { BREW="$b"; break; }; done
fi

# Folders in $HOME that hold the user's own files; never searched or touched.
PRUNE=(Desktop Documents Downloads Pictures Music Nextcloud)
if [[ $OS == darwin ]]; then PRUNE+=(Library .Trash Movies); else PRUNE+=(Videos .local/share/Trash); fi
prune_args=()
for d in "${PRUNE[@]}"; do prune_args+=(-o -path "$HOME/$d"); done
prune_args=("${prune_args[@]:1}")

# ------------------------------------------------------------------ questions
if [[ $OS == darwin ]]; then
  cat <<'EOF'
This removes nix-green and Nix from this Mac:
  • every Homebrew cask (Ghostty, Nextcloud, Zen, Raycast, ProtonVPN, and any others)
  • Nix apps: Brave, Obsidian, LibreOffice, Signal, LocalSend, VLC, VSCodium
  • nix-darwin, Home Manager, Nix itself and the Nix Store volume
  • Tailscale daemon, SketchyBar, AeroSpace, Nix fonts, Home Manager dotfiles
Your Documents, Desktop, Downloads, Photos and iCloud are not touched.
EOF
else
  cat <<'EOF'
This removes nix-green and Nix from this computer:
  • Nix apps: Brave, Zen, Obsidian, Nextcloud client, Signal, LocalSend, VLC,
    Proton VPN, VSCodium, and every other Home Manager package
  • Home Manager dotfiles and user services (waybar, mako, swayosd, hypridle, ...)
  • Nix itself: /nix, the nix-daemon service and the nixbld users
  • the swayosd brightness udev rule, if you added it
Programs from your distro's package manager (Hyprland, hyprlock, ...) stay.
Your Documents, Desktop, Downloads, Pictures and ~/Nextcloud folder are not touched.
EOF
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo
    warn "You are in the Hyprland session. Its bar, launcher and config come from Nix"
    warn "and go away; log out and pick another session (or a TTY) afterwards."
  fi
fi
ask "Continue? [y/N]" n || { echo "Aborted."; exit 0; }

echo
echo "A few choices up front, then everything runs without further questions:"
echo
q=1
echo "$q) App data: browser profiles, Signal messages, Obsidian/VSCodium settings,"
echo "   Claude Code/Codex/opencode logins and history, Neovim plugins, calcurse,"
echo "   shell history, and the configs nix-green wrote. (Obsidian vaults and the"
echo "   ~/Nextcloud sync folder are NOT deleted.)"
ask "   Delete this app data? [y/N]" n && DEL_DATA=1 || DEL_DATA=0
echo
RESET_DEFAULTS=0
REMOVE_BREW=0
if [[ $OS == darwin ]]; then
  q=$((q + 1))
  echo "$q) Reset macOS settings nix-green changed back to defaults: light mode,"
  echo "   default accent colour, visible menu bar, file extensions hidden,"
  echo "   default Dock layout (removes your Dock icons), automatic time zone."
  ask "   Reset these settings? [Y/n]" y && RESET_DEFAULTS=1
  echo
  if [[ -n "$BREW" ]]; then
    q=$((q + 1))
    echo "$q) Homebrew itself and every command-line tool installed with it."
    ask "   Remove Homebrew completely? [y/N]" n && REMOVE_BREW=1
    echo
  fi
fi
DEL_REPO=0
if [[ -d "$HOME/nix-green" ]]; then
  q=$((q + 1))
  echo "$q) The ~/nix-green repo folder (it's still on GitHub)."
  ask "   Delete ~/nix-green? [y/N]" n && DEL_REPO=1
  echo
fi

sudo -v || exit 1
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

BACKUP="$HOME/nix-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
shopt -s nullglob

# ------------------------------------------------------------- user services
if [[ $OS == darwin ]]; then
  info "Stopping SketchyBar, AeroSpace and other Home Manager login agents"
  for f in "$HOME"/Library/LaunchAgents/*.plist; do
    if is_nix_plist "$f"; then
      label=$(plist_label "$f")
      launchctl bootout "gui/$UID/$label" 2>/dev/null
      rm -f "$f" && ok "Removed agent $label"
    fi
  done
  pkill -x sketchybar 2>/dev/null
  pkill -x AeroSpace 2>/dev/null
  osascript -e 'quit app "AeroSpace"' >/dev/null 2>&1
else
  info "Stopping Home Manager user services"
  units_dir="$HOME/.config/systemd/user"
  links=()
  if [[ -d "$units_dir" ]]; then
    while IFS= read -r l; do links+=("$l"); done \
      < <(find "$units_dir" -maxdepth 2 -type l -lname '/nix/*' 2>/dev/null)
  fi
  if [[ ${#links[@]} -eq 0 ]]; then
    ok "None found"
  else
    # Files inside a unit's drop-in folder (foo.service.d/) are not units.
    units=$(for l in "${links[@]}"; do [[ "$(dirname "$l")" == *.d ]] || basename "$l"; done | sort -u)
    for u in $units; do
      systemctl --user disable --now "$u" >/dev/null 2>&1
    done
    for l in "${links[@]}"; do rm -f "$l"; done
    for u in $units; do ok "Removed $u"; done
    find "$units_dir" -depth -type d -empty -delete 2>/dev/null
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user reset-failed 2>/dev/null
  fi
fi

# ---------------------------------------------------------------- casks
if [[ $OS == darwin ]]; then
  if [[ -n "$BREW" ]]; then
    info "Removing Homebrew casks"
    casks=$(HOMEBREW_NO_AUTO_UPDATE=1 "$BREW" list --cask 2>/dev/null)
    if [[ -z "$casks" ]]; then
      ok "No casks installed"
    else
      for c in $casks; do
        if HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 PATH="$(dirname "$BREW"):$PATH" \
             "$BREW" uninstall --cask --zap --force "$c" >/dev/null 2>&1; then
          ok "Removed $c"
        else
          warn "Could not fully remove $c (try: brew uninstall --cask --zap --force $c)"
        fi
      done
    fi
  else
    info "Homebrew not found; skipping casks"
  fi

  info "Removing apps installed by Nix"
  for d in "/Applications/Nix Apps" "/Applications/Nix Trampolines"; do
    [[ -e "$d" ]] && sudo rm -rf "$d" && ok "Removed $d"
  done
  rm_home "Applications/Home Manager Apps" "Applications/Home Manager Trampolines"
fi

# ---------------------------------------------------------------- app data
if [[ $DEL_DATA -eq 1 ]]; then
  info "Deleting app data"
  rm_home \
    ".claude" ".claude.json*" ".codex" ".agents" \
    ".config/opencode" ".local/share/opencode" ".local/state/opencode" ".cache/opencode" \
    ".config/nvim" ".local/share/nvim" ".local/state/nvim" ".cache/nvim" \
    ".config/herdr" ".config/calcurse" ".local/share/calcurse" ".calcurse" \
    ".config/btop" ".config/bat" ".cache/bat" ".config/kitty" ".config/ghostty" \
    ".config/starship.toml" ".cache/starship" ".config/clock-rs" \
    ".config/fastfetch" ".luarocks" \
    ".zsh_history" ".zsh_sessions" ".zcompdump*" ".local/state/nix-green"
  if [[ $OS == darwin ]]; then
    rm_home \
      "Library/Application Support/BraveSoftware" "Library/Caches/BraveSoftware" \
      "Library/Preferences/com.brave.Browser*.plist" "Library/Saved Application State/com.brave.Browser*" \
      "Library/Application Support/obsidian" "Library/Preferences/md.obsidian.plist" \
      "Library/Saved Application State/md.obsidian.savedState" \
      "Library/Application Support/LibreOffice" "Library/Preferences/org.libreoffice.script.plist" \
      "Library/Saved Application State/org.libreoffice.script.savedState" \
      "Library/Application Support/Signal" "Library/Preferences/org.whispersystems.signal-desktop.plist" \
      "Library/Saved Application State/org.whispersystems.signal-desktop.savedState" \
      "Library/Caches/org.whispersystems.signal-desktop*" \
      "Library/Application Support/org.localsend.localsendApp" "Library/Containers/org.localsend.localsendApp" \
      "Library/Preferences/org.localsend.localsendApp.plist" \
      "Library/Preferences/org.videolan.vlc" "Library/Preferences/org.videolan.vlc.plist" \
      "Library/Application Support/org.videolan.vlc" "Library/Caches/org.videolan.vlc" \
      "Library/Saved Application State/org.videolan.vlc.savedState" \
      "Library/Application Support/VSCodium" ".vscode-oss" "Library/Preferences/com.vscodium.plist" \
      "Library/Saved Application State/com.vscodium.savedState" "Library/Caches/com.vscodium*" \
      "Library/Application Support/lazygit" \
      ".config/sketchybar" ".config/aerospace" ".aerospace.toml"
  else
    rm_home \
      ".config/BraveSoftware" ".cache/BraveSoftware" \
      ".config/zen" ".zen" ".cache/zen" \
      ".config/obsidian" ".config/Signal" \
      ".local/share/org.localsend.localsend_app" \
      ".config/vlc" ".local/share/vlc" \
      ".config/VSCodium" ".vscode-oss" \
      ".config/Nextcloud" ".config/Proton" ".cache/Proton" \
      ".config/lazygit" ".config/yazi" \
      ".config/hypr" ".config/waybar" ".config/rofi" ".config/mako" ".config/swayosd" \
      ".local/share/hyprland"
  fi
fi

# ------------------------------------------------------------- Nix itself
if [[ -x /nix/nix-installer ]]; then
  info "Running the Determinate Nix uninstaller"
  sudo /nix/nix-installer uninstall --no-confirm \
    || warn "Determinate uninstaller reported an error; continuing with manual cleanup"
fi

if [[ $OS == darwin ]]; then
  if command -v darwin-uninstaller >/dev/null 2>&1 && [[ -d /nix/store ]]; then
    info "Running the nix-darwin uninstaller"
    sudo "$(command -v darwin-uninstaller)" || warn "nix-darwin uninstaller failed; continuing"
  fi

  info "Stopping Nix system services (nix-daemon, Tailscale, nix-darwin)"
  for f in /Library/LaunchDaemons/*.plist; do
    if is_nix_plist "$f"; then
      label=$(plist_label "$f")
      sudo launchctl bootout "system/$label" 2>/dev/null
      sudo rm -f "$f" && ok "Removed daemon $label"
    fi
  done
  if [[ ! -d /Applications/Tailscale.app ]]; then
    for d in /Library/Tailscale /var/lib/tailscale; do
      [[ -e "$d" ]] && sudo rm -rf "$d" && ok "Removed Tailscale state $d"
    done
  fi
  [[ -e /usr/local/bin/determinate-nixd ]] && sudo rm -f /usr/local/bin/determinate-nixd && ok "Removed determinate-nixd"
else
  info "Stopping Nix system services (nix-daemon)"
  sys_units=()
  while IFS= read -r f; do sys_units+=("$f"); done < <(find /etc/systemd/system -maxdepth 2 \
    \( -name 'nix-daemon.*' -o -name 'nix-directory.service' -o -name 'nix.mount' \
       -o -name 'ensure-symlinked-units-resolve.service' -o -lname '/nix/*' \) 2>/dev/null)
  if [[ ${#sys_units[@]} -eq 0 ]]; then
    ok "None found"
  else
    for u in $(for f in "${sys_units[@]}"; do basename "$f"; done | sort -u); do
      sudo systemctl disable --now "$u" >/dev/null 2>&1
      ok "Stopped $u"
    done
    for f in "${sys_units[@]}"; do sudo rm -f "$f"; done
    sudo systemctl daemon-reload
  fi
  [[ -e /etc/tmpfiles.d/nix-daemon.conf ]] && sudo rm -f /etc/tmpfiles.d/nix-daemon.conf && ok "Removed /etc/tmpfiles.d/nix-daemon.conf"
  if command -v semodule >/dev/null 2>&1 && sudo semodule -l 2>/dev/null | grep -qx 'nix'; then
    sudo semodule -r nix >/dev/null 2>&1 && ok "Removed SELinux policy module nix"
  fi

  info "Removing the swayosd brightness udev rule"
  if [[ -e /etc/udev/rules.d/99-swayosd.rules ]]; then
    sudo rm -f /etc/udev/rules.d/99-swayosd.rules && ok "Removed /etc/udev/rules.d/99-swayosd.rules"
    sudo udevadm control --reload 2>/dev/null
    id -nG | grep -qw video && warn "You are still in the video group (harmless; remove with: sudo gpasswd -d $USER video)"
  else
    ok "Not present"
  fi
fi

info "Restoring /etc files changed by Nix"
if [[ $OS == darwin ]]; then
  while IFS= read -r b; do
    orig="${b%.before-nix-darwin}"
    sudo rm -f "$orig"; sudo mv "$b" "$orig" && ok "Restored $orig"
  done < <(find /private/etc -maxdepth 3 -name '*.before-nix-darwin' 2>/dev/null)
fi
rc_files=(/etc/zshrc /etc/zprofile /etc/zshenv /etc/zsh/zshrc /etc/zsh/zshenv /etc/bashrc /etc/bash.bashrc /etc/profile)
for f in "${rc_files[@]}"; do
  if [[ -f "$f.backup-before-nix" ]]; then
    sudo rm -f "$f"; sudo mv "$f.backup-before-nix" "$f" && ok "Restored $f"
  fi
done
for f in "${rc_files[@]}"; do
  if [[ -f "$f" && ! -L "$f" ]] && grep -q '^# Nix$' "$f"; then
    sudo cp "$f" "$BACKUP/$(echo "${f#/etc/}" | tr / _)"
    sudo "${SEDI[@]}" '/^# Nix$/,/^# End Nix$/d' "$f" && ok "Removed Nix block from $f"
  fi
done
for f in /etc/profile.d/nix.sh /etc/profile.d/nix-daemon.sh /etc/fish/conf.d/nix.fish /etc/fish/conf.d/nix-daemon.fish; do
  [[ -e "$f" || -L "$f" ]] && sudo rm -f "$f" && ok "Removed $f"
done
ETC=/etc; [[ $OS == darwin ]] && ETC=/private/etc
while IFS= read -r l; do
  sudo rm -f "$l" && ok "Removed dangling link $l"
done < <(sudo find "$ETC" -maxdepth 4 -type l \( -lname '/etc/static/*' -o -lname '/nix/*' \) 2>/dev/null)
if [[ $OS == darwin ]]; then
  [[ -L /etc/static || -e /etc/static ]] && sudo rm -rf /etc/static && ok "Removed /etc/static"
  sudo rm -f /etc/ssh/sshd_config.d/100-nix-darwin.conf
  [[ -f /etc/zshrc ]] || warn "/etc/zshrc is missing; zsh still works, it just lacks Apple's default tweaks"
fi

info "Checking your login shell"
if [[ $OS == darwin ]]; then
  login_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
else
  login_shell=$(getent passwd "$USER" | cut -d: -f7)
fi
case "$login_shell" in
  /nix/*|/run/*|/etc/profiles/*|"$HOME"/.nix-profile/*)
    if [[ $OS == darwin ]]; then
      sudo chsh -s /bin/zsh "$USER" >/dev/null && ok "Login shell changed to /bin/zsh"
    else
      new_shell=/bin/bash; [[ -x /bin/zsh ]] && new_shell=/bin/zsh
      sudo usermod -s "$new_shell" "$USER" && ok "Login shell changed to $new_shell"
    fi ;;
  *) ok "Login shell is $login_shell" ;;
esac
if grep -qE '^(/nix/|/run/|/etc/profiles/)' /etc/shells 2>/dev/null; then
  sudo "${SEDI[@]}" -E '/^(\/nix\/|\/run\/|\/etc\/profiles\/)/d' /etc/shells && ok "Cleaned /etc/shells"
fi

info "Removing nixbld users and group"
if [[ $OS == darwin ]]; then
  for u in $(dscl . -list /Users | grep '^_nixbld'); do
    sudo dscl . -delete "/Users/$u" && ok "Deleted user $u"
  done
  dscl . -read /Groups/nixbld >/dev/null 2>&1 && sudo dscl . -delete /Groups/nixbld && ok "Deleted group nixbld"
else
  for u in $(getent passwd | cut -d: -f1 | grep -E '^_?nixbld[0-9]+$'); do
    sudo userdel "$u" && ok "Deleted user $u"
  done
  getent group nixbld >/dev/null && sudo groupdel nixbld && ok "Deleted group nixbld"
fi

if [[ $OS == darwin ]]; then
  info "Removing /nix and /run mount entries"
  if grep -qE '[[:space:]]/nix[[:space:]]' /etc/fstab 2>/dev/null; then
    sudo cp /etc/fstab "$BACKUP/fstab"
    sudo "${SEDI[@]}" -E '/[[:space:]]\/nix[[:space:]]/d' /etc/fstab && ok "Cleaned /etc/fstab"
  fi
  if [[ -f /etc/synthetic.conf ]] && grep -qE '^(nix|run)([[:space:]]|$)' /etc/synthetic.conf; then
    sudo cp /etc/synthetic.conf "$BACKUP/synthetic.conf"
    sudo "${SEDI[@]}" -E '/^(nix|run)([[:space:]]|$)/d' /etc/synthetic.conf
    if ! grep -q '[^[:space:]]' /etc/synthetic.conf; then
      sudo rm -f /etc/synthetic.conf && ok "Removed /etc/synthetic.conf"
    else
      ok "Cleaned /etc/synthetic.conf"
    fi
  fi

  info "Deleting the Nix Store volume"
  vol=$(diskutil apfs list | awk '
    /APFS Volume Disk/ { match($0, /disk[0-9]+s[0-9]+/); id = substr($0, RSTART, RLENGTH) }
    /Name:[[:space:]]+Nix Store/ { print id; exit }')
  if [[ -n "$vol" ]]; then
    sudo diskutil unmount force "$vol" >/dev/null 2>&1
    sudo diskutil apfs deleteVolume "$vol" >/dev/null && ok "Deleted volume $vol"
  else
    ok "Already gone"
  fi
  sudo security delete-generic-password -l "Nix Store" /Library/Keychains/System.keychain >/dev/null 2>&1 \
    && ok "Removed Nix Store keychain entry"

  info "Removing Nix fonts and leftover system files"
  [[ -e "/Library/Fonts/Nix Fonts" ]] && sudo rm -rf "/Library/Fonts/Nix Fonts" && ok "Removed /Library/Fonts/Nix Fonts"
  sudo rm -rf /etc/nix /etc/nix-darwin /var/root/.nix-profile /var/root/.nix-defexpr \
              /var/root/.nix-channels /var/root/.cache/nix /var/root/.local/state/nix
  ok "Done"
else
  info "Deleting /nix and leftover system files"
  if [[ -e /nix ]]; then
    mountpoint -q /nix 2>/dev/null && sudo umount /nix
    sudo rm -rf /nix && ok "Removed /nix"
  else
    ok "/nix already gone"
  fi
  sudo rm -rf /etc/nix /root/.nix-profile /root/.nix-defexpr /root/.nix-channels \
              /root/.cache/nix /root/.local/state/nix
  ok "Done"
fi

# ------------------------------------------------------- Home Manager leftovers
info "Removing Home Manager links and state from your home folder"
while IFS= read -r l; do
  rm -f "$l" && ok "Removed ~/${l#"$HOME"/}"
done < <(find "$HOME" -maxdepth 5 \( "${prune_args[@]}" \) -prune -o -type l -lname '/nix/*' -print 2>/dev/null
  if [[ $OS == darwin ]]; then
    find "$HOME/Library/Application Support" "$HOME/Library/Preferences" "$HOME/Library/Fonts" \
      -maxdepth 3 -type l -lname '/nix/*' 2>/dev/null
  fi)
rm_home ".nix-profile" ".nix-defexpr" ".nix-channels" ".local/state/nix" ".local/state/home-manager" \
        ".local/share/home-manager" ".cache/nix" ".config/nix" ".config/home-manager"
for d in .config .local .cache .claude .codex .agents .zsh; do
  [[ -d "$HOME/$d" ]] && find "$HOME/$d" -depth -type d -empty -delete 2>/dev/null
done
if [[ $OS == linux ]] && command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 && ok "Refreshed the font cache"
fi

# Home Manager moved these originals aside before nix-green; put back the ones
# whose path is free again, and list the rest.
backups=()
while IFS= read -r b; do
  orig="${b%.backup}"
  if [[ -e "$orig" || -L "$orig" ]]; then
    backups+=("$b")
  else
    mv "$b" "$orig" && ok "Restored your original ~/${orig#"$HOME"/}"
  fi
done < <(find "$HOME" -maxdepth 3 \( "${prune_args[@]}" \) -prune -o -type f -name '*.backup' -print 2>/dev/null)
if [[ ${#backups[@]} -gt 0 ]]; then
  warn "Home Manager also saved these originals, but the file exists again (compare, then delete or restore):"
  printf '        %s\n' "${backups[@]}"
fi

# ------------------------------------------------------------- macOS defaults
if [[ $RESET_DEFAULTS -eq 1 ]]; then
  info "Resetting macOS settings to defaults"
  defaults delete com.apple.dock 2>/dev/null && ok "Dock reset to default layout"
  defaults delete com.apple.finder AppleShowAllExtensions 2>/dev/null
  for k in AppleShowAllExtensions _HIHideMenuBar AppleInterfaceStyle AppleAccentColor AppleHighlightColor; do
    defaults delete -g "$k" 2>/dev/null
  done
  defaults delete com.raycast.macos 2>/dev/null
  ok "Appearance, menu bar and Finder settings reset"
  sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true 2>/dev/null
  sudo systemsetup -setusingnetworktime on >/dev/null 2>&1
  ok "Automatic time zone turned on (needs Location Services)"
  killall Dock Finder SystemUIServer 2>/dev/null
fi

# ---------------------------------------------------------------- Homebrew
if [[ $REMOVE_BREW -eq 1 ]]; then
  info "Removing Homebrew"
  if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" >/dev/null 2>&1; then
    ok "Homebrew uninstalled"
  else
    warn "Homebrew's uninstaller reported problems"
  fi
  prefix="$(dirname "$(dirname "$BREW")")"
  [[ "$prefix" == /opt/homebrew && -d /opt/homebrew ]] && sudo rm -rf /opt/homebrew && ok "Removed /opt/homebrew"
  for f in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if [[ -f "$f" && ! -L "$f" ]] && grep -q 'brew shellenv' "$f"; then
      cp "$f" "$BACKUP/$(basename "$f")"
      "${SEDI[@]}" '/brew shellenv/d' "$f" && ok "Removed Homebrew line from ~/$(basename "$f")"
    fi
  done
  rm_home "Library/Caches/Homebrew" "Library/Logs/Homebrew" ".cache/Homebrew"
fi

# ------------------------------------------------------------- repo + finish
if [[ $DEL_REPO -eq 1 ]]; then
  info "Deleting ~/nix-green"
  rm -rf "$HOME/nix-green" && ok "Removed ~/nix-green"
fi

info "Checking your personal shell files for leftover references"
found=0
for f in ~/.zshrc ~/.zprofile ~/.zshenv ~/.bash_profile ~/.bashrc ~/.profile; do
  if [[ -f "$f" ]] && grep -qiE 'nix|home-manager' "$f"; then
    found=1; warn "$f still mentions nix:"; grep -niE 'nix|home-manager' "$f" | sed 's/^/        /'
  fi
done
[[ $found -eq 0 ]] && ok "Clean"

rmdir "$BACKUP" 2>/dev/null
info "All done."
[[ -d "$BACKUP" ]] && echo "    Backups of edited system files: $BACKUP"
echo "    Leftover nix-uninstall-backup-* folders in your home from earlier runs can be deleted."
echo
if [[ $OS == darwin ]]; then
  if ask "Reboot now to finish? [Y/n]" y; then sudo shutdown -r now; fi
  echo "Reboot when you're ready; /nix disappears after restarting."
else
  if ask "Reboot now to finish? [Y/n]" y; then sudo systemctl reboot; fi
  echo "Log out or reboot when you're ready, so your session stops using Nix's PATH and services."
fi
