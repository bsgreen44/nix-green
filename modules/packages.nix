{ pkgs, gazelle, tsui, pvetui, ... }:

{
  home.packages =
    with pkgs;
    [
      bat
      wget
      git
      fastfetch
      brave
      obsidian
      nextcloud-client
      libreoffice
      python315
      lazygit
      luarocks
      lua51Packages.lua
      wiremix # audio tui
      signal-desktop
      localsend
      opencode
      vlc
      yazi #TUI file manager
    ]
    ++ [
      # NetworkManager tui
      gazelle.packages.${pkgs.stdenv.hostPlatform.system}.default

      # pvetui (Proxmox manager tui)
      pvetui.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Tailscale tui
      (pkgs.runCommand "tsui-wrapped" {
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        makeWrapper ${tsui.packages.${pkgs.stdenv.hostPlatform.system}.tsui}/bin/tsui $out/bin/tsui \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
            pkgs.libX11
          ]}
      '')
    ];

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
    profiles.default.userSettings = {
      "telemetry.enableTelemetry" = false;
      "telemetry.enableCrashReporter" = false;
      update.mode = "none";
      update.showReleaseNotes = false;
    };
    profiles.default.extensions = with pkgs.vscode-extensions; [
      catppuccin.catppuccin-vsc
      jnoortheen.nix-ide
    ];
  };

  # Gazelle config
  programs.gazelle = {
    enable = true;
    settings = {
      theme = "nord"; # choose your theme
    };
  };
}
