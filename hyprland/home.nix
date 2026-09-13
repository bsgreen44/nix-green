{ pkgs, username, ... }:
{
  _module.args = {
    wallpaper = "/home/${username}/nix-green/wallpapers/catppuccin_mocha_japanese_wallpaper_8k.png";
    hidpi = false;   # set true on 2k/4k laptop panels
  };
  imports = [
    ../modules/apps.nix
    ../modules/packages.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/themes.nix
    ../modules/hyprland.nix
    ../modules/hypr-workspace-layout.nix
    ../modules/hypridle.nix
    ../modules/hyprlock.nix
    ../modules/waybar.nix
    ../modules/rofi.nix
    ../modules/mako.nix
    ../modules/swayosd.nix
    ../modules/screensaver.nix
  ];

  # Idle screensaver. false makes hypridle's 3-minute timeout lock the session
  # directly; SUPER + SHIFT + Z still launches the screensaver by hand.
  green.screensaver.enable = true;

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
