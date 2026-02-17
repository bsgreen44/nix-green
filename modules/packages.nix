{ pkgs, gazelle, ... }:

{
  home.packages =
    with pkgs;
    [
      bat
      wget
      git
      fastfetch
      obsidian
      nextcloud-client
      libreoffice
      gcc
      python315
      lazygit
      luarocks
      lua51Packages.lua
      wiremix # audio tui
    ]
    ++ [
      gazelle.packages.${pkgs.system}.default # network tui
    ];

  # brave config
  programs.brave = {
    enable = true;
    package = pkgs.brave;
  };

  # bat config
  programs.bat = {
    enable = true;
    config = {
      pager = "never"; # makes bat act like cat
    };
  };

  # btop config
  programs.btop = {
    enable = true;
    settings = {
      theme_background = false;
    };
  };

  # VScode config
  programs.vscode = {
    enable = true;
  };

  # Gazelle config
  programs.gazelle = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha"; # choose your theme
    };
  };
}
