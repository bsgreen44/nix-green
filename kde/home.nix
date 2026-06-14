{ username, ... }:
{
  imports = [
    ../modules/packages.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/kdethemes.nix
    ../modules/themes.nix
    ../modules/screensaver.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # zen-browser (Linux-only; macOS uses the homebrew cask)
  programs.zen-browser = {
    enable = true;
    #setAsDefaultBrowser = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
