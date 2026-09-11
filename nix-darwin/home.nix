{ username, ... }:
{
  imports = [
    # Defines the green.apps role registry that ../modules/terminal.nix reads.
    # lib.mkIf would not help here - the option has to be declared by an imported
    # module or referencing it is an eval error.
    ../modules/apps.nix
    ../modules/packages.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/themes.nix
    ../modules/raycast.nix
    # ../modules/aerospace.nix
    # ../modules/sketchybar.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
