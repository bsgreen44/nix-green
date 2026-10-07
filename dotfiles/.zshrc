# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Portable version of the zsh setup in nix-green modules/shells.nix. Plugin
# paths are the Arch package locations; adjust them for your distro.

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_FCNTL_LOCK HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

autoload -U compinit && compinit

# zsh-syntax-highlighting's docs want it sourced after other widgets, so it goes
# last, matching the plugin order in shells.nix.
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ $TERM != dumb ]] && command -v starship >/dev/null && eval "$(starship init zsh)"

alias cat='bat'
