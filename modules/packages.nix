{ pkgs, gazelle, tsui, ... }:

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
      python315
      lazygit
      luarocks
      lua51Packages.lua
      wiremix # audio tui
      signal-desktop
      opencode
      vlc
      yazi #TUI file manager
    ]
    ++ [
      gazelle.packages.${pkgs.system}.default # network tui
      (pkgs.runCommand "tsui-wrapped" {
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        makeWrapper ${tsui.packages.${pkgs.system}.tsui}/bin/tsui $out/bin/tsui \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
            pkgs.libX11
          ]}
      '')
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
      theme = "nord"; # choose your theme
    };
  };
}
