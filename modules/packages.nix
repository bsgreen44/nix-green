{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wget
    git
    fastfetch
    obsidian
    nextcloud-client
    tailscale
    libreoffice
    gcc
    python315
    luarocks
    lua51Packages.lua
  ];

  # brave config
  programs.brave = {
    enable = true;
    package = pkgs.brave;

  };

  # btop config
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = false;
    };
  };
}
