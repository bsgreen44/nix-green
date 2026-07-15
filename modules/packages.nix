{ pkgs, lib, gazelle, tsui, pvetui, herdr, ... }:

{
  home.packages =
    with pkgs;
    [
      # Cross-platform CLI tools
      bat
      wget
      git
      fastfetch
      claude-code
      codex
      python315
      lazygit
      luarocks
      lua51Packages.lua

      # herdr (AI coding-agent multiplexer) — cross-platform flake package
      herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals stdenv.isLinux [
      # Linux-only GUI apps (macOS uses homebrew casks instead)
      brave
      obsidian
      nextcloud-client
      libreoffice
      signal-desktop
      localsend
      vlc

      # Linux-only TUIs (skipped on macOS)
      yazi # TUI file manager
      wiremix # audio tui

      # Linux-only flake packages
      # NetworkManager tui
      gazelle.packages.${pkgs.stdenv.hostPlatform.system}.default

      # pvetui (Proxmox manager tui)
      #pvetui.packages.${pkgs.stdenv.hostPlatform.system}.default

      (pvetui.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
        vendorHash = "sha256-JOo/7/3J9LqefIYuRl9efSlSfzLvQ/B8Jpy2e5cdEio=";
      }))

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

  # VSCodium config (Linux-only — macOS installs via homebrew cask for /Applications integration)
  programs.vscodium = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        anthropic.claude-code
        jnoortheen.nix-ide
      ];
      userSettings = {
        "claudeCode.preferredLocation" = "panel";
        "[markdown]" = {
          "editor.unicodeHighlight.ambiguousCharacters" = false;
          "editor.unicodeHighlight.invisibleCharacters" = false;
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.wordWrap" = "on";
          "editor.quickSuggestions" = {
            comments = "off";
            strings = "off";
            other = "off";
          };
        };
      };
    };
  };

  # Gazelle config (Linux-only — gazelle is a NetworkManager TUI)
  programs.gazelle = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    settings = {
      theme = "nord"; # choose your theme
    };
  };

  programs.clock-rs = {
    enable = true;
    settings = {
      general = {
        color = "green";
        interval = 250;
        blink = false;
        bold = true;
      };
      position = {
        horizontal = "center";
        vertical = "center";
      };
      date = {
        fmt = "%A, %B %d, %Y";
        use_12h = true;
        utc = false;
        hide_seconds = false;
      };
    };
  };

  # Opencode config
  programs.opencode = {
    enable = true;
    settings = {
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama";
          options = {
            baseURL = "http://127.0.0.1:11434/v1";
          };
          models = {
            "qwen2.5-coder:3b" = {
              name = "qwen2.5-coder:3b";
            };
          };
        };
      };
      # model = "ollama/qwen2.5-coder:3b";  # default model on startup
      autoupdate = false;
    };
  };
}
