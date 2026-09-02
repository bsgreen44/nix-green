{ username, ... }:
{
  imports = [
    ../modules/packages.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/themes.nix
    # ../modules/raycast.nix
    # ../modules/aerospace.nix
    # ../modules/sketchybar.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
