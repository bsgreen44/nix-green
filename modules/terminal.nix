{ pkgs, ghostty, ... }:

{
  # ghostty config
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    package = ghostty.packages.${pkgs.system}.default;
    settings = {
      #background-blur-radius = 20;
      theme = "dark:Catppuccin Frappe,light:Catppuccin Latte";
      background-opacity = 0.9;
      window-theme = "dark";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 10;
      gtk-tabs-location = "hidden";
      #window-decoration = false;
    };
  };
}
