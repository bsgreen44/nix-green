{ pkgs, config, username, ... }:
{
  _module.args = {
    wallpaper = "/home/${username}/nix-green/wallpapers/catppuccin_mocha_japanese_wallpaper_8k.png";
  };
  imports = [
    ../modules/apps.nix
    ../modules/packages.nix
    ../modules/terminal.nix
    ../modules/shells.nix
    ../modules/starship.nix
    ../modules/neovim.nix
    ../modules/themes.nix
    ../modules/dictation.nix
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

  # `rebuild` re-runs the switch for this configuration, from any directory.
  home.shellAliases.rebuild = "${config.home.homeDirectory}/nix-green/scripts/install.sh hyprland";

  # zen-browser (Linux-only; macOS uses the homebrew cask)
  programs.zen-browser = {
    enable = true;
    #setAsDefaultBrowser = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
