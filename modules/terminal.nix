{ pkgs, lib, ghostty, ... }:

{
  # ghostty config
  programs.ghostty = {
    enable = true;
    enableBashIntegration = false;
    package = ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      #background-blur-radius = 20;
      theme = "dark:Catppuccin Mocha,light:Catppuccin Latte";
      background-opacity = 0.9;
      window-theme = "dark";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 10;
      #window-decoration = false;
    } // lib.optionalAttrs pkgs.stdenv.isLinux {
      gtk-tabs-location = "hidden"; # GTK-only — Ghostty uses native UI on macOS
    };
  };
}
