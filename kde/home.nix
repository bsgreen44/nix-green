{ config, username, ... }:
{
  imports = [
    ../modules/apps.nix
    ../modules/packages.nix
    ../modules/herdr.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/kdethemes.nix
    ../modules/themes.nix
    ../modules/dictation.nix
    ../modules/screensaver.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # `rebuild` re-runs the switch for this configuration, from any directory.
  home.shellAliases.rebuild = "${config.home.homeDirectory}/nix-green/scripts/install.sh kde";

  # zen-browser (Linux-only; macOS uses the homebrew cask)
  programs.zen-browser = {
    enable = true;
    #setAsDefaultBrowser = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
