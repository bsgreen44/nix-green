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
      tailscale
      libreoffice
      gcc
      python315
      lazygit
      luarocks
      lua51Packages.lua
    ]
    ++ [
      gazelle.packages.${pkgs.system}.default
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
      theme = "catppuccin"; # choose your theme
    };
  };
}
