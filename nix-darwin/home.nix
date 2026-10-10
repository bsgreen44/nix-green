{ config, username, ... }:
{
  imports = [
    # Defines the green.apps role registry that ../modules/terminal.nix reads.
    # lib.mkIf would not help here - the option has to be declared by an imported
    # module or referencing it is an eval error.
    ../modules/apps.nix
    ../modules/packages.nix
    ../modules/herdr.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/themes.nix
    ../modules/raycast.nix
    ../modules/aerospace.nix
    ../modules/sketchybar.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.11";

  # `rebuild` re-runs the switch for this configuration, from any directory.
  # macOS has a single configuration, so install.sh takes no target here.
  home.shellAliases.rebuild = "${config.home.homeDirectory}/nix-green/scripts/install.sh";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
