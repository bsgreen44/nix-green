{
  username,
  ...
}:
{
  imports = [
    ../modules/packages.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/themes.nix
    ../modules/hyprland.nix
    ../modules/hypridle.nix
    ../modules/hyprlock.nix
    ../modules/waybar.nix
    ../modules/rofi.nix
    ../modules/walker.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
