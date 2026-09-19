{ pkgs, config, gazelle, tsui, pvetui, herdr, ... }:

let
  # One global instruction file for every agent harness.
  #
  # Linked out of the Nix store so it stays editable in place: change
  # global-agents.md in the working tree and Claude, Codex and opencode all pick
  # it up on their next run, with no rebuild. The tradeoff is that the content is
  # not reproducible from the flake alone - it is whatever the checkout holds.
  # That is the point; a read-only store symlink would stop the agents (and you)
  # appending to their own instructions.
  #
  # Deliberately NOT named AGENTS.md: all three harnesses walk up from the cwd
  # looking for AGENTS.md, so that name would make this file double as
  # nix-green's *project* instructions and load twice in this repo. opencode and
  # codex have no way to opt out of that.
  #
  # Same hardcoded repo path as the wallpaper in hyprland/home.nix; a checkout
  # somewhere other than ~/nix-green needs this edited.
  agentsContext = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nix-green/global-agents.md";
in

{
  home.packages =
    with pkgs;
    [
      bat
      wget
      git
      fastfetch
      brave
      claude-code
      codex
      obsidian
      nextcloud-client
      libreoffice
      wakeonlan
      bluetui
      calcurse
      cmatrix
      cbonsai
      lazygit
      luarocks
      lua51Packages.lua
      wiremix # audio tui
      signal-desktop
      localsend
      vlc
      yazi #TUI file manager
    ]
    ++ [
      # NetworkManager tui
      gazelle.packages.${pkgs.stdenv.hostPlatform.system}.default

      # herdr (AI coding-agent multiplexer)
      herdr.packages.${pkgs.stdenv.hostPlatform.system}.default

      # pvetui (Proxmox manager tui)
      #pvetui.packages.${pkgs.stdenv.hostPlatform.system}.default

      (pvetui.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
        vendorHash = "sha256-7Tuh9T3uTlNxdSlSL7gQIYXpfpNbCkQrRWj/FoU8fbU=";
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

  # VSCodium config
  programs.vscodium = {
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

  # Gazelle config
  programs.gazelle = {
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

  # Global agent instructions. One file, every harness. See `agentsContext` above
  # for why it is an out-of-store symlink and why it is not called AGENTS.md.
  home.file.".claude/CLAUDE.md".source = agentsContext;      # Claude Code
  home.file.".codex/AGENTS.md".source = agentsContext;       # Codex CLI, $CODEX_HOME
  xdg.configFile."opencode/AGENTS.md".source = agentsContext;

  # opencode
  programs.opencode = {
    enable = true;
    settings = {
      model = "openai/gpt-5.5";
      small_model = "openai/gpt-5.4-mini";
      default_agent = "plan";
      agent = {
        plan.model = "openai/gpt-5.5";
        general.model = "openai/gpt-5.5";
        explore.model = "openai/gpt-5.4-mini";
        scout.model = "openai/gpt-5.4-mini";
      };

      autoupdate = false;

      # Local fallback, selectable at runtime with /models.
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
    };
  };
  # zen-browser
  programs.zen-browser = {
    enable = true;
    #setAsDefaultBrowser = true;
  };
}
