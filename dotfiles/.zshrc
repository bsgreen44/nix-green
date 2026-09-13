# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Load zsh options, keybindings, and completion
[[ -f /usr/share/omarchy-zsh/shell/zoptions ]] && source /usr/share/omarchy-zsh/shell/zoptions

# Load shared shell configuration (aliases, functions, environment, tool init)
[[ -f /usr/share/omarchy-zsh/shell/all ]] && source /usr/share/omarchy-zsh/shell/all

# ---------------------------------------------------------------------------
# Migrated from nix-green modules/shells.nix
#
# Everything else that file declared is already covered by omarchy-zsh:
# zsh-syntax-highlighting (zoptions, sourced last) and starship (shell/inits).
# ---------------------------------------------------------------------------

# zsh-autosuggestions is not a dependency of omarchy-zsh, so it is installed and
# sourced here. This has to come after zoptions, which sources
# zsh-syntax-highlighting - both plugins' docs want autosuggestions loaded after
# the highlighter, and this is the reverse of the order shells.nix used.
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

alias cat='bat'

# ---------------------------------------------------------------------------
# Omarchy bash function libraries that omarchy-zsh 1.5.0 does not ship.
#
# It ships 5 of the 8 in /usr/share/omarchy/default/bash/fns/. These are zsh
# ports of the other three - rsyncing (rsw/lsw/dsw), herdr (hdl/hds/hdlm/hsl)
# and ssh-reconnect (the ssh auto-reconnect wrapper). If a future omarchy-zsh
# starts shipping any of them, delete the corresponding file here: this loop
# runs after shell/all, so these definitions would otherwise win.
# ---------------------------------------------------------------------------
for _fn in ~/.config/zsh/fns/*(N); do source "$_fn"; done
unset _fn
