{ pkgs, username, ... }:
{
  _module.args = {
    wallpaper = "/home/${username}/nix-green/wallpapers/linux-catppuccin.jpg";
    hidpi = false;   # set true on 2k/4k laptop panels
  };
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
    ../modules/mako.nix
    ../modules/screensaver.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
